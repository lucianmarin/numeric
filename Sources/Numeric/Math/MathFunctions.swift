import Foundation

public enum MathFunctions {
    private static let eConst = M_E

    public static let constants: [String: MathValue] = [
        "pi": .number(.pi),
        "PI": .number(.pi),
        "e": .number(eConst),
        "E": .number(eConst),
        "tau": .number(2.0 * .pi),
        "phi": .number((1.0 + sqrt(5.0)) / 2.0),
        "i": .complex(re: 0.0, im: 1.0),
        "Infinity": .number(.infinity),
        "NaN": .number(.nan),
        "true": .bool(true),
        "false": .bool(false),
        "null": .null,
        "LN2": .number(log(2.0)),
        "LN10": .number(log(10.0)),
        "LOG2E": .number(log2(eConst)),
        "LOG10E": .number(log10(eConst)),
        "SQRT1_2": .number(sqrt(0.5)),
        "SQRT2": .number(sqrt(2.0)),
        "version": .string("13.0.3-swift"),

        // Physical constants (MathJS CODATA values with units)
        "speedOfLight": .unit(value: 299792458.0, unit: UnitRegistry.resolve("m")!.divide(UnitRegistry.resolve("s")!)),
        "gravitationConstant": .number(6.67430e-11),
        "planckConstant": .number(6.62607015e-34),
        "reducedPlanckConstant": .number(1.054571817e-34),
        "magneticConstant": .number(1.25663706212e-6),
        "electricConstant": .number(8.8541878128e-12),
        "vacuumImpedance": .number(376.730313668),
        "coulomb": .number(8.9875517923e9),
        "elementaryCharge": .number(1.602176634e-19),
        "bohrMagneton": .number(9.2740100783e-24),
        "conductanceQuantum": .number(7.748091729e-5),
        "inverseConductanceQuantum": .number(12906.40372),
        "magneticFluxQuantum": .number(2.067833848e-15),
        "nuclearMagneton": .number(5.0507837461e-27),
        "klitzing": .number(25812.80745),
        "bohrRadius": .number(5.29177210903e-11),
        "classicalElectronRadius": .number(2.8179403262e-15),
        "electronMass": .number(9.1093837015e-31),
        "fermiCoupling": .number(1.1663787e-5),
        "fineStructure": .number(7.2973525693e-3),
        "hartreeEnergy": .number(4.3597447222071e-18),
        "protonMass": .number(1.67262192369e-27),
        "deuteronMass": .number(3.3435837724e-27),
        "neutronMass": .number(1.67492749804e-27),
        "quantumOfCirculation": .number(3.6369475516e-4),
        "rydberg": .number(10973731.568160),
        "thomsonCrossSection": .number(6.6524587321e-29),
        "weakMixingAngle": .number(0.22290),
        "efimovFactor": .number(22.7),
        "atomicMass": .number(1.66053906660e-27),
        "avogadro": .number(6.02214076e23),
        "boltzmann": .number(1.380649e-23),
        "faraday": .number(96485.33212),
        "firstRadiation": .number(3.741771852e-16),
        "loschmidt": .number(2.686780111e25),
        "gasConstant": .number(8.314462618),
        "molarPlanckConstant": .number(3.990312712e-10),
        "molarVolume": .number(0.02241396954),
        "sackurTetrode": .number(-1.16487052358),
        "secondRadiation": .number(0.01438776877),
        "stefanBoltzmann": .number(5.670374419e-8),
        "wienDisplacement": .number(2.897771955e-3),
        "gravity": .unit(value: 9.80665, unit: UnitRegistry.resolve("m")!.divide(UnitRegistry.resolve("s2")!)),
        "atm": .unit(value: 101325.0, unit: UnitRegistry.resolve("Pa")!)
    ]

    public static func factorial(_ n: Double) throws -> Double {
        if n < 0 {
            throw MathEvalError("Factorial only defined for non-negative numbers")
        }
        let intN = Int(n)
        if abs(n - Double(intN)) > 1e-12 {
            return gamma(n + 1.0)
        }
        if intN > 170 { return .infinity }
        if intN <= 1 { return 1.0 }
        var res = 1.0
        for i in 2...intN {
            res *= Double(i)
        }
        return res
    }

    public static func gamma(_ z: Double) -> Double {
        if z < 0.5 {
            return .pi / (sin(.pi * z) * gamma(1.0 - z))
        }
        let x = z - 1.0
        let p: [Double] = [
            0.9999999999998099,
            676.5203681218851,
            -1259.1392167224028,
            771.3234287776531,
            -176.6150291621406,
            12.507343278686905,
            -0.13857109526572012,
            9.984369578019572e-6,
            1.5056327351493116e-7
        ]
        var a = p[0]
        let t = x + 7.5
        for i in 1..<p.count {
            a += p[i] / (x + Double(i))
        }
        return sqrt(2.0 * .pi) * pow(t, x + 0.5) * exp(-t) * a
    }

    public static func erf(_ x: Double) -> Double {
        let sign = x < 0 ? -1.0 : 1.0
        let ax = abs(x)
        let t = 1.0 / (1.0 + 0.3275911 * ax)
        let y = 1.0 - (((((1.061405429 * t - 1.453152027) * t) + 1.421413741) * t - 0.284496736) * t + 0.254829592) * t * exp(-ax * ax)
        return sign * y
    }

    public static func gcd(_ a: Int64, _ b: Int64) -> Int64 {
        var x = abs(a)
        var y = abs(b)
        while y != 0 {
            let t = y
            y = x % y
            x = t
        }
        return x
    }

    public static func lcm(_ a: Int64, _ b: Int64) -> Int64 {
        if a == 0 || b == 0 { return 0 }
        return abs(a / gcd(a, b) * b)
    }

    public static func isPrime(_ n: Int64) -> Bool {
        if n < 2 { return false }
        if n == 2 || n == 3 { return true }
        if n % 2 == 0 || n % 3 == 0 { return false }
        var i: Int64 = 5
        while i * i <= n {
            if n % i == 0 || n % (i + 2) == 0 { return false }
            i += 6
        }
        return true
    }

    public static func combinations(_ n: Int64, _ k: Int64) throws -> Double {
        if k < 0 || k > n {
            throw MathEvalError("combinations: k must be between 0 and n")
        }
        let kk = min(k, n - k)
        if kk == 0 { return 1.0 }
        var res = 1.0
        for i in 1...kk {
            res = res * Double(n - kk + i) / Double(i)
        }
        return Foundation.round(res)
    }

    public static func permutations(_ n: Int64, _ k: Int64? = nil) throws -> Double {
        let kk = k ?? n
        if kk < 0 || kk > n {
            throw MathEvalError("permutations: k must be between 0 and n")
        }
        if kk == 0 { return 1.0 }
        var res = 1.0
        for i in (n - kk + 1)...n {
            res *= Double(i)
        }
        return res
    }

    private static func extractNumbers(_ args: [MathValue]) throws -> [Double] {
        var out: [Double] = []
        for arg in args {
            switch arg {
            case .matrix:
                for v in arg.flatValues() {
                    out.append(try v.asDouble())
                }
            default:
                out.append(try arg.asDouble())
            }
        }
        if out.isEmpty {
            throw MathEvalError("Function requires at least one numeric value")
        }
        return out
    }

    private static func applyUnaryMath(_ arg: MathValue, _ realOp: (Double) throws -> MathValue) throws -> MathValue {
        switch arg {
        case .matrix:
            return try MatrixOps.mapElementWise(arg) { try applyUnaryMath($0, realOp) }
        case .unit(let val, let unit):
            if unit.dimensions == [.angle: 1] {
                return try realOp(unit.toBase(val))
            } else {
                return try realOp(val)
            }
        default:
            return try realOp(try arg.asDouble())
        }
    }

    private static func requireArg(_ args: [MathValue], _ index: Int = 0, name: String) throws -> MathValue {
        guard index < args.count else {
            throw MathEvalError("\(name)() requires at least \(index + 1) argument(s)")
        }
        return args[index]
    }

    public static func invokeBuiltIn(
        name: String,
        args: [MathValue],
        evaluator: (MathValue, [MathValue]) throws -> MathValue
    ) throws -> MathValue {
        switch name {
        case "abs":
            let a = try requireArg(args, name: name)
            switch a {
            case .complex(let re, let im):
                return .number(ComplexOps.absVal((re, im)))
            case .unit(let val, let unit):
                return .unit(value: abs(val), unit: unit)
            case .matrix:
                return try MatrixOps.mapElementWise(a) { try invokeBuiltIn(name: "abs", args: [$0], evaluator: evaluator) }
            default:
                return .number(abs(try a.asDouble()))
            }

        case "add":
            guard args.count >= 2 else { throw MathEvalError("add() requires 2 arguments") }
            var acc = args[0]
            for v in args.dropFirst() {
                acc = try MathEvaluator.evalBinaryOp("+", acc, v)
            }
            return acc

        case "subtract":
            guard args.count == 2 else { throw MathEvalError("subtract() requires 2 arguments") }
            return try MathEvaluator.evalBinaryOp("-", args[0], args[1])

        case "multiply":
            guard args.count >= 2 else { throw MathEvalError("multiply() requires 2 arguments") }
            var acc = args[0]
            for v in args.dropFirst() {
                acc = try MathEvaluator.evalBinaryOp("*", acc, v)
            }
            return acc

        case "divide":
            guard args.count == 2 else { throw MathEvalError("divide() requires 2 arguments") }
            return try MathEvaluator.evalBinaryOp("/", args[0], args[1])

        case "mod":
            guard args.count == 2 else { throw MathEvalError("mod() requires 2 arguments") }
            return try MathEvaluator.evalBinaryOp("%", args[0], args[1])

        case "pow":
            guard args.count == 2 else { throw MathEvalError("pow() requires 2 arguments") }
            return try MathEvaluator.evalBinaryOp("^", args[0], args[1])

        case "dotMultiply":
            guard args.count == 2 else { throw MathEvalError("dotMultiply() requires 2 arguments") }
            return try MathEvaluator.evalBinaryOp(".*", args[0], args[1])

        case "dotDivide":
            guard args.count == 2 else { throw MathEvalError("dotDivide() requires 2 arguments") }
            return try MathEvaluator.evalBinaryOp("./", args[0], args[1])

        case "dotPow":
            guard args.count == 2 else { throw MathEvalError("dotPow() requires 2 arguments") }
            return try MathEvaluator.evalBinaryOp(".^", args[0], args[1])

        case "round":
            let x = try requireArg(args, name: name)
            let decimals = args.count >= 2 ? Int(try args[1].asDouble()) : 0
            let factor = pow(10.0, Double(decimals))
            return try applyUnaryMath(x) { .number(Foundation.round($0 * factor) / factor) }

        case "floor":
            return try applyUnaryMath(try requireArg(args, name: name)) { .number(Foundation.floor($0)) }
        case "ceil":
            return try applyUnaryMath(try requireArg(args, name: name)) { .number(Foundation.ceil($0)) }
        case "fix":
            return try applyUnaryMath(try requireArg(args, name: name)) { .number(Foundation.trunc($0)) }
        case "sign":
            return try applyUnaryMath(try requireArg(args, name: name)) { v in
                if v > 0 { return .number(1.0) }
                if v < 0 { return .number(-1.0) }
                return .number(0.0)
            }
        case "cbrt":
            return try applyUnaryMath(try requireArg(args, name: name)) { .number(Foundation.cbrt($0)) }
        case "cube":
            return try applyUnaryMath(try requireArg(args, name: name)) { .number($0 * $0 * $0) }
        case "square":
            return try applyUnaryMath(try requireArg(args, name: name)) { .number($0 * $0) }
        case "sqrt":
            let a = try requireArg(args, name: name)
            if case .complex(let re, let im) = a {
                return ComplexOps.sqrtVal((re, im))
            } else if case .number(let v) = a, v < 0 {
                return ComplexOps.sqrtVal((v, 0.0))
            } else {
                return try applyUnaryMath(a) { v in
                    if v < 0 {
                        return ComplexOps.sqrtVal((v, 0.0))
                    }
                    return .number(Foundation.sqrt(v))
                }
            }
        case "nthRoot":
            let x = try requireArg(args, 0, name: name).asDouble()
            let n = args.count >= 2 ? try args[1].asDouble() : 2.0
            return .number(pow(x, 1.0 / n))
        case "hypot":
            let nums = try extractNumbers(args)
            return .number(sqrt(nums.reduce(0.0) { $0 + $1 * $1 }))
        case "norm":
            let a = try requireArg(args, name: name)
            switch a {
            case .matrix:
                return .number(try MatrixOps.norm(a))
            case .complex(let re, let im):
                return .number(ComplexOps.absVal((re, im)))
            default:
                return .number(abs(try a.asDouble()))
            }

        case "exp":
            let a = try requireArg(args, name: name)
            if case .complex(let re, let im) = a {
                return ComplexOps.expVal((re, im))
            }
            return try applyUnaryMath(a) { .number(Foundation.exp($0)) }
        case "expm1":
            return try applyUnaryMath(try requireArg(args, name: name)) { .number(Foundation.expm1($0)) }
        case "log", "ln":
            let a = try requireArg(args, name: name)
            if args.count == 2 {
                let base = try args[1].asDouble()
                return .number(Foundation.log(try a.asDouble()) / Foundation.log(base))
            } else if case .complex(let re, let im) = a {
                return ComplexOps.lnVal((re, im))
            } else {
                return try applyUnaryMath(a) { .number(Foundation.log($0)) }
            }
        case "log10":
            return try applyUnaryMath(try requireArg(args, name: name)) { .number(Foundation.log10($0)) }
        case "log2":
            return try applyUnaryMath(try requireArg(args, name: name)) { .number(Foundation.log2($0)) }
        case "log1p":
            return try applyUnaryMath(try requireArg(args, name: name)) { .number(Foundation.log1p($0)) }

        case "gcd":
            let nums = try extractNumbers(args).map { Int64($0) }
            guard let first = nums.first else { throw MathEvalError("gcd() requires arguments") }
            let g = nums.dropFirst().reduce(first) { gcd($0, $1) }
            return .number(Double(g))
        case "lcm":
            let nums = try extractNumbers(args).map { Int64($0) }
            guard let first = nums.first else { throw MathEvalError("lcm() requires arguments") }
            let l = nums.dropFirst().reduce(first) { lcm($0, $1) }
            return .number(Double(l))
        case "xgcd":
            var a = Int64(try requireArg(args, 0, name: name).asDouble())
            var b = Int64(try requireArg(args, 1, name: name).asDouble())
            var x0: Int64 = 1, x1: Int64 = 0
            var y0: Int64 = 0, y1: Int64 = 1
            while b != 0 {
                let q = a / b
                let r = a % b
                a = b; b = r
                let nx = x0 - q * x1; x0 = x1; x1 = nx
                let ny = y0 - q * y1; y0 = y1; y1 = ny
            }
            return MathValue.vector([.number(Double(a)), .number(Double(x0)), .number(Double(y0))])
        case "isPrime":
            return .bool(isPrime(Int64(try requireArg(args, name: name).asDouble())))
        case "isInteger":
            let d = try requireArg(args, name: name).asDouble()
            return .bool(d.isFinite && abs(d - Foundation.round(d)) < 1e-12)
        case "isPositive":
            return .bool(try requireArg(args, name: name).asDouble() > 0.0)
        case "isNegative":
            return .bool(try requireArg(args, name: name).asDouble() < 0.0)
        case "isZero":
            return .bool(abs(try requireArg(args, name: name).asDouble()) < 1e-15)
        case "isNaN":
            return .bool(try requireArg(args, name: name).asDouble().isNaN)
        case "isNumeric":
            let a = try requireArg(args, name: name)
            if case .number = a { return .bool(true) }
            if case .complex = a { return .bool(true) }
            return .bool(false)

        case "sin":
            let a = try requireArg(args, name: name)
            if case .complex(let re, let im) = a { return ComplexOps.sinVal((re, im)) }
            return try applyUnaryMath(a) { .number(Foundation.sin($0)) }
        case "cos":
            let a = try requireArg(args, name: name)
            if case .complex(let re, let im) = a { return ComplexOps.cosVal((re, im)) }
            return try applyUnaryMath(a) { .number(Foundation.cos($0)) }
        case "tan":
            let a = try requireArg(args, name: name)
            if case .complex(let re, let im) = a { return try ComplexOps.tanVal((re, im)) }
            return try applyUnaryMath(a) { .number(Foundation.tan($0)) }
        case "asin":
            return try applyUnaryMath(try requireArg(args, name: name)) { .number(Foundation.asin($0)) }
        case "acos":
            return try applyUnaryMath(try requireArg(args, name: name)) { .number(Foundation.acos($0)) }
        case "atan":
            return try applyUnaryMath(try requireArg(args, name: name)) { .number(Foundation.atan($0)) }
        case "atan2":
            return .number(Foundation.atan2(try requireArg(args, 0, name: name).asDouble(), try requireArg(args, 1, name: name).asDouble()))
        case "sinh":
            return try applyUnaryMath(try requireArg(args, name: name)) { .number(Foundation.sinh($0)) }
        case "cosh":
            return try applyUnaryMath(try requireArg(args, name: name)) { .number(Foundation.cosh($0)) }
        case "tanh":
            return try applyUnaryMath(try requireArg(args, name: name)) { .number(Foundation.tanh($0)) }
        case "asinh":
            return try applyUnaryMath(try requireArg(args, name: name)) { .number(Foundation.asinh($0)) }
        case "acosh":
            return try applyUnaryMath(try requireArg(args, name: name)) { .number(Foundation.acosh($0)) }
        case "atanh":
            return try applyUnaryMath(try requireArg(args, name: name)) { .number(Foundation.atanh($0)) }
        case "sec":
            return try applyUnaryMath(try requireArg(args, name: name)) { .number(1.0 / Foundation.cos($0)) }
        case "csc":
            return try applyUnaryMath(try requireArg(args, name: name)) { .number(1.0 / Foundation.sin($0)) }
        case "cot":
            return try applyUnaryMath(try requireArg(args, name: name)) { .number(1.0 / Foundation.tan($0)) }
        case "asec":
            return try applyUnaryMath(try requireArg(args, name: name)) { .number(Foundation.acos(1.0 / $0)) }
        case "acsc":
            return try applyUnaryMath(try requireArg(args, name: name)) { .number(Foundation.asin(1.0 / $0)) }
        case "acot":
            return try applyUnaryMath(try requireArg(args, name: name)) { .number(Foundation.atan(1.0 / $0)) }
        case "sech":
            return try applyUnaryMath(try requireArg(args, name: name)) { .number(1.0 / Foundation.cosh($0)) }
        case "csch":
            return try applyUnaryMath(try requireArg(args, name: name)) { .number(1.0 / Foundation.sinh($0)) }
        case "coth":
            return try applyUnaryMath(try requireArg(args, name: name)) { .number(Foundation.cosh($0) / Foundation.sinh($0)) }
        case "asech":
            return try applyUnaryMath(try requireArg(args, name: name)) { .number(Foundation.acosh(1.0 / $0)) }
        case "acsch":
            return try applyUnaryMath(try requireArg(args, name: name)) { .number(Foundation.asinh(1.0 / $0)) }
        case "acoth":
            return try applyUnaryMath(try requireArg(args, name: name)) { .number(Foundation.atanh(1.0 / $0)) }
        case "deg":
            return .number(try requireArg(args, name: name).asDouble() * 180.0 / .pi)
        case "rad":
            return .number(try requireArg(args, name: name).asDouble() * .pi / 180.0)

        case "complex":
            if args.isEmpty { return .complex(re: 0.0, im: 0.0) }
            if args.count == 1 {
                let c = try args[0].asComplex()
                return .complex(re: c.re, im: c.im)
            }
            return MathValue.complexOrReal(re: try args[0].asDouble(), im: try args[1].asDouble())
        case "re":
            return .number(try requireArg(args, name: name).asComplex().re)
        case "im":
            return .number(try requireArg(args, name: name).asComplex().im)
        case "conj":
            return ComplexOps.conj(try requireArg(args, name: name).asComplex())
        case "arg":
            return .number(ComplexOps.arg(try requireArg(args, name: name).asComplex()))

        case "sum":
            let nums = try extractNumbers(args)
            return .number(nums.reduce(0.0, +))
        case "prod":
            let nums = try extractNumbers(args)
            return .number(nums.reduce(1.0, *))
        case "mean", "avg":
            let nums = try extractNumbers(args)
            return .number(nums.reduce(0.0, +) / Double(nums.count))
        case "median":
            let sorted = try extractNumbers(args).sorted()
            let mid = sorted.count / 2
            let med = sorted.count % 2 == 1 ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2.0
            return .number(med)
        case "min":
            let nums = try extractNumbers(args)
            return .number(nums.min() ?? .nan)
        case "max":
            let nums = try extractNumbers(args)
            return .number(nums.max() ?? .nan)
        case "variance":
            let nums = try extractNumbers(args)
            if nums.count <= 1 { return .number(0.0) }
            let m = nums.reduce(0.0, +) / Double(nums.count)
            let sumSq = nums.reduce(0.0) { $0 + ($1 - m) * ($1 - m) }
            return .number(sumSq / Double(nums.count - 1))
        case "std":
            let v = try invokeBuiltIn(name: "variance", args: args, evaluator: evaluator).asDouble()
            return .number(sqrt(v))
        case "mad":
            let nums = try extractNumbers(args)
            let med = try invokeBuiltIn(name: "median", args: args, evaluator: evaluator).asDouble()
            let devs = nums.map { MathValue.number(abs($0 - med)) }
            return try invokeBuiltIn(name: "median", args: [MathValue.vector(devs)], evaluator: evaluator)
        case "mode":
            let nums = try extractNumbers(args)
            var counts: [Double: Int] = [:]
            for v in nums { counts[v, default: 0] += 1 }
            let maxCount = counts.values.max() ?? 0
            let modes = counts.filter { $0.value == maxCount }.keys.sorted().map { MathValue.number($0) }
            return MathValue.vector(modes)
        case "cumsum":
            let nums = try extractNumbers(args)
            var running = 0.0
            let res = nums.map { v -> MathValue in
                running += v
                return .number(running)
            }
            return MathValue.vector(res)
        case "diff":
            let nums = try extractNumbers(args)
            if nums.count < 2 { return MathValue.vector([]) }
            let res = (1..<nums.count).map { MathValue.number(nums[$0] - nums[$0 - 1]) }
            return MathValue.vector(res)
        case "corr":
            let a = try requireArg(args, 0, name: name).flatValues().map { try $0.asDouble() }
            let b = try requireArg(args, 1, name: name).flatValues().map { try $0.asDouble() }
            guard a.count == b.count && !a.isEmpty else {
                throw MathEvalError("corr() requires non-empty vectors of equal length")
            }
            let ma = a.reduce(0.0, +) / Double(a.count)
            let mb = b.reduce(0.0, +) / Double(b.count)
            var num = 0.0, da = 0.0, db = 0.0
            for i in a.indices {
                let xa = a[i] - ma
                let xb = b[i] - mb
                num += xa * xb
                da += xa * xa
                db += xb * xb
            }
            return .number(num / sqrt(da * db))
        case "quantileSeq":
            let nums = try requireArg(args, 0, name: name).flatValues().map { try $0.asDouble() }.sorted()
            let p = try requireArg(args, 1, name: name).asDouble()
            guard !nums.isEmpty else { throw MathEvalError("quantileSeq() requires non-empty sequence") }
            let pos = p * Double(nums.count - 1)
            let lower = max(0, min(nums.count - 1, Int(floor(pos))))
            let upper = max(0, min(nums.count - 1, Int(ceil(pos))))
            let weight = pos - Double(lower)
            return .number(nums[lower] * (1.0 - weight) + nums[upper] * weight)

        case "factorial":
            return try applyUnaryMath(try requireArg(args, name: name)) { .number(try factorial($0)) }
        case "gamma":
            return try applyUnaryMath(try requireArg(args, name: name)) { .number(gamma($0)) }
        case "lgamma":
            return try applyUnaryMath(try requireArg(args, name: name)) { .number(Foundation.log(abs(gamma($0)))) }
        case "erf":
            return try applyUnaryMath(try requireArg(args, name: name)) { .number(erf($0)) }
        case "combinations":
            return .number(try combinations(Int64(try requireArg(args, 0, name: name).asDouble()), Int64(try requireArg(args, 1, name: name).asDouble())))
        case "combinationsWithRep":
            let n = Int64(try requireArg(args, 0, name: name).asDouble())
            let k = Int64(try requireArg(args, 1, name: name).asDouble())
            return .number(try combinations(n + k - 1, k))
        case "permutations":
            let n = Int64(try requireArg(args, 0, name: name).asDouble())
            let k = args.count >= 2 ? Int64(try args[1].asDouble()) : n
            return .number(try permutations(n, k))
        case "catalan":
            let n = Int64(try requireArg(args, 0, name: name).asDouble())
            return .number(try combinations(2 * n, n) / Double(n + 1))
        case "stirlingS2":
            let n = Int(try requireArg(args, 0, name: name).asDouble())
            let k = Int(try requireArg(args, 1, name: name).asDouble())
            var sum = 0.0
            for j in 0...k {
                let sign = (k - j) % 2 == 1 ? -1.0 : 1.0
                sum += sign * (try combinations(Int64(k), Int64(j))) * pow(Double(j), Double(n))
            }
            return .number(Foundation.round(sum / (try factorial(Double(k)))))
        case "bellNumbers":
            let n = Int(try requireArg(args, 0, name: name).asDouble())
            var total = 0.0
            for k in 0...n {
                total += try invokeBuiltIn(name: "stirlingS2", args: [.number(Double(n)), .number(Double(k))], evaluator: evaluator).asDouble()
            }
            return .number(total)
        case "random":
            switch args.count {
            case 0: return .number(Double.random(in: 0.0..<1.0))
            case 1:
                let upper = try args[0].asDouble()
                return .number(upper > 0 ? Double.random(in: 0.0..<upper) : 0.0)
            default:
                let lo = try args[0].asDouble()
                let hi = try args[1].asDouble()
                return .number(hi > lo ? Double.random(in: lo..<hi) : lo)
            }
        case "randomInt":
            switch args.count {
            case 1:
                let hi = Int64(try args[0].asDouble())
                return .number(Double(hi > 0 ? Int64.random(in: 0..<hi) : 0))
            default:
                let lo = Int64(try requireArg(args, 0, name: name).asDouble())
                let hi = Int64(try requireArg(args, 1, name: name).asDouble())
                return .number(Double(hi > lo ? Int64.random(in: lo..<hi) : lo))
            }
        case "pickRandom":
            let list = try requireArg(args, name: name).flatValues()
            if list.isEmpty { return .null }
            return list.randomElement() ?? .null

        case "matrix":
            return args.first ?? .matrix([])
        case "det":
            return .number(try MatrixOps.det(try requireArg(args, name: name)))
        case "inv":
            return try MatrixOps.inv(try requireArg(args, name: name))
        case "transpose":
            return try MatrixOps.transpose(try requireArg(args, name: name))
        case "ctranspose":
            return try MatrixOps.ctranspose(try requireArg(args, name: name))
        case "trace":
            return .number(try MatrixOps.trace(try requireArg(args, name: name)))
        case "lusolve", "lsolve", "usolve":
            return try MatrixOps.lusolve(try requireArg(args, 0, name: name), try requireArg(args, 1, name: name))
        case "dot":
            return .number(try MatrixOps.dot(try requireArg(args, 0, name: name), try requireArg(args, 1, name: name)))
        case "cross":
            return try MatrixOps.cross(try requireArg(args, 0, name: name), try requireArg(args, 1, name: name))
        case "kron":
            return try MatrixOps.kron(try requireArg(args, 0, name: name), try requireArg(args, 1, name: name))
        case "identity", "eye":
            let r = args.count >= 1 ? Int(try args[0].asDouble()) : 1
            let c = args.count >= 2 ? Int(try args[1].asDouble()) : r
            return MatrixOps.eye(r, c)
        case "zeros":
            let r = args.count >= 1 ? Int(try args[0].asDouble()) : 1
            let c = args.count >= 2 ? Int(try args[1].asDouble()) : 1
            return MatrixOps.zeros(r, c)
        case "ones":
            let r = args.count >= 1 ? Int(try args[0].asDouble()) : 1
            let c = args.count >= 2 ? Int(try args[1].asDouble()) : 1
            return MatrixOps.ones(r, c)
        case "diag":
            return try MatrixOps.diag(try requireArg(args, name: name))
        case "flatten":
            return MathValue.vector(try requireArg(args, name: name).flatValues())
        case "squeeze":
            let flat = try requireArg(args, name: name).flatValues()
            return flat.count == 1 ? flat[0] : MathValue.vector(flat)
        case "reshape":
            let m = try requireArg(args, 0, name: name)
            let sizes = try requireArg(args, 1, name: name).flatValues().map { Int(try $0.asDouble()) }
            return try MatrixOps.reshape(m, sizes: sizes)
        case "size":
            let a = try requireArg(args, name: name)
            switch a {
            case .matrix:
                if a.isVector {
                    return MathValue.vector([.number(Double(a.colCount))])
                } else {
                    return MathValue.vector([.number(Double(a.rowCount)), .number(Double(a.colCount))])
                }
            case .string(let s):
                return MathValue.vector([.number(Double(s.count))])
            default:
                return MathValue.vector([])
            }
        case "count":
            let a = try requireArg(args, name: name)
            switch a {
            case .matrix:
                return .number(Double(a.flatValues().count))
            case .string(let s):
                return .number(Double(s.count))
            default:
                return .number(1.0)
            }
        case "row":
            guard case .matrix(let rows) = try requireArg(args, 0, name: name) else {
                throw MathEvalError("Expected matrix in row()")
            }
            let idx = Int(try requireArg(args, 1, name: name).asDouble()) - 1
            guard idx >= 0 && idx < rows.count else { throw MathEvalError("Row index out of bounds") }
            return MathValue.vector(rows[idx])
        case "column":
            guard case .matrix(let rows) = try requireArg(args, 0, name: name) else {
                throw MathEvalError("Expected matrix in column()")
            }
            let idx = Int(try requireArg(args, 1, name: name).asDouble()) - 1
            let col = try rows.map { row -> [MathValue] in
                guard idx >= 0 && idx < row.count else { throw MathEvalError("Column index out of bounds") }
                return [row[idx]]
            }
            return .matrix(col)
        case "concat":
            guard case .matrix(let aRows) = try requireArg(args, 0, name: name),
                  case .matrix(let bRows) = try requireArg(args, 1, name: name) else {
                throw MathEvalError("concat() requires matrices")
            }
            if aRows.count == bRows.count {
                return .matrix(zip(aRows, bRows).map { $0 + $1 })
            } else {
                return .matrix(aRows + bRows)
            }
        case "sort":
            let flat = try requireArg(args, name: name).flatValues()
            let sorted = try flat.sorted { try $0.asDouble() < $1.asDouble() }
            return MathValue.vector(sorted)
        case "range":
            let start = try requireArg(args, 0, name: name).asDouble()
            let end = try requireArg(args, 1, name: name).asDouble()
            let step = args.count >= 3 ? try args[2].asDouble() : 1.0
            var list: [MathValue] = []
            var cur = start
            if step > 0 {
                while cur < end - 1e-12 {
                    list.append(.number(cur))
                    cur += step
                }
            } else if step < 0 {
                while cur > end + 1e-12 {
                    list.append(.number(cur))
                    cur += step
                }
            }
            return MathValue.vector(list)
        case "map":
            let m = try requireArg(args, 0, name: name)
            let fn = try requireArg(args, 1, name: name)
            return try MatrixOps.mapElementWise(m) { try evaluator(fn, [$0]) }
        case "filter":
            let m = try requireArg(args, 0, name: name)
            let fn = try requireArg(args, 1, name: name)
            let filtered = try m.flatValues().filter { try evaluator(fn, [$0]).asBoolean() }
            return MathValue.vector(filtered)
        case "forEach":
            let m = try requireArg(args, 0, name: name)
            let fn = try requireArg(args, 1, name: name)
            let mapped = try m.flatValues().map { try evaluator(fn, [$0]) }
            return MathValue.vector(mapped)
        case "index":
            if args.count == 1 { return args[0] }
            return .matrix(args.map { [$0] })
        case "subset":
            guard case .matrix(let rows) = try requireArg(args, 0, name: name) else {
                throw MathEvalError("Expected matrix in subset()")
            }
            let m = args[0]
            let idxArg = try requireArg(args, 1, name: name)
            if case .matrix(let idxRows) = idxArg, !idxArg.isVector && idxRows.count == 2 {
                let rIdx = Int(try idxRows[0][0].asDouble()) - 1
                let cIdx = Int(try idxRows[1][0].asDouble()) - 1
                return rows[rIdx][cIdx]
            } else if case .matrix = idxArg {
                let flat = m.flatValues()
                let picked = try idxArg.flatValues().map { flat[Int(try $0.asDouble()) - 1] }
                return MathValue.vector(picked)
            } else {
                let flat = m.flatValues()
                return flat[Int(try idxArg.asDouble()) - 1]
            }
        case "matrixFromFunction":
            let dims = try requireArg(args, 0, name: name).flatValues().map { Int(try $0.asDouble()) }
            let fn = try requireArg(args, 1, name: name)
            let rows = dims.first ?? 1
            let cols = dims.count >= 2 ? dims[1] : 1
            var out: [[MathValue]] = []
            for r in 0..<rows {
                var row: [MathValue] = []
                for c in 0..<cols {
                    let idxVec = MathValue.vector([.number(Double(r + 1)), .number(Double(c + 1))])
                    row.append(try evaluator(fn, [idxVec]))
                }
                out.append(row)
            }
            return .matrix(out)
        case "lsolveAll", "usolveAll":
            let sol = try MatrixOps.lusolve(try requireArg(args, 0, name: name), try requireArg(args, 1, name: name))
            return .matrix([sol.flatValues()])
        case "solveODE":
            let fn = try requireArg(args, 0, name: name)
            let span = try requireArg(args, 1, name: name).flatValues().map { try $0.asDouble() }
            let y0 = try requireArg(args, 2, name: name).asDouble()
            let t0 = span[0]
            let tEnd = span[1]
            let steps = 20
            let dt = (tEnd - t0) / Double(steps)
            var t = t0
            var y = y0
            for _ in 0..<steps {
                let k1 = try evaluator(fn, [.number(t), .number(y)]).asDouble()
                let k2 = try evaluator(fn, [.number(t + dt / 2.0), .number(y + dt * k1 / 2.0)]).asDouble()
                let k3 = try evaluator(fn, [.number(t + dt / 2.0), .number(y + dt * k2 / 2.0)]).asDouble()
                let k4 = try evaluator(fn, [.number(t + dt), .number(y + dt * k3)]).asDouble()
                y += (dt / 6.0) * (k1 + 2.0 * k2 + 2.0 * k3 + k4)
                t += dt
            }
            return .object(["t": .number(tEnd), "y": .number(y)], orderedKeys: ["t", "y"])
        case "config":
            return .object([
                "epsilon": .number(1e-12),
                "matrix": .string("Matrix"),
                "number": .string("number"),
                "precision": .number(14.0)
            ], orderedKeys: ["epsilon", "matrix", "number", "precision"])
        case "help":
            if let first = args.first, case .string(let s) = first {
                return .string("Help for \(s)")
            }
            return .string("Help for math")

        case "setUnion":
            let a = try requireArg(args, 0, name: name).flatValues().map { try $0.asDouble() }
            let b = try requireArg(args, 1, name: name).flatValues().map { try $0.asDouble() }
            let u = Array(Set(a + b)).sorted().map { MathValue.number($0) }
            return MathValue.vector(u)
        case "setIntersect":
            let a = Set(try requireArg(args, 0, name: name).flatValues().map { try $0.asDouble() })
            let b = Set(try requireArg(args, 1, name: name).flatValues().map { try $0.asDouble() })
            let inter = a.intersection(b).sorted().map { MathValue.number($0) }
            return MathValue.vector(inter)
        case "setDifference":
            let a = Set(try requireArg(args, 0, name: name).flatValues().map { try $0.asDouble() })
            let b = Set(try requireArg(args, 1, name: name).flatValues().map { try $0.asDouble() })
            let diff = a.subtracting(b).sorted().map { MathValue.number($0) }
            return MathValue.vector(diff)
        case "setSymDifference":
            let a = Set(try requireArg(args, 0, name: name).flatValues().map { try $0.asDouble() })
            let b = Set(try requireArg(args, 1, name: name).flatValues().map { try $0.asDouble() })
            let sym = a.symmetricDifference(b).sorted().map { MathValue.number($0) }
            return MathValue.vector(sym)
        case "setDistinct":
            let a = try requireArg(args, 0, name: name).flatValues().map { try $0.asDouble() }
            let dist = Array(Set(a)).sorted().map { MathValue.number($0) }
            return MathValue.vector(dist)
        case "setIsSubset":
            let a = Set(try requireArg(args, 0, name: name).flatValues().map { try $0.asDouble() })
            let b = Set(try requireArg(args, 1, name: name).flatValues().map { try $0.asDouble() })
            return .bool(a.isSubset(of: b))

        case "distance":
            let a = try requireArg(args, 0, name: name).flatValues().map { try $0.asDouble() }
            let b = try requireArg(args, 1, name: name).flatValues().map { try $0.asDouble() }
            guard a.count == b.count else { throw MathEvalError("distance() points must have same dimensions") }
            let sumSq = zip(a, b).reduce(0.0) { $0 + pow($1.0 - $1.1, 2.0) }
            return .number(sqrt(sumSq))

        case "bitAnd":
            return .number(Double(Int64(try requireArg(args, 0, name: name).asDouble()) & Int64(try requireArg(args, 1, name: name).asDouble())))
        case "bitOr":
            return .number(Double(Int64(try requireArg(args, 0, name: name).asDouble()) | Int64(try requireArg(args, 1, name: name).asDouble())))
        case "bitXor":
            return .number(Double(Int64(try requireArg(args, 0, name: name).asDouble()) ^ Int64(try requireArg(args, 1, name: name).asDouble())))
        case "bitNot":
            return .number(Double(~Int64(try requireArg(args, 0, name: name).asDouble())))
        case "leftShift":
            return .number(Double(Int64(try requireArg(args, 0, name: name).asDouble()) << Int(try requireArg(args, 1, name: name).asDouble())))
        case "rightArithShift":
            return .number(Double(Int64(try requireArg(args, 0, name: name).asDouble()) >> Int(try requireArg(args, 1, name: name).asDouble())))
        case "rightLogShift":
            let v = UInt32(bitPattern: Int32(truncatingIfNeeded: Int64(try requireArg(args, 0, name: name).asDouble())))
            let s = UInt32(Int(try requireArg(args, 1, name: name).asDouble()))
            return .number(Double(v >> s))

        case "hex":
            return .string("0x" + String(Int64(try requireArg(args, name: name).asDouble()), radix: 16))
        case "bin":
            return .string("0b" + String(Int64(try requireArg(args, name: name).asDouble()), radix: 2))
        case "oct":
            return .string("0o" + String(Int64(try requireArg(args, name: name).asDouble()), radix: 8))
        case "format", "string":
            return .string(try requireArg(args, name: name).format())
        case "number":
            let a = try requireArg(args, name: name)
            if case .unit(let val, let u) = a {
                if args.count >= 2, case .string(let targetStr) = args[1] {
                    guard let target = UnitRegistry.resolve(targetStr) else {
                        throw MathEvalError("Unknown unit \(targetStr)")
                    }
                    return .number(try u.convertTo(val, target: target))
                }
                return .number(val)
            }
            return .number(try a.asDouble())
        case "boolean":
            return .bool(try requireArg(args, name: name).asBoolean())
        case "typeOf":
            return .string(try requireArg(args, name: name).typeName())
        case "unit":
            if args.count == 1, case .string(let uStr) = args[0] {
                guard let u = UnitRegistry.resolve(uStr) else {
                    throw MathEvalError("Unknown unit \(uStr)")
                }
                return .unit(value: 1.0, unit: u)
            } else {
                let v = try requireArg(args, 0, name: name).asDouble()
                guard case .string(let uName) = try requireArg(args, 1, name: name),
                      let u = UnitRegistry.resolve(uName) else {
                    throw MathEvalError("Unknown unit")
                }
                return .unit(value: v, unit: u)
            }
        case "to":
            guard case .unit(let val, let u) = try requireArg(args, 0, name: name) else {
                throw MathEvalError("First argument of to() must be a Unit")
            }
            let second = try requireArg(args, 1, name: name)
            let target: MathUnit
            switch second {
            case .unit(_, let tu):
                target = tu
            case .string(let s):
                guard let resolved = UnitRegistry.resolve(s) else {
                    throw MathEvalError("Unknown unit \(s)")
                }
                target = resolved
            default:
                throw MathEvalError("Invalid target unit")
            }
            return .unit(value: try u.convertTo(val, target: target), unit: target)

        default:
            throw MathEvalError("Unknown function: \(name)()")
        }
    }

    public static let builtinFunctions: Set<String> = [
        "abs", "add", "subtract", "multiply", "divide", "mod", "pow",
        "dotMultiply", "dotDivide", "dotPow",
        "round", "floor", "ceil", "fix", "sign", "cbrt", "cube", "square", "sqrt", "nthRoot", "hypot", "norm",
        "exp", "expm1", "log", "ln", "log10", "log2", "log1p",
        "gcd", "lcm", "xgcd", "isPrime", "isInteger", "isPositive", "isNegative", "isZero", "isNaN", "isNumeric",
        "sin", "cos", "tan", "asin", "acos", "atan", "atan2",
        "sinh", "cosh", "tanh", "asinh", "acosh", "atanh",
        "sec", "csc", "cot", "asec", "acsc", "acot", "sech", "csch", "coth", "asech", "acsch", "acoth",
        "deg", "rad", "complex", "re", "im", "conj", "arg",
        "sum", "prod", "mean", "avg", "median", "min", "max", "variance", "std", "mad", "mode", "cumsum", "diff", "corr", "quantileSeq",
        "factorial", "gamma", "lgamma", "erf", "combinations", "combinationsWithRep", "permutations", "catalan", "stirlingS2", "bellNumbers",
        "random", "randomInt", "pickRandom",
        "matrix", "det", "inv", "transpose", "ctranspose", "trace", "lusolve", "lsolve", "usolve", "dot", "cross", "kron",
        "identity", "eye", "zeros", "ones", "diag", "flatten", "squeeze", "reshape", "size", "count", "row", "column", "concat", "sort", "range", "map", "filter", "forEach", "index", "subset", "matrixFromFunction", "lsolveAll", "usolveAll", "solveODE", "config", "help",
        "setUnion", "setIntersect", "setDifference", "setSymDifference", "setDistinct", "setIsSubset",
        "distance",
        "bitAnd", "bitOr", "bitXor", "bitNot", "leftShift", "rightArithShift", "rightLogShift",
        "hex", "bin", "oct", "format", "string", "number", "boolean", "typeOf", "unit", "to"
    ]
}
