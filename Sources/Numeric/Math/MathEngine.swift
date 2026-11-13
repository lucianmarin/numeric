import Foundation

public enum TokenType: Equatable, Sendable {
    case number
    case imag
    case string
    case ident
    case lineRef
    case op
    case lparen
    case rparen
    case lbracket
    case rbracket
    case lbrace
    case rbrace
    case comma
    case semi
    case colon
    case question
    case dot
    case eof
}

public struct Token: Equatable, Sendable {
    public let type: TokenType
    public let text: String
    public let pos: Int

    public init(type: TokenType, text: String, pos: Int) {
        self.type = type
        self.text = text
        self.pos = pos
    }
}

public enum MathTokenizer {
    private static let multiCharOps: Set<String> = [
        ".*", "./", ".^", "==", "!=", "<=", ">=", "&&", "||", "<<", ">>>", ">>"
    ]

    public static func stripInlineComment(_ line: String) -> String {
        var inString = false
        var stringChar: Character = "\""
        let chars = Array(line)
        var i = 0
        while i < chars.count {
            let c = chars[i]
            if inString {
                if c == "\\" && i + 1 < chars.count {
                    i += 2
                    continue
                }
                if c == stringChar {
                    inString = false
                }
            } else {
                if c == "\"" || c == "'" {
                    let prevNonSpace = chars[..<i].last { !$0.isWhitespace }
                    let isTranspose = (c == "'") && (prevNonSpace != nil) &&
                        (prevNonSpace!.isLetter || prevNonSpace!.isNumber || prevNonSpace == "]" || prevNonSpace == ")")
                    if !isTranspose {
                        inString = true
                        stringChar = c
                    }
                } else if c == "#" {
                    return String(chars[..<i])
                } else if c == "/" && i + 1 < chars.count && chars[i + 1] == "/" {
                    return String(chars[..<i])
                }
            }
            i += 1
        }
        return line
    }

    public static func tokenize(_ rawInput: String) throws -> [Token] {
        let input = stripInlineComment(rawInput)
        let chars = Array(input)
        var tokens: [Token] = []
        var i = 0
        let n = chars.count

        while i < n {
            let c = chars[i]
            if c.isWhitespace {
                i += 1
                continue
            }

            // Hex / Binary / Octal or Decimal numbers
            if c.isNumber || (c == "." && i + 1 < n && chars[i + 1].isNumber) {
                let start = i
                if c == "0" && i + 1 < n && "xXbBoO".contains(chars[i + 1]) {
                    let prefix = chars[i + 1].lowercased()
                    i += 2
                    let numStart = i
                    while i < n && (chars[i].isHexDigit || chars[i] == "_") {
                        i += 1
                    }
                    let digits = String(chars[numStart..<i]).replacingOccurrences(of: "_", with: "")
                    let radix: Int
                    switch prefix {
                    case "x": radix = 16
                    case "b": radix = 2
                    default: radix = 8
                    }
                    let val = UInt64(digits, radix: radix) ?? 0
                    tokens.append(Token(type: .number, text: String(val), pos: start))
                    continue
                }

                while i < n && (chars[i].isNumber || chars[i] == "_") { i += 1 }
                if i < n && chars[i] == "." {
                    i += 1
                    while i < n && (chars[i].isNumber || chars[i] == "_") { i += 1 }
                }
                if i < n && (chars[i] == "e" || chars[i] == "E") {
                    let expStart = i
                    i += 1
                    if i < n && (chars[i] == "+" || chars[i] == "-") { i += 1 }
                    if i < n && chars[i].isNumber {
                        while i < n && chars[i].isNumber { i += 1 }
                    } else {
                        i = expStart
                    }
                }
                let numStr = String(chars[start..<i]).replacingOccurrences(of: "_", with: "")
                if i < n && chars[i] == "i" && (i + 1 >= n || (!chars[i + 1].isLetter && !chars[i + 1].isNumber)) {
                    i += 1
                    tokens.append(Token(type: .imag, text: numStr, pos: start))
                } else {
                    tokens.append(Token(type: .number, text: numStr, pos: start))
                }
                continue
            }

            // Line reference ($1, $2, ...)
            if c == "$" && i + 1 < n && chars[i + 1].isNumber {
                let start = i
                i += 1
                while i < n && chars[i].isNumber { i += 1 }
                tokens.append(Token(type: .lineRef, text: String(chars[start..<i]), pos: start))
                continue
            }

            // Transpose operator vs String literal
            if c == "\"" || c == "'" {
                let prev = tokens.last
                if c == "'" && prev != nil && [.ident, .rbracket, .rparen, .number, .imag, .lineRef].contains(prev!.type) {
                    tokens.append(Token(type: .op, text: "'", pos: i))
                    i += 1
                    continue
                }
                let quote = c
                let start = i
                i += 1
                var sb = ""
                while i < n && chars[i] != quote {
                    if chars[i] == "\\" && i + 1 < n {
                        i += 1
                        switch chars[i] {
                        case "n": sb.append("\n")
                        case "t": sb.append("\t")
                        default: sb.append(chars[i])
                        }
                    } else {
                        sb.append(chars[i])
                    }
                    i += 1
                }
                if i < n && chars[i] == quote { i += 1 }
                tokens.append(Token(type: .string, text: sb, pos: start))
                continue
            }

            // Identifiers & keyword operators (in, to, mod, and, or, not, xor)
            if c.isLetter || c == "_" || c == "°" || c == "µ" || c == "μ" || c == "Ω" {
                let start = i
                while i < n && (chars[i].isLetter || chars[i].isNumber || chars[i] == "_" || chars[i] == "°" || chars[i] == "µ" || chars[i] == "μ" || chars[i] == "Ω") {
                    i += 1
                }
                let word = String(chars[start..<i])
                switch word {
                case "in", "to", "mod", "and", "or", "xor", "not":
                    tokens.append(Token(type: .op, text: word, pos: start))
                default:
                    tokens.append(Token(type: .ident, text: word, pos: start))
                }
                continue
            }

            // 3-char & 2-char operators
            if i + 3 <= n && String(chars[i..<(i + 3)]) == ">>>" {
                tokens.append(Token(type: .op, text: ">>>", pos: i))
                i += 3
                continue
            }
            if i + 2 <= n {
                let two = String(chars[i..<(i + 2)])
                if multiCharOps.contains(two) {
                    tokens.append(Token(type: .op, text: two, pos: i))
                    i += 2
                    continue
                }
            }

            switch c {
            case "(": tokens.append(Token(type: .lparen, text: "(", pos: i))
            case ")": tokens.append(Token(type: .rparen, text: ")", pos: i))
            case "[": tokens.append(Token(type: .lbracket, text: "[", pos: i))
            case "]": tokens.append(Token(type: .rbracket, text: "]", pos: i))
            case "{": tokens.append(Token(type: .lbrace, text: "{", pos: i))
            case "}": tokens.append(Token(type: .rbrace, text: "}", pos: i))
            case ",": tokens.append(Token(type: .comma, text: ",", pos: i))
            case ";": tokens.append(Token(type: .semi, text: ";", pos: i))
            case ":": tokens.append(Token(type: .colon, text: ":", pos: i))
            case "?": tokens.append(Token(type: .question, text: "?", pos: i))
            case ".": tokens.append(Token(type: .dot, text: ".", pos: i))
            case "+", "-", "*", "/", "%", "^", "=", "<", ">", "!", "&", "|", "~":
                tokens.append(Token(type: .op, text: String(c), pos: i))
            default:
                throw MathEvalError("Unexpected character '\(c)' at position \(i)")
            }
            i += 1
        }

        tokens.append(Token(type: .eof, text: "", pos: n))
        return tokens
    }
}

public struct AstObjectField: Equatable, Sendable {
    public let key: String
    public let value: AstNode

    public init(key: String, value: AstNode) {
        self.key = key
        self.value = value
    }
}

public indirect enum AstNode: Equatable, Sendable {
    case numberLit(Double)
    case imagLit(Double)
    case stringLit(String)
    case ident(String)
    case lineRef(Int)
    case unary(op: String, expr: AstNode)
    case postfix(op: String, expr: AstNode)
    case binary(op: String, left: AstNode, right: AstNode)
    case ternary(cond: AstNode, ifTrue: AstNode, ifFalse: AstNode)
    case range(start: AstNode, end: AstNode, step: AstNode?)
    case call(callee: AstNode, args: [AstNode])
    case member(target: AstNode, field: String)
    case index(target: AstNode, indices: [AstNode])
    case matrixLit(rows: [[AstNode]])
    case objectLit(fields: [AstObjectField])
    case varAssign(name: String, expr: AstNode)
    case funcAssign(name: String, params: [String], body: AstNode)
    case block(statements: [AstNode])
}

public final class MathParser {
    private let tokens: [Token]
    private var pos = 0
    private var ternaryDepth = 0

    public init(tokens: [Token]) {
        self.tokens = tokens
    }

    private func peek(_ offset: Int = 0) -> Token {
        let idx = pos + offset
        return idx < tokens.count ? tokens[idx] : tokens.last!
    }

    @discardableResult
    private func consume() -> Token {
        let t = peek()
        pos += 1
        return t
    }

    @discardableResult
    private func expect(_ type: TokenType) throws -> Token {
        let t = peek()
        guard t.type == type else {
            throw MathEvalError("Expected \(type) but got '\(t.text)'")
        }
        return consume()
    }

    public func parseProgram() throws -> AstNode {
        var stmts: [AstNode] = []
        while peek().type == .semi { consume() }
        while peek().type != .eof {
            stmts.append(try parseStatement())
            while peek().type == .semi { consume() }
        }
        if stmts.count == 1 { return stmts[0] }
        return .block(statements: stmts)
    }

    private func parseStatement() throws -> AstNode {
        // Variable assignment: x = expr
        if peek().type == .ident && peek(1).type == .op && peek(1).text == "=" {
            let name = consume().text
            consume() // '='
            return .varAssign(name: name, expr: try parseExpression())
        }
        // Function assignment: f(x, y) = expr
        if peek().type == .ident && peek(1).type == .lparen {
            let saved = pos
            let name = consume().text
            consume() // '('
            var params: [String] = []
            var validParams = true
            if peek().type != .rparen {
                while true {
                    if peek().type == .ident {
                        params.append(consume().text)
                    } else {
                        validParams = false
                        break
                    }
                    if peek().type == .comma {
                        consume()
                    } else {
                        break
                    }
                }
            }
            if validParams && peek().type == .rparen && peek(1).type == .op && peek(1).text == "=" {
                consume() // ')'
                consume() // '='
                return .funcAssign(name: name, params: params, body: try parseExpression())
            }
            pos = saved
        }
        return try parseExpression()
    }

    private func parseExpression() throws -> AstNode {
        let cond = try parseLogicalOr()
        if peek().type == .question {
            consume()
            ternaryDepth += 1
            let ifTrue = try parseExpression()
            ternaryDepth -= 1
            try expect(.colon)
            let ifFalse = try parseExpression()
            return .ternary(cond: cond, ifTrue: ifTrue, ifFalse: ifFalse)
        }
        return cond
    }

    private func parseLogicalOr() throws -> AstNode {
        var left = try parseLogicalXor()
        while peek().type == .op && (peek().text == "||" || peek().text == "or") {
            let op = consume().text
            left = .binary(op: op, left: left, right: try parseLogicalXor())
        }
        return left
    }

    private func parseLogicalXor() throws -> AstNode {
        var left = try parseLogicalAnd()
        while peek().type == .op && peek().text == "xor" {
            let op = consume().text
            left = .binary(op: op, left: left, right: try parseLogicalAnd())
        }
        return left
    }

    private func parseLogicalAnd() throws -> AstNode {
        var left = try parseBitwiseOr()
        while peek().type == .op && (peek().text == "&&" || peek().text == "and") {
            let op = consume().text
            left = .binary(op: op, left: left, right: try parseBitwiseOr())
        }
        return left
    }

    private func parseBitwiseOr() throws -> AstNode {
        var left = try parseBitwiseXor()
        while peek().type == .op && peek().text == "|" {
            consume()
            left = .binary(op: "|", left: left, right: try parseBitwiseXor())
        }
        return left
    }

    private func parseBitwiseXor() throws -> AstNode {
        var left = try parseBitwiseAnd()
        while peek().type == .op && peek().text == "^|" {
            consume()
            left = .binary(op: "^|", left: left, right: try parseBitwiseAnd())
        }
        return left
    }

    private func parseBitwiseAnd() throws -> AstNode {
        var left = try parseEquality()
        while peek().type == .op && peek().text == "&" {
            consume()
            left = .binary(op: "&", left: left, right: try parseEquality())
        }
        return left
    }

    private func parseEquality() throws -> AstNode {
        var left = try parseRelational()
        while peek().type == .op && (peek().text == "==" || peek().text == "!=") {
            let op = consume().text
            left = .binary(op: op, left: left, right: try parseRelational())
        }
        return left
    }

    private func parseRelational() throws -> AstNode {
        var left = try parseUnitConversion()
        while peek().type == .op && ["<", ">", "<=", ">="].contains(peek().text) {
            let op = consume().text
            left = .binary(op: op, left: left, right: try parseUnitConversion())
        }
        return left
    }

    private func parseUnitConversion() throws -> AstNode {
        var left = try parseRange()
        while peek().type == .op && (peek().text == "in" || peek().text == "to") {
            let op = consume().text
            left = .binary(op: op, left: left, right: try parseRange())
        }
        return left
    }

    private func parseRange() throws -> AstNode {
        let first = try parseShift()
        if peek().type == .colon && ternaryDepth == 0 {
            consume()
            let second = try parseShift()
            if peek().type == .colon {
                consume()
                let third = try parseShift()
                return .range(start: first, end: third, step: second)
            }
            return .range(start: first, end: second, step: nil)
        }
        return first
    }

    private func parseShift() throws -> AstNode {
        var left = try parseAdditive()
        while peek().type == .op && ["<<", ">>", ">>>"].contains(peek().text) {
            let op = consume().text
            left = .binary(op: op, left: left, right: try parseAdditive())
        }
        return left
    }

    private func parseAdditive() throws -> AstNode {
        var left = try parseMultiplicative()
        while peek().type == .op && (peek().text == "+" || peek().text == "-") {
            let op = consume().text
            left = .binary(op: op, left: left, right: try parseMultiplicative())
        }
        return left
    }

    private func canImplicitMultiply(_ prev: AstNode) -> Bool {
        let next = peek()
        switch next.type {
        case .ident:
            return true
        case .lparen:
            switch prev {
            case .numberLit, .imagLit, .index, .matrixLit:
                return true
            default:
                return false
            }
        default:
            return false
        }
    }

    private func parseMultiplicative() throws -> AstNode {
        var left = try parseUnary()
        while true {
            let t = peek()
            if t.type == .op && ["*", "/", ".*", "./", "%", "mod"].contains(t.text) {
                let op = consume().text
                left = .binary(op: op, left: left, right: try parseUnary())
            } else if canImplicitMultiply(left) {
                var right = try parsePower()
                // Bind implicit unit multiplication (`10 ohm` in `230 V / 10 ohm`) tighter than `/`
                while canImplicitMultiply(right) {
                    right = .binary(op: "*", left: right, right: try parsePower())
                }
                left = .binary(op: "*", left: left, right: right)
            } else {
                break
            }
        }
        return left
    }

    private func parseUnary() throws -> AstNode {
        let t = peek()
        if t.type == .op && ["+", "-", "!", "~", "not"].contains(t.text) {
            let op = consume().text
            return .unary(op: op, expr: try parseUnary())
        }
        var expr = try parsePower()
        while canImplicitMultiply(expr) {
            expr = .binary(op: "*", left: expr, right: try parsePower())
        }
        return expr
    }

    private func parsePower() throws -> AstNode {
        let base = try parsePostfix()
        let t = peek()
        if t.type == .op && (t.text == "^" || t.text == ".^") {
            let op = consume().text
            let exp = try parseUnary()
            return .binary(op: op, left: base, right: exp)
        }
        return base
    }

    private func parsePostfix() throws -> AstNode {
        var expr = try parsePrimary()
        while true {
            let t = peek()
            if t.type == .lparen {
                consume()
                var args: [AstNode] = []
                if peek().type != .rparen {
                    while true {
                        args.append(try parseExpression())
                        if peek().type == .comma {
                            consume()
                        } else {
                            break
                        }
                    }
                }
                try expect(.rparen)
                expr = .call(callee: expr, args: args)
            } else if t.type == .lbracket {
                consume()
                var indices: [AstNode] = []
                if peek().type != .rbracket {
                    while true {
                        if peek().type == .colon {
                            consume()
                            indices.append(.range(start: .numberLit(1.0), end: .ident("end"), step: nil))
                        } else {
                            indices.append(try parseExpression())
                        }
                        if peek().type == .comma {
                            consume()
                        } else {
                            break
                        }
                    }
                }
                try expect(.rbracket)
                expr = .index(target: expr, indices: indices)
            } else if t.type == .dot {
                consume()
                let field = try expect(.ident).text
                expr = .member(target: expr, field: field)
            } else if t.type == .op && t.text == "'" {
                consume()
                expr = .postfix(op: "'", expr: expr)
            } else if t.type == .op && t.text == "!" && peek(1).text != "=" {
                consume()
                expr = .postfix(op: "!", expr: expr)
            } else if t.type == .op && t.text == "%" {
                let nextType = peek(1).type
                let isModulo = [.number, .imag, .ident, .lineRef, .lparen, .lbracket].contains(nextType)
                if !isModulo {
                    consume()
                    expr = .postfix(op: "%", expr: expr)
                } else {
                    break
                }
            } else {
                break
            }
        }
        return expr
    }

    private func parsePrimary() throws -> AstNode {
        let t = peek()
        switch t.type {
        case .number:
            consume()
            guard let val = Double(t.text) else {
                throw MathEvalError("Invalid number '\(t.text)'")
            }
            return .numberLit(val)
        case .imag:
            consume()
            guard let val = Double(t.text) else {
                throw MathEvalError("Invalid imaginary number '\(t.text)'")
            }
            return .imagLit(val)
        case .string:
            consume()
            return .stringLit(t.text)
        case .lineRef:
            consume()
            guard let idx = Int(t.text.dropFirst()) else {
                throw MathEvalError("Invalid line reference '\(t.text)'")
            }
            return .lineRef(idx)
        case .ident:
            consume()
            return .ident(t.text)
        case .op where ["mod", "to", "in", "and", "or", "xor", "not"].contains(t.text) && peek(1).type == .lparen:
            consume()
            return .ident(t.text)
        case .lparen:
            consume()
            let inner = try parseExpression()
            try expect(.rparen)
            return inner
        case .lbracket:
            return try parseMatrix()
        case .lbrace:
            return try parseObject()
        default:
            throw MathEvalError("Unexpected token '\(t.text)'")
        }
    }

    private func parseMatrix() throws -> AstNode {
        try expect(.lbracket)
        var rows: [[AstNode]] = []
        if peek().type != .rbracket {
            var currentRow: [AstNode] = []
            while true {
                if peek().type == .lbracket {
                    let sub = try parseMatrix()
                    if case .matrixLit(let subRows) = sub, subRows.count == 1 {
                        rows.append(subRows[0])
                    } else {
                        currentRow.append(sub)
                    }
                } else {
                    currentRow.append(try parseExpression())
                }

                switch peek().type {
                case .comma:
                    consume()
                case .semi:
                    consume()
                    if !currentRow.isEmpty {
                        rows.append(currentRow)
                        currentRow = []
                    }
                default:
                    break
                }
                if peek().type == .rbracket { break }
            }
            if !currentRow.isEmpty {
                rows.append(currentRow)
            }
        }
        try expect(.rbracket)
        return .matrixLit(rows: rows)
    }

    private func parseObject() throws -> AstNode {
        try expect(.lbrace)
        var fields: [AstObjectField] = []
        if peek().type != .rbrace {
            while true {
                let keyToken = consume()
                let key: String
                switch keyToken.type {
                case .ident, .string:
                    key = keyToken.text
                default:
                    throw MathEvalError("Expected object key, got '\(keyToken.text)'")
                }
                try expect(.colon)
                let val = try parseExpression()
                fields.append(AstObjectField(key: key, value: val))
                if peek().type == .comma {
                    consume()
                } else {
                    break
                }
            }
        }
        try expect(.rbrace)
        return .objectLit(fields: fields)
    }
}

public final class MathScope {
    public var vars: [String: MathValue] = [:]
    public var lineResults: [Int: MathValue] = [:]

    public init(vars: [String: MathValue] = [:], lineResults: [Int: MathValue] = [:]) {
        self.vars = vars
        self.lineResults = lineResults
    }

    public func copy() -> MathScope {
        MathScope(vars: vars, lineResults: lineResults)
    }
}

public enum MathEvaluator {
    public static func eval(_ node: AstNode, scope: MathScope) throws -> MathValue {
        switch node {
        case .numberLit(let value):
            return .number(value)
        case .imagLit(let value):
            return MathValue.complexOrReal(re: 0.0, im: value)
        case .stringLit(let value):
            return .string(value)
        case .lineRef(let lineIndex):
            guard let val = scope.lineResults[lineIndex] else {
                throw MathEvalError("Line $\(lineIndex) has no value")
            }
            return val
        case .ident(let name):
            if let v = scope.vars[name] { return v }
            if let c = MathFunctions.constants[name] { return c }
            if let u = UnitRegistry.resolve(name) { return .unit(value: 1.0, unit: u) }
            if MathFunctions.builtinFunctions.contains(name) {
                return .function(name: name, params: ["x"], body: .call(callee: .ident(name), args: [.ident("x")]), capturedScope: [:])
            }
            throw MathEvalError("Undefined symbol: \(name)")

        case .varAssign(let name, let expr):
            let v = try eval(expr, scope: scope)
            scope.vars[name] = v
            return v

        case .funcAssign(let name, let params, let body):
            let fn = MathValue.function(name: name, params: params, body: body, capturedScope: scope.vars)
            scope.vars[name] = fn
            return fn

        case .block(let statements):
            var last: MathValue = .null
            for s in statements {
                last = try eval(s, scope: scope)
            }
            return last

        case .unary(let op, let expr):
            let v = try eval(expr, scope: scope)
            switch op {
            case "+":
                return v
            case "-":
                switch v {
                case .number(let n): return .number(-n)
                case .complex(let re, let im): return MathValue.complexOrReal(re: -re, im: -im)
                case .unit(let val, let u): return .unit(value: -val, unit: u)
                case .matrix: return try MatrixOps.mapElementWise(v) { .number(-(try $0.asDouble())) }
                default: throw MathEvalError("Cannot negate \(v.typeName())")
                }
            case "!", "not":
                return .bool(!v.asBoolean())
            case "~":
                return .number(Double(~Int64(try v.asDouble())))
            default:
                throw MathEvalError("Unknown unary operator \(op)")
            }

        case .postfix(let op, let expr):
            let v = try eval(expr, scope: scope)
            switch op {
            case "!":
                return .number(try MathFunctions.factorial(try v.asDouble()))
            case "%":
                return .number((try v.asDouble()) / 100.0)
            case "'":
                switch v {
                case .matrix: return try MatrixOps.ctranspose(v)
                case .complex(let re, let im): return ComplexOps.conj((re, im))
                default: return v
                }
            default:
                throw MathEvalError("Unknown postfix operator \(op)")
            }

        case .ternary(let cond, let ifTrue, let ifFalse):
            let c = try eval(cond, scope: scope).asBoolean()
            return c ? (try eval(ifTrue, scope: scope)) : (try eval(ifFalse, scope: scope))

        case .range(let start, let end, let step):
            let s = try eval(start, scope: scope).asDouble()
            let e = try eval(end, scope: scope).asDouble()
            let st = step != nil ? (try eval(step!, scope: scope).asDouble()) : 1.0
            var items: [MathValue] = []
            var cur = s
            if st > 0 {
                while cur <= e + 1e-12 && items.count < 10000 {
                    items.append(.number(cur))
                    cur += st
                }
            } else if st < 0 {
                while cur >= e - 1e-12 && items.count < 10000 {
                    items.append(.number(cur))
                    cur += st
                }
            }
            return MathValue.vector(items)

        case .matrixLit(let rows):
            let evaledRows = try rows.map { row in
                try row.map { try eval($0, scope: scope) }
            }
            return .matrix(evaledRows)

        case .objectLit(let fields):
            var map: [String: MathValue] = [:]
            var orderedKeys: [String] = []
            for field in fields {
                if map[field.key] == nil { orderedKeys.append(field.key) }
                map[field.key] = try eval(field.value, scope: scope)
            }
            return .object(map, orderedKeys: orderedKeys)

        case .member(let target, let field):
            let t = try eval(target, scope: scope)
            guard case .object(let fields, _) = t else {
                throw MathEvalError("Cannot access property '\(field)' on \(t.typeName())")
            }
            return fields[field] ?? .null

        case .index(let target, let indices):
            let t = try eval(target, scope: scope)
            switch t {
            case .matrix(let rows):
                if t.isVector && indices.count == 1 {
                    let vec = rows[0]
                    let idxScope = scope.copy()
                    idxScope.vars["end"] = .number(Double(vec.count))
                    let idxVal = try eval(indices[0], scope: idxScope)
                    if case .matrix = idxVal {
                        let picked = try idxVal.flatValues().map { v -> MathValue in
                            let i = Int(try v.asDouble()) - 1
                            guard i >= 0 && i < vec.count else {
                                throw MathEvalError("Index \(i + 1) out of bounds")
                            }
                            return vec[i]
                        }
                        return MathValue.vector(picked)
                    } else {
                        let i = Int(try idxVal.asDouble()) - 1
                        guard i >= 0 && i < vec.count else {
                            throw MathEvalError("Index \(i + 1) out of bounds")
                        }
                        return vec[i]
                    }
                } else if indices.count == 2 {
                    let rScope = scope.copy()
                    rScope.vars["end"] = .number(Double(t.rowCount))
                    let rIdx = try eval(indices[0], scope: rScope)

                    let cScope = scope.copy()
                    cScope.vars["end"] = .number(Double(t.colCount))
                    let cIdx = try eval(indices[1], scope: cScope)

                    let rList: [Int]
                    if case .matrix = rIdx {
                        rList = try rIdx.flatValues().map { Int(try $0.asDouble()) - 1 }
                    } else {
                        rList = [Int(try rIdx.asDouble()) - 1]
                    }

                    let cList: [Int]
                    if case .matrix = cIdx {
                        cList = try cIdx.flatValues().map { Int(try $0.asDouble()) - 1 }
                    } else {
                        cList = [Int(try cIdx.asDouble()) - 1]
                    }

                    if rList.count == 1 && cList.count == 1 {
                        return rows[rList[0]][cList[0]]
                    }
                    let subRows = rList.map { r in cList.map { c in rows[r][c] } }
                    if subRows.count == 1 {
                        return MathValue.vector(subRows[0])
                    }
                    return .matrix(subRows)
                } else {
                    let flat = t.flatValues()
                    let idxScope = scope.copy()
                    idxScope.vars["end"] = .number(Double(flat.count))
                    let idx = Int(try eval(indices[0], scope: idxScope).asDouble()) - 1
                    guard idx >= 0 && idx < flat.count else {
                        throw MathEvalError("Index out of bounds")
                    }
                    return flat[idx]
                }

            case .object(let fields, _):
                guard case .string(let key) = try eval(indices[0], scope: scope) else {
                    throw MathEvalError("Object key must be a string")
                }
                return fields[key] ?? .null

            case .string(let value):
                let idxScope = scope.copy()
                idxScope.vars["end"] = .number(Double(value.count))
                let idx = Int(try eval(indices[0], scope: idxScope).asDouble()) - 1
                guard idx >= 0 && idx < value.count else {
                    throw MathEvalError("String index out of bounds")
                }
                let charIdx = value.index(value.startIndex, offsetBy: idx)
                return .string(String(value[charIdx]))

            default:
                throw MathEvalError("Cannot index \(t.typeName())")
            }

        case .call(let callee, let args):
            let evaledArgs = try args.map { try eval($0, scope: scope) }
            if case .ident(let fnName) = callee {
                if let userFn = scope.vars[fnName], case .function = userFn {
                    return try invokeUserFunction(userFn, args: evaledArgs, parentScope: scope)
                }
                return try MathFunctions.invokeBuiltIn(name: fnName, args: evaledArgs) { fnVal, callArgs in
                    try invokeCallable(fnVal, args: callArgs, parentScope: scope)
                }
            }
            let calleeVal = try eval(callee, scope: scope)
            return try invokeCallable(calleeVal, args: evaledArgs, parentScope: scope)

        case .binary(let op, let left, let right):
            switch op {
            case "&&", "and":
                let l = try eval(left, scope: scope).asBoolean()
                return l ? .bool(try eval(right, scope: scope).asBoolean()) : .bool(false)
            case "||", "or":
                let l = try eval(left, scope: scope).asBoolean()
                return l ? .bool(true) : .bool(try eval(right, scope: scope).asBoolean())
            case "in", "to":
                let lVal = try eval(left, scope: scope)
                let targetUnit = try resolveUnitExpression(right, scope: scope)
                guard case .unit(let val, let u) = lVal else {
                    throw MathEvalError("Left side of '\(op)' must be a unit value")
                }
                return .unit(value: try u.convertTo(val, target: targetUnit), unit: targetUnit)
            default:
                let l = try eval(left, scope: scope)
                let r = try eval(right, scope: scope)
                return try evalBinaryOp(op, l, r)
            }
        }
    }

    private static func resolveUnitExpression(_ node: AstNode, scope: MathScope) throws -> MathUnit {
        switch node {
        case .ident(let name):
            if let u = UnitRegistry.resolve(name) { return u }
            if let v = scope.vars[name], case .unit(_, let u) = v { return u }
            throw MathEvalError("Unknown unit '\(name)'")
        case .binary(let op, let left, let right):
            switch op {
            case "*":
                return try resolveUnitExpression(left, scope: scope).multiply(try resolveUnitExpression(right, scope: scope))
            case "/":
                return try resolveUnitExpression(left, scope: scope).divide(try resolveUnitExpression(right, scope: scope))
            case "^":
                let base = try resolveUnitExpression(left, scope: scope)
                let exp = Int(try eval(right, scope: scope).asDouble())
                return base.powUnit(exp)
            default:
                break
            }
        default:
            break
        }
        let v = try eval(node, scope: scope)
        if case .unit(_, let u) = v { return u }
        throw MathEvalError("Invalid unit expression")
    }

    private static func invokeCallable(_ fnVal: MathValue, args: [MathValue], parentScope: MathScope) throws -> MathValue {
        if case .function(let name, _, _, let capturedScope) = fnVal {
            if MathFunctions.builtinFunctions.contains(name) && capturedScope.isEmpty {
                return try MathFunctions.invokeBuiltIn(name: name, args: args) { f, a in
                    try invokeCallable(f, args: a, parentScope: parentScope)
                }
            }
            return try invokeUserFunction(fnVal, args: args, parentScope: parentScope)
        }
        throw MathEvalError("Value is not a function")
    }

    private static func invokeUserFunction(_ fn: MathValue, args: [MathValue], parentScope: MathScope) throws -> MathValue {
        guard case .function(let name, let params, let body, let capturedScope) = fn else {
            throw MathEvalError("Not a function")
        }
        guard args.count == params.count else {
            throw MathEvalError("Function \(name) expects \(params.count) argument(s), got \(args.count)")
        }
        let fnScope = parentScope.copy()
        for (k, v) in capturedScope { fnScope.vars[k] = v }
        for (idx, p) in params.enumerated() {
            fnScope.vars[p] = args[idx]
        }
        return try eval(body, scope: fnScope)
    }

    public static func evalBinaryOp(_ op: String, _ l: MathValue, _ r: MathValue) throws -> MathValue {
        // Matrix operations
        if case .matrix = l, op == "*" {
            if case .matrix = r {
                return try MatrixOps.multiply(l, r, addOp: { try evalBinaryOp("+", $0, $1) }, mulOp: { try evalBinaryOp("*", $0, $1) })
            }
        }
        if case .matrix(let lRows) = l, op == "^", case .number(let nVal) = r {
            let exp = Int(nVal)
            if exp == -1 { return try MatrixOps.inv(l) }
            if exp == 0 { return MatrixOps.eye(lRows.count) }
            if exp > 0 {
                var acc = l
                for _ in 2...exp {
                    acc = try evalBinaryOp("*", acc, l)
                }
                return acc
            }
        }
        if (l.isMatrix || r.isMatrix) && ["+", "-", ".*", "./", ".^", "*", "/"].contains(op) {
            let elemOp: String
            switch op {
            case ".*": elemOp = "*"
            case "./": elemOp = "/"
            case ".^": elemOp = "^"
            default: elemOp = op
            }
            return try MatrixOps.zipElementWise(l, r) { try evalBinaryOp(elemOp, $0, $1) }
        }

        // Unit operations
        if case .unit = l {
            return try evalUnitOp(op, l, r)
        }
        if case .unit = r {
            return try evalUnitOp(op, l, r)
        }

        // Complex operations
        if l.isComplex || r.isComplex {
            let lc = try l.asComplex()
            let rc = try r.asComplex()
            switch op {
            case "+": return ComplexOps.add(lc, rc)
            case "-": return ComplexOps.sub(lc, rc)
            case "*": return ComplexOps.mul(lc, rc)
            case "/": return ComplexOps.div(lc, rc)
            case "^": return try ComplexOps.pow(lc, rc)
            case "==": return .bool(abs(lc.re - rc.re) < 1e-12 && abs(lc.im - rc.im) < 1e-12)
            case "!=": return .bool(abs(lc.re - rc.re) >= 1e-12 || abs(lc.im - rc.im) >= 1e-12)
            default: throw MathEvalError("Unsupported operator '\(op)' for complex numbers")
            }
        }

        // String concatenation
        if op == "+" && (l.isString || r.isString) {
            return .string(l.format() + r.format())
        }

        // Equality on strings or booleans
        if op == "==" && (l.isString || r.isString || l.isBool || r.isBool) {
            return .bool(l.format() == r.format())
        }
        if op == "!=" && (l.isString || r.isString || l.isBool || r.isBool) {
            return .bool(l.format() != r.format())
        }

        // Real number operations
        let a = try l.asDouble()
        let b = try r.asDouble()
        switch op {
        case "+": return .number(a + b)
        case "-": return .number(a - b)
        case "*", ".*": return .number(a * b)
        case "/", "./": return .number(a / b)
        case "%", "mod": return .number(a - Foundation.floor(a / b) * b)
        case "^", ".^":
            if a < 0 && abs(b - Foundation.round(b)) > 1e-12 {
                return try ComplexOps.pow((a, 0.0), (b, 0.0))
            }
            return .number(Foundation.pow(a, b))
        case "==": return .bool(abs(a - b) < 1e-12)
        case "!=": return .bool(abs(a - b) >= 1e-12)
        case "<": return .bool(a < b)
        case ">": return .bool(a > b)
        case "<=": return .bool(a <= b + 1e-12)
        case ">=": return .bool(a >= b - 1e-12)
        case "xor": return .bool(l.asBoolean() != r.asBoolean())
        case "&": return .number(Double(Int64(a) & Int64(b)))
        case "|": return .number(Double(Int64(a) | Int64(b)))
        case "^|": return .number(Double(Int64(a) ^ Int64(b)))
        case "<<": return .number(Double(Int64(a) << Int(b)))
        case ">>": return .number(Double(Int64(a) >> Int(b)))
        case ">>>":
            let ua = UInt32(bitPattern: Int32(truncatingIfNeeded: Int64(a)))
            let ub = UInt32(Int(b))
            return .number(Double(ua >> ub))
        default:
            throw MathEvalError("Unknown operator '\(op)'")
        }
    }

    private static func evalUnitOp(_ op: String, _ l: MathValue, _ r: MathValue) throws -> MathValue {
        switch op {
        case "+", "-":
            guard case .unit(let lVal, let lUnit) = l, case .unit(let rVal, let rUnit) = r else {
                throw MathEvalError("Cannot add/subtract Unit and non-Unit")
            }
            guard lUnit.hasSameDimensions(rUnit) else {
                throw MathEvalError("Incompatible units: \(lUnit.name) and \(rUnit.name)")
            }
            let rConverted = try rUnit.convertTo(rVal, target: lUnit)
            let res = op == "+" ? lVal + rConverted : lVal - rConverted
            return .unit(value: res, unit: lUnit)

        case "*", ".*":
            switch (l, r) {
            case (.unit(let lVal, let lUnit), .unit(let rVal, let rUnit)):
                let baseProd = lUnit.toBase(lVal) * rUnit.toBase(rVal)
                let newU = lUnit.multiply(rUnit)
                if newU.dimensions.isEmpty { return .number(baseProd) }
                return .unit(value: newU.fromBase(baseProd), unit: newU)
            case (.unit(let lVal, let lUnit), _):
                return .unit(value: lVal * (try r.asDouble()), unit: lUnit)
            case (_, .unit(let rVal, let rUnit)):
                return .unit(value: (try l.asDouble()) * rVal, unit: rUnit)
            default:
                throw MathEvalError("Invalid unit multiplication")
            }

        case "/", "./":
            switch (l, r) {
            case (.unit(let lVal, let lUnit), .unit(let rVal, let rUnit)):
                let baseQuot = lUnit.toBase(lVal) / rUnit.toBase(rVal)
                let newU = lUnit.divide(rUnit)
                if newU.dimensions.isEmpty { return .number(baseQuot) }
                return .unit(value: newU.fromBase(baseQuot), unit: newU)
            case (.unit(let lVal, let lUnit), _):
                return .unit(value: lVal / (try r.asDouble()), unit: lUnit)
            case (_, .unit(let rVal, let rUnit)):
                let newU = rUnit.powUnit(-1)
                let baseVal = (try l.asDouble()) / rUnit.toBase(rVal)
                return .unit(value: newU.fromBase(baseVal), unit: newU)
            default:
                throw MathEvalError("Invalid unit division")
            }

        case "^", ".^":
            guard case .unit(let lVal, let lUnit) = l else {
                throw MathEvalError("Unit cannot be in exponent")
            }
            let exp = Int(try r.asDouble())
            let newU = lUnit.powUnit(exp)
            let baseVal = Foundation.pow(lUnit.toBase(lVal), Double(exp))
            return .unit(value: newU.fromBase(baseVal), unit: newU)

        case "==":
            guard case .unit(let lVal, let lUnit) = l, case .unit(let rVal, let rUnit) = r else {
                return .bool(false)
            }
            return .bool(lUnit.hasSameDimensions(rUnit) && abs(lUnit.toBase(lVal) - rUnit.toBase(rVal)) < 1e-9)
        case "!=":
            guard case .unit(let lVal, let lUnit) = l, case .unit(let rVal, let rUnit) = r else {
                return .bool(true)
            }
            return .bool(!lUnit.hasSameDimensions(rUnit) || abs(lUnit.toBase(lVal) - rUnit.toBase(rVal)) >= 1e-9)
        case "<":
            guard case .unit(let lVal, let lUnit) = l, case .unit(let rVal, let rUnit) = r else {
                throw MathEvalError("Cannot compare Unit with non-Unit")
            }
            return .bool(lUnit.toBase(lVal) < rUnit.toBase(rVal))
        case ">":
            guard case .unit(let lVal, let lUnit) = l, case .unit(let rVal, let rUnit) = r else {
                throw MathEvalError("Cannot compare Unit with non-Unit")
            }
            return .bool(lUnit.toBase(lVal) > rUnit.toBase(rVal))
        case "<=":
            guard case .unit(let lVal, let lUnit) = l, case .unit(let rVal, let rUnit) = r else {
                throw MathEvalError("Cannot compare Unit with non-Unit")
            }
            return .bool(lUnit.toBase(lVal) <= rUnit.toBase(rVal) + 1e-9)
        case ">=":
            guard case .unit(let lVal, let lUnit) = l, case .unit(let rVal, let rUnit) = r else {
                throw MathEvalError("Cannot compare Unit with non-Unit")
            }
            return .bool(lUnit.toBase(lVal) >= rUnit.toBase(rVal) - 1e-9)
        default:
            throw MathEvalError("Unsupported operator '\(op)' for units")
        }
    }
}

private extension MathValue {
    var isMatrix: Bool {
        if case .matrix = self { return true }
        return false
    }
    var isComplex: Bool {
        if case .complex = self { return true }
        return false
    }
    var isString: Bool {
        if case .string = self { return true }
        return false
    }
    var isBool: Bool {
        if case .bool = self { return true }
        return false
    }
}

public struct LineEvaluation: Equatable, Sendable {
    public let lineNumber: Int
    public let rawLine: String
    public let value: MathValue?
    public let formattedResult: String?
    public let numericValue: Double?
    public let isError: Bool
    public let errorMessage: String?

    public init(
        lineNumber: Int,
        rawLine: String,
        value: MathValue? = nil,
        formattedResult: String? = nil,
        numericValue: Double? = nil,
        isError: Bool = false,
        errorMessage: String? = nil
    ) {
        self.lineNumber = lineNumber
        self.rawLine = rawLine
        self.value = value
        self.formattedResult = formattedResult
        self.numericValue = numericValue
        self.isError = isError
        self.errorMessage = errorMessage
    }
}

public struct DocumentEvaluation: Equatable, Sendable {
    public let lines: [LineEvaluation]
    public let scopeVariables: [String: String]
    public let sum: Double
    public let average: Double
    public let numericCount: Int

    public init(
        lines: [LineEvaluation],
        scopeVariables: [String: String],
        sum: Double,
        average: Double,
        numericCount: Int
    ) {
        self.lines = lines
        self.scopeVariables = scopeVariables
        self.sum = sum
        self.average = average
        self.numericCount = numericCount
    }
}

public enum MathEngine {
    public static func evaluateExpression(_ expr: String, scope: MathScope = MathScope()) throws -> MathValue {
        let stripped = MathTokenizer.stripInlineComment(expr).trimmingCharacters(in: .whitespacesAndNewlines)
        if stripped.isEmpty { return .null }
        let tokens = try MathTokenizer.tokenize(stripped)
        let ast = try MathParser(tokens: tokens).parseProgram()
        return try MathEvaluator.eval(ast, scope: scope)
    }

    public static func evaluateDocument(_ text: String) -> DocumentEvaluation {
        let rawLines = text.components(separatedBy: "\n")
        let scope = MathScope()
        var evaluations: [LineEvaluation] = []
        var numericValues: [Double] = []

        for (index, rawLine) in rawLines.enumerated() {
            let lineNum = index + 1
            let trimmed = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            let codeOnly = MathTokenizer.stripInlineComment(rawLine).trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmed.isEmpty || codeOnly.isEmpty {
                evaluations.append(LineEvaluation(lineNumber: lineNum, rawLine: rawLine))
                continue
            }

            do {
                let value = try evaluateExpression(codeOnly, scope: scope)
                if value != .null {
                    scope.lineResults[lineNum] = value
                    scope.vars["ans"] = value
                }

                let formatted: String?
                switch value {
                case .null, .function:
                    formatted = nil
                default:
                    formatted = value.format()
                }

                let numVal: Double?
                switch value {
                case .number(let v) where v.isFinite:
                    numVal = v
                case .unit(let v, _) where v.isFinite:
                    numVal = v
                default:
                    numVal = nil
                }

                if let numVal {
                    numericValues.append(numVal)
                }

                evaluations.append(
                    LineEvaluation(
                        lineNumber: lineNum,
                        rawLine: rawLine,
                        value: value,
                        formattedResult: formatted,
                        numericValue: numVal
                    )
                )
            } catch {
                evaluations.append(
                    LineEvaluation(
                        lineNumber: lineNum,
                        rawLine: rawLine,
                        isError: true,
                        errorMessage: error.localizedDescription
                    )
                )
            }
        }

        var scopePreview: [String: String] = [:]
        for (k, v) in scope.vars where k != "ans" {
            scopePreview[k] = v.format()
        }

        let sum = numericValues.reduce(0.0, +)
        let avg = numericValues.isEmpty ? 0.0 : sum / Double(numericValues.count)

        return DocumentEvaluation(
            lines: evaluations,
            scopeVariables: scopePreview,
            sum: sum,
            average: avg,
            numericCount: numericValues.count
        )
    }
}
