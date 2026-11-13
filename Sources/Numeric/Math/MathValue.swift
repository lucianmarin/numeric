import Foundation

public struct MathEvalError: LocalizedError, Equatable, Sendable {
    public let message: String

    public init(_ message: String) {
        self.message = message
    }

    public var errorDescription: String? {
        message
    }
}

public indirect enum MathValue: Equatable, Sendable {
    case number(Double)
    case complex(re: Double, im: Double)
    case bool(Bool)
    case string(String)
    case unit(value: Double, unit: MathUnit)
    case matrix([[MathValue]])
    case object([String: MathValue], orderedKeys: [String])
    case function(name: String, params: [String], body: AstNode, capturedScope: [String: MathValue])
    case null

    public var isVector: Bool {
        if case .matrix(let rows) = self {
            return rows.count == 1
        }
        return false
    }

    public var rowCount: Int {
        if case .matrix(let rows) = self {
            return rows.count
        }
        return 0
    }

    public var colCount: Int {
        if case .matrix(let rows) = self {
            return rows.first?.count ?? 0
        }
        return 0
    }

    public func flatValues() -> [MathValue] {
        if case .matrix(let rows) = self {
            return rows.flatMap { $0 }
        }
        return [self]
    }

    public func toDoubleMatrix() throws -> [[Double]] {
        guard case .matrix(let rows) = self else {
            throw MathEvalError("Expected a matrix, got \(typeName())")
        }
        return try rows.map { row in
            try row.map { try $0.asDouble() }
        }
    }

    public static func vector(_ items: [MathValue]) -> MathValue {
        .matrix([items])
    }

    public static func fromDoubles(_ data: [[Double]]) -> MathValue {
        .matrix(data.map { row in row.map { .number($0) } })
    }

    public func asDouble() throws -> Double {
        switch self {
        case .number(let v):
            return v
        case .bool(let b):
            return b ? 1.0 : 0.0
        case .complex(let re, let im):
            if abs(im) < 1e-12 {
                return re
            }
            throw MathEvalError("Cannot convert complex number to real number")
        case .unit(let v, _):
            return v
        case .string(let s):
            if let d = Double(s.trimmingCharacters(in: .whitespaces)) {
                return d
            }
            throw MathEvalError("Cannot convert string \"\(s)\" to number")
        default:
            throw MathEvalError("Expected a number, got \(typeName())")
        }
    }

    public func asComplex() throws -> (re: Double, im: Double) {
        switch self {
        case .complex(let re, let im):
            return (re, im)
        case .number(let v):
            return (v, 0.0)
        case .bool(let b):
            return (b ? 1.0 : 0.0, 0.0)
        default:
            throw MathEvalError("Cannot convert \(typeName()) to complex")
        }
    }

    public func asBoolean() -> Bool {
        switch self {
        case .bool(let b):
            return b
        case .number(let v):
            return v != 0.0 && !v.isNaN
        case .complex(let re, let im):
            return re != 0.0 || im != 0.0
        case .string(let s):
            return !s.isEmpty
        case .null:
            return false
        default:
            return true
        }
    }

    public func typeName() -> String {
        switch self {
        case .number: return "number"
        case .complex: return "Complex"
        case .bool: return "boolean"
        case .string: return "string"
        case .unit: return "Unit"
        case .matrix: return "Matrix"
        case .object: return "Object"
        case .function: return "function"
        case .null: return "null"
        }
    }

    public var numericValue: Double? {
        switch self {
        case .number(let v) where v.isFinite:
            return v
        default:
            return nil
        }
    }

    public func format(precision: Int = 14) -> String {
        switch self {
        case .number(let v):
            return Self.formatNumber(v, precision: precision)
        case .complex(let re, let im):
            return Self.formatComplex(re: re, im: im, precision: precision)
        case .bool(let b):
            return b ? "true" : "false"
        case .string(let s):
            return "\"\(s)\""
        case .unit(let v, let u):
            return "\(Self.formatNumber(v, precision: precision)) \(u.formatName())"
        case .matrix(let rows):
            if rows.isEmpty { return "[]" }
            if rows.count == 1 {
                let inner = rows[0].map { $0.format(precision: precision) }.joined(separator: ", ")
                return "[\(inner)]"
            } else {
                let rowStrs = rows.map { row in
                    "[" + row.map { $0.format(precision: precision) }.joined(separator: ", ") + "]"
                }.joined(separator: ", ")
                return "[\(rowStrs)]"
            }
        case .object(let props, let keys):
            let kList = keys.isEmpty ? Array(props.keys).sorted() : keys
            let pairs = kList.compactMap { k -> String? in
                guard let v = props[k] else { return nil }
                return "\(k): \(v.format(precision: precision))"
            }.joined(separator: ", ")
            return "{\(pairs)}"
        case .function(let name, let params, _, _):
            return "[Function: \(name)(\(params.joined(separator: ", ")))]"
        case .null:
            return "null"
        }
    }

    public static func formatNumber(_ value: Double, precision: Int = 14) -> String {
        if value.isNaN { return "NaN" }
        if value == .infinity { return "Infinity" }
        if value == -.infinity { return "-Infinity" }
        let cleaned = abs(value) < 1e-15 ? 0.0 : value
        if cleaned == 0.0 { return "0" }

        let absVal = abs(cleaned)
        if absVal >= 1e14 || (absVal > 0 && absVal < 1e-4) {
            let scale = Int(floor(log10(absVal)))
            let scaled = cleaned / pow(10.0, Double(scale))
            let mantissa = formatSignificantPlain(scaled, precision: precision)
            let sign = scale >= 0 ? "+" : ""
            return "\(mantissa)e\(sign)\(scale)"
        } else {
            return formatSignificantPlain(cleaned, precision: precision)
        }
    }

    private static func formatSignificantPlain(_ value: Double, precision: Int) -> String {
        if value == 0.0 { return "0" }
        let absVal = abs(value)
        let intDigits = Int(floor(log10(absVal))) + 1
        let fracDigits = max(0, precision - intDigits)
        let formatted = String(format: "%.*f", fracDigits, value)
        var s = formatted
        if s.contains(".") {
            while s.last == "0" {
                s.removeLast()
            }
            if s.last == "." {
                s.removeLast()
            }
        }
        if s == "-0" { return "0" }
        return s
    }

    public static func formatComplex(re: Double, im: Double, precision: Int = 14) -> String {
        let cleanRe = abs(re) < 1e-14 ? 0.0 : re
        let cleanIm = abs(im) < 1e-14 ? 0.0 : im
        if cleanIm == 0.0 {
            return formatNumber(cleanRe, precision: precision)
        }
        let imAbs = abs(cleanIm)
        let imPart = imAbs == 1.0 ? "i" : "\(formatNumber(imAbs, precision: precision))i"
        if cleanRe == 0.0 {
            return cleanIm < 0 ? "-\(imPart)" : imPart
        }
        let sign = cleanIm < 0 ? " - " : " + "
        return "\(formatNumber(cleanRe, precision: precision))\(sign)\(imPart)"
    }

    public static func complexOrReal(re: Double, im: Double) -> MathValue {
        if abs(im) < 1e-14 {
            return .number(abs(re) < 1e-15 ? 0.0 : re)
        }
        return .complex(re: re, im: im)
    }
}

public enum ComplexOps {
    public static func add(_ a: (re: Double, im: Double), _ b: (re: Double, im: Double)) -> MathValue {
        MathValue.complexOrReal(re: a.re + b.re, im: a.im + b.im)
    }

    public static func sub(_ a: (re: Double, im: Double), _ b: (re: Double, im: Double)) -> MathValue {
        MathValue.complexOrReal(re: a.re - b.re, im: a.im - b.im)
    }

    public static func mul(_ a: (re: Double, im: Double), _ b: (re: Double, im: Double)) -> MathValue {
        MathValue.complexOrReal(
            re: a.re * b.re - a.im * b.im,
            im: a.re * b.im + a.im * b.re
        )
    }

    public static func div(_ a: (re: Double, im: Double), _ b: (re: Double, im: Double)) -> MathValue {
        let denom = b.re * b.re + b.im * b.im
        if denom == 0.0 { return .number(.nan) }
        return MathValue.complexOrReal(
            re: (a.re * b.re + a.im * b.im) / denom,
            im: (a.im * b.re - a.re * b.im) / denom
        )
    }

    public static func absVal(_ z: (re: Double, im: Double)) -> Double {
        hypot(z.re, z.im)
    }

    public static func arg(_ z: (re: Double, im: Double)) -> Double {
        atan2(z.im, z.re)
    }

    public static func conj(_ z: (re: Double, im: Double)) -> MathValue {
        .complex(re: z.re, im: -z.im)
    }

    public static func sqrtVal(_ z: (re: Double, im: Double)) -> MathValue {
        let r = absVal(z)
        let re = Foundation.sqrt((r + z.re) / 2.0)
        let im = (z.im < 0 ? -1.0 : 1.0) * Foundation.sqrt(max(0.0, (r - z.re) / 2.0))
        return MathValue.complexOrReal(re: re, im: im)
    }

    public static func expVal(_ z: (re: Double, im: Double)) -> MathValue {
        let er = Foundation.exp(z.re)
        return MathValue.complexOrReal(re: er * Foundation.cos(z.im), im: er * Foundation.sin(z.im))
    }

    public static func lnVal(_ z: (re: Double, im: Double)) -> MathValue {
        MathValue.complexOrReal(re: Foundation.log(absVal(z)), im: arg(z))
    }

    public static func pow(_ a: (re: Double, im: Double), _ b: (re: Double, im: Double)) throws -> MathValue {
        try powVal(a, b)
    }

    public static func powVal(_ a: (re: Double, im: Double), _ b: (re: Double, im: Double)) throws -> MathValue {
        if a.re == 0.0 && a.im == 0.0 {
            return b.re > 0 ? .number(0.0) : .number(.nan)
        }
        let lnA = try lnVal(a).asComplex()
        let prod = try mul(b, lnA).asComplex()
        return expVal(prod)
    }

    public static func sinVal(_ z: (re: Double, im: Double)) -> MathValue {
        MathValue.complexOrReal(re: Foundation.sin(z.re) * Foundation.cosh(z.im), im: Foundation.cos(z.re) * Foundation.sinh(z.im))
    }

    public static func cosVal(_ z: (re: Double, im: Double)) -> MathValue {
        MathValue.complexOrReal(re: Foundation.cos(z.re) * Foundation.cosh(z.im), im: -Foundation.sin(z.re) * Foundation.sinh(z.im))
    }

    public static func tanVal(_ z: (re: Double, im: Double)) throws -> MathValue {
        let s = try sinVal(z).asComplex()
        let c = try cosVal(z).asComplex()
        return div(s, c)
    }
}
