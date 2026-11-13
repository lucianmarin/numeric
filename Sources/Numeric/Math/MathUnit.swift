import Foundation

public enum UnitDimension: Int, CaseIterable, Comparable, Sendable {
    case length = 0
    case mass
    case time
    case current
    case temperature
    case amount
    case luminousIntensity
    case angle
    case bit

    public static func < (lhs: UnitDimension, rhs: UnitDimension) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public struct MathUnit: Equatable, Sendable {
    public let dimensions: [UnitDimension: Int]
    public let scaleToBase: Double
    public let offsetToBase: Double
    public let displayName: String

    public init(
        dimensions: [UnitDimension: Int],
        scaleToBase: Double,
        offsetToBase: Double = 0.0,
        displayName: String
    ) {
        self.dimensions = dimensions
        self.scaleToBase = scaleToBase
        self.offsetToBase = offsetToBase
        self.displayName = displayName
    }

    public var name: String {
        formatName()
    }

    public func isCompatibleWith(_ other: MathUnit) -> Bool {
        dimensions == other.dimensions
    }

    public func hasSameDimensions(_ other: MathUnit) -> Bool {
        dimensions == other.dimensions
    }

    public func toBase(_ value: Double) -> Double {
        (value + offsetToBase) * scaleToBase
    }

    public func fromBase(_ baseValue: Double) -> Double {
        (baseValue / scaleToBase) - offsetToBase
    }

    public func convertTo(_ value: Double, target: MathUnit) throws -> Double {
        guard isCompatibleWith(target) else {
            throw MathEvalError("Cannot convert between incompatible units: \(formatName()) and \(target.formatName())")
        }
        return target.fromBase(toBase(value))
    }

    public func multiply(_ other: MathUnit) -> MathUnit {
        var merged = dimensions
        for (dim, exp) in other.dimensions {
            let next = (merged[dim] ?? 0) + exp
            if next == 0 {
                merged.removeValue(forKey: dim)
            } else {
                merged[dim] = next
            }
        }
        let combinedName: String
        if displayName.isEmpty {
            combinedName = other.displayName
        } else if other.displayName.isEmpty {
            combinedName = displayName
        } else if displayName == other.displayName {
            combinedName = "\(displayName)^2"
        } else {
            combinedName = "\(displayName)*\(other.displayName)"
        }
        return MathUnit(
            dimensions: merged,
            scaleToBase: scaleToBase * other.scaleToBase,
            offsetToBase: 0.0,
            displayName: combinedName
        )
    }

    public func divide(_ other: MathUnit) -> MathUnit {
        var merged = dimensions
        for (dim, exp) in other.dimensions {
            let next = (merged[dim] ?? 0) - exp
            if next == 0 {
                merged.removeValue(forKey: dim)
            } else {
                merged[dim] = next
            }
        }
        let combinedName: String
        if other.displayName.isEmpty {
            combinedName = displayName
        } else if displayName.isEmpty {
            combinedName = "1/\(other.displayName)"
        } else {
            combinedName = "\(displayName)/\(other.displayName)"
        }
        return MathUnit(
            dimensions: merged,
            scaleToBase: scaleToBase / other.scaleToBase,
            offsetToBase: 0.0,
            displayName: combinedName
        )
    }

    public func powUnit(_ exponent: Int) -> MathUnit {
        pow(exponent)
    }

    public func pow(_ exponent: Int) -> MathUnit {
        if exponent == 0 {
            return MathUnit(dimensions: [:], scaleToBase: 1.0, offsetToBase: 0.0, displayName: "")
        }
        var merged: [UnitDimension: Int] = [:]
        for (dim, exp) in dimensions {
            let v = exp * exponent
            if v != 0 {
                merged[dim] = v
            }
        }
        let name = exponent == 1 ? displayName : "\(displayName)\(exponent)"
        return MathUnit(
            dimensions: merged,
            scaleToBase: Foundation.pow(scaleToBase, Double(exponent)),
            offsetToBase: 0.0,
            displayName: name
        )
    }

    public func formatName() -> String {
        if !displayName.isEmpty {
            return displayName
        }
        return dimensions.keys.sorted().map { d in
            let e = dimensions[d] ?? 1
            let baseSymbol: String
            switch d {
            case .length: baseSymbol = "m"
            case .mass: baseSymbol = "kg"
            case .time: baseSymbol = "s"
            case .current: baseSymbol = "A"
            case .temperature: baseSymbol = "K"
            case .amount: baseSymbol = "mol"
            case .luminousIntensity: baseSymbol = "cd"
            case .angle: baseSymbol = "rad"
            case .bit: baseSymbol = "b"
            }
            return e == 1 ? baseSymbol : "\(baseSymbol)^\(e)"
        }.joined(separator: "*")
    }
}

public enum UnitRegistry {
    private struct BaseUnitDef: Sendable {
        let canonical: String
        let aliases: [String]
        let dimensions: [UnitDimension: Int]
        let scale: Double
        let offset: Double
        let allowSiPrefixes: Bool
        let allowBinaryPrefixes: Bool

        init(
            _ canonical: String,
            _ aliases: [String],
            _ dimensions: [UnitDimension: Int],
            _ scale: Double,
            offset: Double = 0.0,
            allowSiPrefixes: Bool = false,
            allowBinaryPrefixes: Bool = false
        ) {
            self.canonical = canonical
            self.aliases = aliases
            self.dimensions = dimensions
            self.scale = scale
            self.offset = offset
            self.allowSiPrefixes = allowSiPrefixes
            self.allowBinaryPrefixes = allowBinaryPrefixes
        }
    }

    private static let siPrefixes: [(String, Double)] = [
        ("da", 1e1),
        ("Y", 1e24),
        ("Z", 1e21),
        ("E", 1e18),
        ("P", 1e15),
        ("T", 1e12),
        ("G", 1e9),
        ("M", 1e6),
        ("k", 1e3),
        ("h", 1e2),
        ("d", 1e-1),
        ("c", 1e-2),
        ("m", 1e-3),
        ("u", 1e-6),
        ("µ", 1e-6),
        ("n", 1e-9),
        ("p", 1e-12),
        ("f", 1e-15),
        ("a", 1e-18),
        ("z", 1e-21),
        ("y", 1e-24)
    ]

    private static let binaryPrefixes: [(String, Double)] = [
        ("Yi", pow(2.0, 80.0)),
        ("Zi", pow(2.0, 70.0)),
        ("Ei", pow(2.0, 60.0)),
        ("Pi", pow(2.0, 50.0)),
        ("Ti", pow(2.0, 40.0)),
        ("Gi", pow(2.0, 30.0)),
        ("Mi", pow(2.0, 20.0)),
        ("Ki", pow(2.0, 10.0))
    ]

    private static let defs: [BaseUnitDef] = [
        // Length (base: m)
        BaseUnitDef("m", ["meter", "meters", "metre", "metres"], [.length: 1], 1.0, allowSiPrefixes: true),
        BaseUnitDef("in", ["inch", "inches"], [.length: 1], 0.0254),
        BaseUnitDef("ft", ["foot", "feet"], [.length: 1], 0.3048),
        BaseUnitDef("yd", ["yard", "yards"], [.length: 1], 0.9144),
        BaseUnitDef("mi", ["mile", "miles"], [.length: 1], 1609.344),
        BaseUnitDef("nmi", ["nauticalmile"], [.length: 1], 1852.0),
        BaseUnitDef("angstrom", ["angstroms"], [.length: 1], 1e-10),
        BaseUnitDef("au", ["AU"], [.length: 1], 149597870700.0),
        BaseUnitDef("ly", ["lightyear", "lightyears"], [.length: 1], 9.4607304725808e15),

        // Area (base: m^2)
        BaseUnitDef("m2", ["sqm"], [.length: 2], 1.0),
        BaseUnitDef("cm2", ["sqcm"], [.length: 2], 1e-4),
        BaseUnitDef("mm2", ["sqmm"], [.length: 2], 1e-6),
        BaseUnitDef("km2", ["sqkm"], [.length: 2], 1e6),
        BaseUnitDef("sqft", ["ft2"], [.length: 2], 0.09290304),
        BaseUnitDef("sqin", ["in2"], [.length: 2], 0.00064516),
        BaseUnitDef("sqyd", ["yd2"], [.length: 2], 0.83612736),
        BaseUnitDef("sqmi", ["mi2"], [.length: 2], 2589988.110336),
        BaseUnitDef("acre", ["acres"], [.length: 2], 4046.8564224),
        BaseUnitDef("hectare", ["hectares", "ha"], [.length: 2], 10000.0),

        // Volume (base: m^3)
        BaseUnitDef("m3", ["cum"], [.length: 3], 1.0),
        BaseUnitDef("cm3", ["cc", "cucm"], [.length: 3], 1e-6),
        BaseUnitDef("mm3", ["cumm"], [.length: 3], 1e-9),
        BaseUnitDef("L", ["l", "liter", "liters", "litre", "litres"], [.length: 3], 1e-3, allowSiPrefixes: true),
        BaseUnitDef("gal", ["gallon", "gallons"], [.length: 3], 0.003785411784),
        BaseUnitDef("qt", ["quart", "quarts"], [.length: 3], 0.000946352946),
        BaseUnitDef("pt", ["pint", "pints"], [.length: 3], 0.000473176473),
        BaseUnitDef("cup", ["cups"], [.length: 3], 0.0002365882365),
        BaseUnitDef("floz", ["fluidounce", "fluidounces"], [.length: 3], 2.95735295625e-5),
        BaseUnitDef("tbsp", ["tablespoon", "tablespoons"], [.length: 3], 1.478676478125e-5),
        BaseUnitDef("tsp", ["teaspoon", "teaspoons"], [.length: 3], 4.92892159375e-6),

        // Mass (base: kg)
        BaseUnitDef("g", ["gram", "grams"], [.mass: 1], 1e-3, allowSiPrefixes: true),
        BaseUnitDef("kg", ["kilogram", "kilograms"], [.mass: 1], 1.0),
        BaseUnitDef("mg", ["milligram", "milligrams"], [.mass: 1], 1e-6),
        BaseUnitDef("ug", ["microgram", "micrograms"], [.mass: 1], 1e-9),
        BaseUnitDef("tonne", ["tonnes", "t", "metricton"], [.mass: 1], 1000.0),
        BaseUnitDef("lb", ["lbs", "lbm", "pound", "pounds"], [.mass: 1], 0.45359237),
        BaseUnitDef("oz", ["ounce", "ounces"], [.mass: 1], 0.028349523125),
        BaseUnitDef("stone", ["stones"], [.mass: 1], 6.35029318),
        BaseUnitDef("ton", ["tons"], [.mass: 1], 907.18474),

        // Time (base: s)
        BaseUnitDef("s", ["sec", "secs", "second", "seconds"], [.time: 1], 1.0, allowSiPrefixes: true),
        BaseUnitDef("min", ["mins", "minute", "minutes"], [.time: 1], 60.0),
        BaseUnitDef("h", ["hr", "hrs", "hour", "hours"], [.time: 1], 3600.0),
        BaseUnitDef("day", ["days", "d"], [.time: 1], 86400.0),
        BaseUnitDef("week", ["weeks", "wk"], [.time: 1], 604800.0),
        BaseUnitDef("month", ["months"], [.time: 1], 2629800.0),
        BaseUnitDef("year", ["years", "yr", "yrs"], [.time: 1], 31557600.0),

        // Frequency (base: s^-1)
        BaseUnitDef("Hz", ["hertz"], [.time: -1], 1.0, allowSiPrefixes: true),

        // Angle (base: rad)
        BaseUnitDef("rad", ["radian", "radians"], [.angle: 1], 1.0, allowSiPrefixes: true),
        BaseUnitDef("deg", ["degree", "degrees"], [.angle: 1], Double.pi / 180.0),
        BaseUnitDef("grad", ["gradian", "gradians"], [.angle: 1], Double.pi / 200.0),
        BaseUnitDef("arcmin", ["arcminute", "arcminutes"], [.angle: 1], Double.pi / 10800.0),
        BaseUnitDef("arcsec", ["arcsecond", "arcseconds"], [.angle: 1], Double.pi / 648000.0),

        // Temperature (base: K)
        BaseUnitDef("K", ["kelvin", "kelvins"], [.temperature: 1], 1.0, allowSiPrefixes: true),
        BaseUnitDef("degC", ["celsius"], [.temperature: 1], 1.0, offset: 273.15),
        BaseUnitDef("degF", ["fahrenheit"], [.temperature: 1], 5.0 / 9.0, offset: 459.67),
        BaseUnitDef("degR", ["rankine"], [.temperature: 1], 5.0 / 9.0),

        // Electric current (base: A)
        BaseUnitDef("A", ["amp", "amps", "ampere", "amperes"], [.current: 1], 1.0, allowSiPrefixes: true),

        // Substance & luminous intensity
        BaseUnitDef("mol", ["mole", "moles"], [.amount: 1], 1.0, allowSiPrefixes: true),
        BaseUnitDef("cd", ["candela"], [.luminousIntensity: 1], 1.0, allowSiPrefixes: true),

        // Force (base: kg*m/s^2)
        BaseUnitDef("N", ["newton", "newtons"], [.mass: 1, .length: 1, .time: -2], 1.0, allowSiPrefixes: true),
        BaseUnitDef("dyn", ["dyne"], [.mass: 1, .length: 1, .time: -2], 1e-5),
        BaseUnitDef("lbf", ["poundforce"], [.mass: 1, .length: 1, .time: -2], 4.4482216152605),
        BaseUnitDef("kip", ["kips"], [.mass: 1, .length: 1, .time: -2], 4448.2216152605),

        // Energy (base: kg*m^2/s^2)
        BaseUnitDef("J", ["joule", "joules"], [.mass: 1, .length: 2, .time: -2], 1.0, allowSiPrefixes: true),
        BaseUnitDef("Wh", [], [.mass: 1, .length: 2, .time: -2], 3600.0, allowSiPrefixes: true),
        BaseUnitDef("kWh", [], [.mass: 1, .length: 2, .time: -2], 3.6e6),
        BaseUnitDef("cal", ["calorie", "calories"], [.mass: 1, .length: 2, .time: -2], 4.184, allowSiPrefixes: true),
        BaseUnitDef("kcal", ["Cal"], [.mass: 1, .length: 2, .time: -2], 4184.0),
        BaseUnitDef("BTU", ["btu"], [.mass: 1, .length: 2, .time: -2], 1055.05585262),
        BaseUnitDef("eV", ["electronvolt", "electronvolts"], [.mass: 1, .length: 2, .time: -2], 1.602176634e-19, allowSiPrefixes: true),
        BaseUnitDef("erg", [], [.mass: 1, .length: 2, .time: -2], 1e-7),

        // Power (base: kg*m^2/s^3)
        BaseUnitDef("W", ["watt", "watts"], [.mass: 1, .length: 2, .time: -3], 1.0, allowSiPrefixes: true),
        BaseUnitDef("hp", ["horsepower"], [.mass: 1, .length: 2, .time: -3], 745.6998715822702),

        // Pressure (base: kg/(m*s^2))
        BaseUnitDef("Pa", ["pascal", "pascals"], [.mass: 1, .length: -1, .time: -2], 1.0, allowSiPrefixes: true),
        BaseUnitDef("bar", ["bars"], [.mass: 1, .length: -1, .time: -2], 1e5, allowSiPrefixes: true),
        BaseUnitDef("atm", ["atmosphere", "atmospheres"], [.mass: 1, .length: -1, .time: -2], 101325.0),
        BaseUnitDef("torr", ["Torr"], [.mass: 1, .length: -1, .time: -2], 101325.0 / 760.0),
        BaseUnitDef("mmHg", [], [.mass: 1, .length: -1, .time: -2], 133.322387415),
        BaseUnitDef("psi", [], [.mass: 1, .length: -1, .time: -2], 6894.757293168361),

        // Speed (base: m/s)
        BaseUnitDef("mph", [], [.length: 1, .time: -1], 0.44704),
        BaseUnitDef("kph", ["kmh"], [.length: 1, .time: -1], 1.0 / 3.6),
        BaseUnitDef("knot", ["knots", "kt", "kts"], [.length: 1, .time: -1], 1852.0 / 3600.0),

        // Electromagnetism
        BaseUnitDef("C", ["coulomb", "coulombs"], [.current: 1, .time: 1], 1.0, allowSiPrefixes: true),
        BaseUnitDef("V", ["volt", "volts"], [.mass: 1, .length: 2, .time: -3, .current: -1], 1.0, allowSiPrefixes: true),
        BaseUnitDef("ohm", ["ohms"], [.mass: 1, .length: 2, .time: -3, .current: -2], 1.0, allowSiPrefixes: true),
        BaseUnitDef("F", ["farad", "farads"], [.mass: -1, .length: -2, .time: 4, .current: 2], 1.0, allowSiPrefixes: true),
        BaseUnitDef("S", ["siemens"], [.mass: -1, .length: -2, .time: 3, .current: 2], 1.0, allowSiPrefixes: true),
        BaseUnitDef("Wb", ["weber", "webers"], [.mass: 1, .length: 2, .time: -2, .current: -1], 1.0, allowSiPrefixes: true),
        BaseUnitDef("T", ["tesla", "teslas"], [.mass: 1, .time: -2, .current: -1], 1.0, allowSiPrefixes: true),
        BaseUnitDef("H", ["henry", "henrys"], [.mass: 1, .length: 2, .time: -2, .current: -2], 1.0, allowSiPrefixes: true),

        // Digital Storage (base: bit)
        BaseUnitDef("b", ["bit", "bits"], [.bit: 1], 1.0, allowSiPrefixes: true, allowBinaryPrefixes: true),
        BaseUnitDef("B", ["byte", "bytes"], [.bit: 1], 8.0, allowSiPrefixes: true, allowBinaryPrefixes: true)
    ]

    private static let exactUnits: [String: MathUnit] = {
        var map: [String: MathUnit] = [:]
        for def in defs {
            map[def.canonical] = MathUnit(dimensions: def.dimensions, scaleToBase: def.scale, offsetToBase: def.offset, displayName: def.canonical)
            for alias in def.aliases {
                map[alias] = MathUnit(dimensions: def.dimensions, scaleToBase: def.scale, offsetToBase: def.offset, displayName: alias)
            }
        }
        return map
    }()

    private static let prefixableUnits: [BaseUnitDef] = defs.filter { $0.allowSiPrefixes || $0.allowBinaryPrefixes }

    public static func resolve(_ token: String) -> MathUnit? {
        if let exact = exactUnits[token] {
            return exact
        }

        // Check power suffix like m^2, s^2, m2, s2
        if let powRange = token.range(of: #"^([a-zA-Zµ]+)\^?(-?\d+)$"#, options: .regularExpression) {
            let full = String(token[powRange])
            // Extract base and exponent
            var idx = full.endIndex
            while idx > full.startIndex {
                let prev = full.index(before: idx)
                let ch = full[prev]
                if ch.isNumber || ch == "-" {
                    idx = prev
                } else {
                    break
                }
            }
            var basePart = String(full[..<idx])
            if basePart.hasSuffix("^") {
                basePart.removeLast()
            }
            let expPart = String(full[idx...])
            if let exp = Int(expPart), let baseUnit = resolveSimpleOrPrefixed(basePart) {
                return baseUnit.pow(exp)
            }
        }

        return resolveSimpleOrPrefixed(token)
    }

    private static func resolveSimpleOrPrefixed(_ token: String) -> MathUnit? {
        if let exact = exactUnits[token] {
            return exact
        }

        for def in prefixableUnits {
            let namesToTry = [def.canonical] + def.aliases
            if def.allowBinaryPrefixes {
                for (prefix, factor) in binaryPrefixes {
                    for uName in namesToTry {
                        if token == "\(prefix)\(uName)" {
                            return MathUnit(dimensions: def.dimensions, scaleToBase: def.scale * factor, offsetToBase: 0.0, displayName: token)
                        }
                    }
                }
            }
            if def.allowSiPrefixes {
                for (prefix, factor) in siPrefixes {
                    for uName in namesToTry {
                        if token == "\(prefix)\(uName)" {
                            return MathUnit(dimensions: def.dimensions, scaleToBase: def.scale * factor, offsetToBase: 0.0, displayName: token)
                        }
                    }
                }
            }
        }
        return nil
    }

    public static func isKnownUnit(_ token: String) -> Bool {
        resolve(token) != nil
    }
}
