import Foundation

public struct SyntaxEntry: Identifiable, Equatable, Sendable {
    public var id: String { "\(name)-\(syntax)" }
    public let name: String
    public let syntax: String
    public let desc: String
    public let example: String

    public init(name: String, syntax: String, desc: String, example: String) {
        self.name = name
        self.syntax = syntax
        self.desc = desc
        self.example = example
    }
}

public struct SyntaxCategory: Identifiable, Equatable, Sendable {
    public var id: String { category }
    public let category: String
    public let items: [SyntaxEntry]

    public init(category: String, items: [SyntaxEntry]) {
        self.category = category
        self.items = items
    }
}

public enum SyntaxCatalog {
    public static let categories: [SyntaxCategory] = [
        SyntaxCategory(
            category: "Editor & Variables",
            items: [
                SyntaxEntry(name: "Variable assignment", syntax: "name = expr", desc: "Define a variable in scope for subsequent lines", example: "revenue = 12500"),
                SyntaxEntry(name: "Function definition", syntax: "f(x, y) = expr", desc: "Define a reusable custom function", example: "hyp(a, b) = sqrt(a^2 + b^2); hyp(3, 4)"),
                SyntaxEntry(name: "Line reference", syntax: "$1, $2, ...", desc: "Reference the evaluated result of line N", example: "$1 * 1.15"),
                SyntaxEntry(name: "Previous answer", syntax: "ans", desc: "Reference the result of the previous evaluated line", example: "ans + 100"),
                SyntaxEntry(name: "Chained statements", syntax: "expr1; expr2", desc: "Evaluate multiple statements on one line, returning the last", example: "a = 5; b = 12; sqrt(a^2 + b^2)"),
                SyntaxEntry(name: "Comments", syntax: "# text or // text", desc: "Add notes or section headers ignored by the evaluator", example: "# Monthly Budget")
            ]
        ),
        SyntaxCategory(
            category: "Operators",
            items: [
                SyntaxEntry(name: "Addition", syntax: "x + y", desc: "Add scalars, vectors, matrices, or compatible units", example: "125 + 375"),
                SyntaxEntry(name: "Subtraction", syntax: "x - y", desc: "Subtract scalars, vectors, matrices, or compatible units", example: "500 - 142"),
                SyntaxEntry(name: "Multiplication", syntax: "x * y", desc: "Scalar/matrix multiplication or implicit multiplication", example: "24 * 7"),
                SyntaxEntry(name: "Element-wise multiply", syntax: "x .* y", desc: "Hadamard (element-by-element) matrix multiplication", example: "[1, 2, 3] .* [4, 5, 6]"),
                SyntaxEntry(name: "Division", syntax: "x / y", desc: "Divide numbers or form compound units", example: "100 km / (2 hour)"),
                SyntaxEntry(name: "Element-wise divide", syntax: "x ./ y", desc: "Element-by-element array division", example: "[10, 20, 30] ./ [2, 4, 5]"),
                SyntaxEntry(name: "Exponentiation", syntax: "x ^ y", desc: "Raise x to the power y (right-associative)", example: "2 ^ 10"),
                SyntaxEntry(name: "Element-wise power", syntax: "x .^ y", desc: "Raise each element of x to power y", example: "[2, 3, 4] .^ 2"),
                SyntaxEntry(name: "Modulo", syntax: "x % y  or  x mod y", desc: "Remainder after division", example: "17 mod 5"),
                SyntaxEntry(name: "Percentage", syntax: "x%", desc: "Postfix percentage (divides by 100)", example: "250 * 18%"),
                SyntaxEntry(name: "Factorial", syntax: "n!", desc: "Product of integers 1 to n (or Gamma(n+1))", example: "6!"),
                SyntaxEntry(name: "Transpose", syntax: "A'", desc: "Conjugate transpose of a matrix or vector", example: "[[1, 2], [3, 4]]'"),
                SyntaxEntry(name: "Range operator", syntax: "start:end  or  start:step:end", desc: "Generate a numeric vector over an inclusive range", example: "0:2:10"),
                SyntaxEntry(name: "Unit conversion", syntax: "val in unit  or  val to unit", desc: "Convert a physical quantity to a target unit", example: "100 km/h to mph"),
                SyntaxEntry(name: "Ternary conditional", syntax: "cond ? a : b", desc: "Evaluate to a if cond is true, otherwise b", example: "15 > 10 ? 100 : 0"),
                SyntaxEntry(name: "Comparison", syntax: "==, !=, <, >, <=, >=", desc: "Compare values or compatible units", example: "1 km == 1000 m"),
                SyntaxEntry(name: "Logical", syntax: "and (&&), or (||), not (!), xor", desc: "Boolean logic operators", example: "true and not false"),
                SyntaxEntry(name: "Bitwise", syntax: "&, |, ^|, ~, <<, >>, >>>", desc: "Bitwise integer operations and shifts", example: "1 << 8")
            ]
        ),
        SyntaxCategory(
            category: "Constants",
            items: [
                SyntaxEntry(name: "pi / PI", syntax: "pi", desc: "Archimedes' constant π ≈ 3.14159265358979", example: "2 * pi"),
                SyntaxEntry(name: "tau", syntax: "tau", desc: "Circle constant τ = 2π ≈ 6.28318530717959", example: "tau / 4"),
                SyntaxEntry(name: "e / E", syntax: "e", desc: "Euler's number e ≈ 2.71828182845905", example: "e ^ 2"),
                SyntaxEntry(name: "phi", syntax: "phi", desc: "Golden ratio φ = (1+√5)/2 ≈ 1.61803398874989", example: "phi ^ 2 - phi"),
                SyntaxEntry(name: "i", syntax: "i", desc: "Imaginary unit √(-1)", example: "(2 + 3i) * (1 - i)"),
                SyntaxEntry(name: "LN2 / LN10", syntax: "LN2, LN10", desc: "Natural logarithm of 2 and 10", example: "LN2"),
                SyntaxEntry(name: "LOG2E / LOG10E", syntax: "LOG2E, LOG10E", desc: "Base-2 and base-10 logarithms of e", example: "LOG10E"),
                SyntaxEntry(name: "SQRT2 / SQRT1_2", syntax: "SQRT2, SQRT1_2", desc: "Square root of 2 and 1/2", example: "SQRT2 ^ 2"),
                SyntaxEntry(name: "speedOfLight", syntax: "speedOfLight", desc: "Speed of light in vacuum (299792458 m/s)", example: "speedOfLight in km/s"),
                SyntaxEntry(name: "gravity", syntax: "gravity", desc: "Standard acceleration of gravity (9.80665 m/s²)", example: "75 kg * gravity in N"),
                SyntaxEntry(name: "atm", syntax: "atm", desc: "Standard atmosphere pressure (101325 Pa)", example: "2 atm in psi"),
                SyntaxEntry(name: "gravitationConstant", syntax: "gravitationConstant", desc: "Newtonian constant of gravitation G", example: "gravitationConstant"),
                SyntaxEntry(name: "planckConstant", syntax: "planckConstant", desc: "Planck constant h (6.62607015e-34)", example: "planckConstant"),
                SyntaxEntry(name: "reducedPlanckConstant", syntax: "reducedPlanckConstant", desc: "Reduced Planck constant ħ = h/(2π)", example: "reducedPlanckConstant"),
                SyntaxEntry(name: "elementaryCharge", syntax: "elementaryCharge", desc: "Elementary charge e (1.602176634e-19 C)", example: "elementaryCharge"),
                SyntaxEntry(name: "avogadro", syntax: "avogadro", desc: "Avogadro constant N_A (6.02214076e23)", example: "avogadro"),
                SyntaxEntry(name: "boltzmann", syntax: "boltzmann", desc: "Boltzmann constant k_B (1.380649e-23)", example: "boltzmann * 300"),
                SyntaxEntry(name: "gasConstant", syntax: "gasConstant", desc: "Molar gas constant R (8.314462618)", example: "gasConstant"),
                SyntaxEntry(name: "stefanBoltzmann", syntax: "stefanBoltzmann", desc: "Stefan-Boltzmann constant σ (5.670374419e-8)", example: "stefanBoltzmann"),
                SyntaxEntry(name: "faraday", syntax: "faraday", desc: "Faraday constant F (96485.33212)", example: "faraday"),
                SyntaxEntry(name: "coulomb", syntax: "coulomb", desc: "Coulomb's constant k_e (8.9875517923e9)", example: "coulomb"),
                SyntaxEntry(name: "electronMass / protonMass", syntax: "electronMass, protonMass, neutronMass", desc: "Rest masses of subatomic particles in kg", example: "protonMass / electronMass"),
                SyntaxEntry(name: "bohrRadius / rydberg", syntax: "bohrRadius, rydberg, fineStructure", desc: "Atomic physics CODATA constants", example: "1 / fineStructure")
            ]
        ),
        SyntaxCategory(
            category: "Arithmetic & Number Theory",
            items: [
                SyntaxEntry(name: "abs", syntax: "abs(x)", desc: "Absolute value or complex magnitude", example: "abs(-42)"),
                SyntaxEntry(name: "sqrt / cbrt / nthRoot", syntax: "sqrt(x), cbrt(x), nthRoot(x, n)", desc: "Square root, cube root, and n-th root", example: "nthRoot(243, 5)"),
                SyntaxEntry(name: "square / cube / pow", syntax: "square(x), cube(x), pow(x, y)", desc: "Power helper functions", example: "cube(4)"),
                SyntaxEntry(name: "hypot", syntax: "hypot(a, b, ...)", desc: "Euclidean norm √(a² + b² + ...)", example: "hypot(3, 4, 12)"),
                SyntaxEntry(name: "exp / expm1", syntax: "exp(x), expm1(x)", desc: "Exponential e^x and e^x - 1", example: "exp(1)"),
                SyntaxEntry(name: "log / ln / log10 / log2 / log1p", syntax: "log(x, [base]), log10(x), log2(x)", desc: "Natural, base-b, base-10, and base-2 logarithms", example: "log(1024, 2)"),
                SyntaxEntry(name: "round / floor / ceil / fix", syntax: "round(x, [n]), floor(x), ceil(x), fix(x)", desc: "Rounding to n decimals, floor, ceiling, or toward zero", example: "round(pi, 4)"),
                SyntaxEntry(name: "sign", syntax: "sign(x)", desc: "Sign of a number (-1, 0, or 1)", example: "sign(-15)"),
                SyntaxEntry(name: "gcd / lcm / xgcd", syntax: "gcd(a, b, ...), lcm(a, b, ...), xgcd(a, b)", desc: "Greatest common divisor, least common multiple, extended GCD", example: "lcm(12, 18, 24)"),
                SyntaxEntry(name: "mod", syntax: "mod(x, y)", desc: "Modulus after division", example: "mod(23, 5)"),
                SyntaxEntry(name: "isPrime / isInteger", syntax: "isPrime(n), isInteger(x)", desc: "Primality and integer checks", example: "isPrime(97)"),
                SyntaxEntry(name: "isPositive / isNegative / isZero", syntax: "isPositive(x), isNegative(x), isZero(x)", desc: "Sign predicates", example: "isPositive(3.5)")
            ]
        ),
        SyntaxCategory(
            category: "Trigonometry",
            items: [
                SyntaxEntry(name: "sin / cos / tan", syntax: "sin(x), cos(x), tan(x)", desc: "Trigonometric functions (accepts radians or deg/rad units)", example: "sin(30 deg)"),
                SyntaxEntry(name: "asin / acos / atan / atan2", syntax: "asin(x), acos(x), atan(x), atan2(y, x)", desc: "Inverse trigonometric functions in radians", example: "atan2(1, 1) * 180 / pi"),
                SyntaxEntry(name: "sec / csc / cot", syntax: "sec(x), csc(x), cot(x)", desc: "Reciprocal trigonometric functions", example: "sec(60 deg)"),
                SyntaxEntry(name: "asec / acsc / acot", syntax: "asec(x), acsc(x), acot(x)", desc: "Inverse reciprocal trigonometric functions", example: "acot(1)"),
                SyntaxEntry(name: "sinh / cosh / tanh", syntax: "sinh(x), cosh(x), tanh(x)", desc: "Hyperbolic functions", example: "cosh(0)"),
                SyntaxEntry(name: "asinh / acosh / atanh", syntax: "asinh(x), acosh(x), atanh(x)", desc: "Inverse hyperbolic functions", example: "asinh(1)"),
                SyntaxEntry(name: "sech / csch / coth", syntax: "sech(x), csch(x), coth(x)", desc: "Hyperbolic reciprocal functions", example: "sech(0)"),
                SyntaxEntry(name: "deg / rad", syntax: "deg(radians), rad(degrees)", desc: "Convert numeric radians to degrees or degrees to radians", example: "deg(pi / 3)")
            ]
        ),
        SyntaxCategory(
            category: "Complex Numbers",
            items: [
                SyntaxEntry(name: "Complex literal", syntax: "a + bi  or  complex(re, im)", desc: "Construct a complex number", example: "(3 + 4i) * (1 - 2i)"),
                SyntaxEntry(name: "re / im", syntax: "re(z), im(z)", desc: "Extract the real or imaginary component", example: "re(5 + 12i)"),
                SyntaxEntry(name: "abs / arg", syntax: "abs(z), arg(z)", desc: "Modulus |z| and phase angle arg(z) in radians", example: "abs(3 + 4i)"),
                SyntaxEntry(name: "conj", syntax: "conj(z)", desc: "Complex conjugate a - bi", example: "conj(3 + 4i)"),
                SyntaxEntry(name: "Euler identity", syntax: "exp(i * x), sqrt(-x)", desc: "Complex exponential, roots, and logarithms", example: "sqrt(-16)")
            ]
        ),
        SyntaxCategory(
            category: "Matrices & Linear Algebra",
            items: [
                SyntaxEntry(name: "Matrix literal", syntax: "[a, b; c, d]  or  [[a, b], [c, d]]", desc: "Create a 1D vector or 2D matrix", example: "M = [1, 2; 3, 4]"),
                SyntaxEntry(name: "Indexing & Slicing", syntax: "A[r, c], v[1:end]", desc: "1-based indexing and range slicing with end keyword", example: "[10, 20, 30, 40, 50][2:end-1]"),
                SyntaxEntry(name: "det", syntax: "det(A)", desc: "Determinant of a square matrix", example: "det([1, 2; 3, 4])"),
                SyntaxEntry(name: "inv", syntax: "inv(A)  or  A^-1", desc: "Inverse of a square non-singular matrix", example: "inv([1, 2; 3, 4])"),
                SyntaxEntry(name: "transpose / ctranspose", syntax: "transpose(A), ctranspose(A), A'", desc: "Matrix transpose and conjugate transpose", example: "transpose([1, 2, 3; 4, 5, 6])"),
                SyntaxEntry(name: "trace", syntax: "trace(A)", desc: "Sum of diagonal elements of a square matrix", example: "trace([5, 1; 2, 7])"),
                SyntaxEntry(name: "lusolve", syntax: "lusolve(A, b)", desc: "Solve linear system A·x = b", example: "lusolve([2, 1; 1, 3], [5, 10])"),
                SyntaxEntry(name: "dot / cross", syntax: "dot(u, v), cross(u, v)", desc: "Vector dot product and 3D cross product", example: "cross([1, 0, 0], [0, 1, 0])"),
                SyntaxEntry(name: "norm", syntax: "norm(v)", desc: "Euclidean (Frobenius) norm of a vector or matrix", example: "norm([3, 4])"),
                SyntaxEntry(name: "kron", syntax: "kron(A, B)", desc: "Kronecker tensor product of two matrices", example: "kron([1, 2], [3, 4])"),
                SyntaxEntry(name: "identity / eye / zeros / ones", syntax: "eye(n), zeros(r, c), ones(r, c)", desc: "Construct identity, zero, or ones matrices", example: "eye(3)"),
                SyntaxEntry(name: "diag", syntax: "diag(v)  or  diag(A)", desc: "Create diagonal matrix from vector or extract diagonal", example: "diag([2, 5, 9])"),
                SyntaxEntry(name: "flatten / reshape / size / count", syntax: "flatten(A), reshape(A, [r, c]), size(A), count(A)", desc: "Inspect or reshape matrix dimensions", example: "reshape(1:6, [2, 3])"),
                SyntaxEntry(name: "row / column / concat", syntax: "row(A, i), column(A, j), concat(A, B)", desc: "Extract a 1-based row/column or concatenate matrices", example: "row([1, 2; 3, 4], 2)"),
                SyntaxEntry(name: "map / filter / sort / range", syntax: "map(v, fn), filter(v, fn), sort(v), range(a, b, [step])", desc: "Functional array operations", example: "f(x) = x^2; map(1:5, f)")
            ]
        ),
        SyntaxCategory(
            category: "Statistics & Probability",
            items: [
                SyntaxEntry(name: "sum / prod", syntax: "sum(x, ...), prod(x, ...)", desc: "Sum or product of elements or arguments", example: "sum([12, 18, 25, 45])"),
                SyntaxEntry(name: "mean / avg / median / mode", syntax: "mean(x), median(x), mode(x)", desc: "Central tendency measures", example: "median([10, 2, 38, 23, 38])"),
                SyntaxEntry(name: "min / max", syntax: "min(x, ...), max(x, ...)", desc: "Smallest or largest element", example: "max([4, 19, 7, 2])"),
                SyntaxEntry(name: "std / variance / mad", syntax: "std(x), variance(x), mad(x)", desc: "Sample standard deviation, sample variance, median absolute deviation", example: "std([2, 4, 4, 4, 5, 5, 7, 9])"),
                SyntaxEntry(name: "cumsum / diff", syntax: "cumsum(v), diff(v)", desc: "Cumulative sum and adjacent differences", example: "cumsum([1, 2, 3, 4])"),
                SyntaxEntry(name: "corr", syntax: "corr(x, y)", desc: "Pearson correlation coefficient between two vectors", example: "corr([1, 2, 3, 4], [2, 4, 6, 8])"),
                SyntaxEntry(name: "quantileSeq", syntax: "quantileSeq(v, p)", desc: "Interpolated p-quantile (0 ≤ p ≤ 1) of a dataset", example: "quantileSeq([10, 20, 30, 40, 50], 0.75)"),
                SyntaxEntry(name: "combinations / permutations", syntax: "combinations(n, k), permutations(n, [k])", desc: "Binomial coefficient nCk and k-permutations of n", example: "combinations(10, 3)"),
                SyntaxEntry(name: "combinationsWithRep", syntax: "combinationsWithRep(n, k)", desc: "Combinations of k items from n with repetition", example: "combinationsWithRep(5, 3)"),
                SyntaxEntry(name: "factorial / gamma / lgamma / erf", syntax: "factorial(n), gamma(z), lgamma(z), erf(x)", desc: "Factorial, Gamma function, log-Gamma, and Gauss error function", example: "erf(1)"),
                SyntaxEntry(name: "catalan / stirlingS2 / bellNumbers", syntax: "catalan(n), stirlingS2(n, k), bellNumbers(n)", desc: "Combinatorial sequences", example: "catalan(5)"),
                SyntaxEntry(name: "random / randomInt / pickRandom", syntax: "random([min, max]), randomInt(min, max), pickRandom(v)", desc: "Random numbers and sampling", example: "randomInt(1, 100)")
            ]
        ),
        SyntaxCategory(
            category: "Set, Bitwise & Utility Functions",
            items: [
                SyntaxEntry(name: "setUnion / setIntersect", syntax: "setUnion(a, b), setIntersect(a, b)", desc: "Union and intersection of two vectors as sorted sets", example: "setIntersect([1, 2, 3, 4], [3, 4, 5])"),
                SyntaxEntry(name: "setDifference / setSymDifference", syntax: "setDifference(a, b), setSymDifference(a, b)", desc: "Set difference and symmetric difference", example: "setDifference([1, 2, 3, 4], [2, 4])"),
                SyntaxEntry(name: "setDistinct / setIsSubset", syntax: "setDistinct(a), setIsSubset(a, b)", desc: "Unique sorted elements and subset check", example: "setDistinct([3, 1, 2, 3, 1])"),
                SyntaxEntry(name: "distance", syntax: "distance(p1, p2)", desc: "Euclidean distance between two n-D points", example: "distance([0, 0], [3, 4])"),
                SyntaxEntry(name: "solveODE", syntax: "solveODE(f, [t0, t1], y0)", desc: "Runge-Kutta 4th order ordinary differential equation solver", example: "f(t, y) = y; solveODE(f, [0, 1], 1)"),
                SyntaxEntry(name: "bitAnd / bitOr / bitXor / bitNot", syntax: "bitAnd(a, b), bitOr(a, b), bitXor(a, b), bitNot(a)", desc: "Bitwise integer functions", example: "bitXor(12, 5)"),
                SyntaxEntry(name: "leftShift / rightArithShift / rightLogShift", syntax: "leftShift(a, b), rightArithShift(a, b)", desc: "Bit shift functions", example: "leftShift(1, 10)"),
                SyntaxEntry(name: "hex / bin / oct", syntax: "hex(n), bin(n), oct(n)", desc: "Format integer in hexadecimal, binary, or octal", example: "hex(255)"),
                SyntaxEntry(name: "typeOf / format / number / boolean", syntax: "typeOf(x), format(x), number(x)", desc: "Inspect type or convert values", example: "typeOf(3 + 4i)")
            ]
        ),
        SyntaxCategory(
            category: "Physical Units & Conversions",
            items: [
                SyntaxEntry(name: "Length", syntax: "m, km, cm, mm, um, nm, pm, fm, angstrom, in, ft, yd, mi, nmi, mil, au, ly, pc", desc: "Metric, Imperial, nautical, and astronomical length units", example: "100 m in ft"),
                SyntaxEntry(name: "Area", syntax: "m2, km2, cm2, mm2, sqin, sqft, sqyd, sqmi, acre, hectare", desc: "Square and land area units", example: "2.5 hectare in acre"),
                SyntaxEntry(name: "Volume", syntax: "m3, L (l, litre), mL (ml), cc, cup, pt, qt, gal, floz, tbsp, tsp", desc: "Metric and US customary liquid volume units", example: "1 gal in L"),
                SyntaxEntry(name: "Mass", syntax: "g, kg, mg, ug, t (tonne), lb (lbs), oz, st (stone), ton, grain, carat, amu (Da)", desc: "Metric, avoirdupois, and atomic mass units", example: "180 lb in kg"),
                SyntaxEntry(name: "Time & Frequency", syntax: "s, ms, us, ns, min, h (hr, hour), day, week, month, year, decade, century, Hz, kHz, MHz, GHz, rpm", desc: "Duration and frequency units", example: "1 year in hours"),
                SyntaxEntry(name: "Speed", syntax: "m/s, km/h (kph), mph, fps, knot", desc: "Velocity and speed units", example: "60 mph in km/h"),
                SyntaxEntry(name: "Temperature", syntax: "K, degC (celsius), degF (fahrenheit), degR (rankine)", desc: "Affine temperature scale conversions", example: "98.6 degF in degC"),
                SyntaxEntry(name: "Force & Pressure", syntax: "N, kN, dyn, lbf, kip, Pa, kPa, MPa, GPa, bar, mbar, atm, psi, torr, mmHg", desc: "Mechanical force and pressure units", example: "1 atm in psi"),
                SyntaxEntry(name: "Energy & Power", syntax: "J, kJ, MJ, Wh, kWh, MWh, cal, kcal, eV, keV, MeV, GeV, BTU, erg, W, kW, MW, GW, hp", desc: "Work, thermal, electrical energy, and power units", example: "100 hp in kW"),
                SyntaxEntry(name: "Electricity & Magnetism", syntax: "A, mA, V, kV, ohm, kohm, Mohm, C, F, uF, nF, pF, S, H, Wb, T, G", desc: "SI electromagnetic units", example: "230 V / 10 ohm in A"),
                SyntaxEntry(name: "Angles", syntax: "rad, deg, grad, arcmin, arcsec, cycle (rev, turn)", desc: "Plane angle units (work directly inside trig functions)", example: "cos(60 deg)"),
                SyntaxEntry(name: "Digital Data", syntax: "b (bit), B (byte), kB, MB, GB, TB, PB, KiB, MiB, GiB, TiB, PiB", desc: "SI decimal (1000) and IEC binary (1024) data units", example: "1 GiB in MB"),
                SyntaxEntry(name: "SI & Binary Prefixes", syntax: "y, z, a, f, p, n, u (µ), m, c, d, da, h, k, M, G, T, P, E, Z, Y, Ki, Mi, Gi, Ti, Pi", desc: "All SI and binary prefixes work on any metric base unit", example: "500 mW in W")
            ]
        )
    ]
}
