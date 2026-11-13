# Numeric

A fast, native macOS notepad-style scientific calculator with a built-in MathJS-compatible evaluation engine, physical unit conversions, matrices, complex numbers, and live syntax highlighting.

## Requirements

- **Platform**: macOS 14.0 (Sonoma) or later
- **Toolchain**: Swift 5.9+ (Swift Package Manager)
- **Frameworks**: SwiftUI & AppKit (zero external dependencies)

## Features

### Notepad-Style Live Sheet
- **Multi-line reactive evaluation**: Every line is evaluated in order with live results aligned to the right.
- **Variables & Scope**: Define variables (`price = 120`, `tax_rate = 18%`) and reuse them across subsequent lines.
- **Line References**: Reference any line's result with `$1`, `$2`, etc., or use `ans` for the previous evaluated line.
- **Custom Functions**: Define reusable functions inline (`hyp(a, b) = sqrt(a^2 + b^2)`).
- **Chained Statements & Comments**: Separate multiple statements with `;` or annotate sheets using `#` or `//` comments.
- **Live Syntax Highlighting**: Token-aware highlighting with light, dark, and system themes.
- **Auto-Persistence & Undo**: Automatically saves sheet state locally with multi-step undo (`⌘Z`), one-click result copying, and a built-in interactive syntax reference (`⌘/`).

### Math Engine Capabilities
- **Data Types**: 64-bit floating-point numbers, complex numbers (`a + bi`), physical units, vectors/matrices, booleans, strings, objects, and closures.
- **Operators**:
  - Standard arithmetic (`+`, `-`, `*`, `/`, `^`, `%`, `mod`), implicit multiplication, postfix percentage (`%`), factorial (`!`), and conjugate transpose (`'`).
  - Element-wise array operators (`.*`, `./`, `.^`) and inclusive range generation (`start:end`, `start:step:end`).
  - Comparison (`==`, `!=`, `<`, `>`, `<=`, `>=`), logical (`and`/`&&`, `or`/`||`, `not`/`!`, `xor`), bitwise (`&`, `|`, `^|`, `~`, `<<`, `>>`, `>>>`), and ternary (`? :`) operators.
- **Physical Units & Conversions**:
  - Dimensional analysis across length, area, volume, mass, time, frequency, angle, temperature (affine scales: `K`, `degC`, `degF`, `degR`), electric current, force, energy, power, pressure, speed, electromagnetism, and digital storage.
  - Full SI decimal (`y` to `Y`) and IEC binary (`Ki` to `Yi`) prefix resolution.
  - Convert units with `in` or `to` (e.g., `42.195 km in miles`, `100 km / (1 hour) to m/s`, `98.6 degF in degC`).
- **Matrices & Linear Algebra**:
  - 1D vectors and 2D matrices (`[1, 2; 3, 4]` or `[[1, 2], [3, 4]]`), 1-based indexing, and range slicing with `end`.
  - Built-in operations: `det`, `inv`, `transpose`, `ctranspose`, `trace`, `lusolve`, `dot`, `cross`, `norm`, `kron`, `eye`/`identity`, `zeros`, `ones`, `diag`, `flatten`, `reshape`, `size`, `count`, `row`, `column`, `concat`, `map`, `filter`, `sort`, and `range`.
- **Complex Numbers**:
  - Arithmetic and transcendental functions over $\mathbb{C}$ (`re`, `im`, `abs`, `arg`, `conj`, `sqrt`, `exp`, `log`, trig).
- **Functions & Constants**:
  - **Arithmetic & Number Theory**: `abs`, `sqrt`, `cbrt`, `nthRoot`, `square`, `cube`, `pow`, `hypot`, `exp`, `expm1`, `log`, `ln`, `log10`, `log2`, `log1p`, `round`, `floor`, `ceil`, `fix`, `sign`, `gcd`, `lcm`, `xgcd`, `mod`, `isPrime`, `isInteger`, `isPositive`, `isNegative`, `isZero`.
  - **Trigonometry**: Full trig, inverse trig, reciprocal (`sec`, `csc`, `cot`), and hyperbolic suites accepting radians or angle units (`sin(30 deg)`).
  - **Statistics, Probability & Combinatorics**: `sum`, `prod`, `mean`/`avg`, `median`, `mode`, `min`, `max`, `std`, `variance`, `mad`, `cumsum`, `diff`, `corr`, `quantileSeq`, `combinations`, `combinationsWithRep`, `permutations`, `factorial`, `gamma`, `lgamma`, `erf`, `catalan`, `stirlingS2`, `bellNumbers`, `random`, `randomInt`, `pickRandom`.
  - **Sets, ODEs & Utilities**: `setUnion`, `setIntersect`, `setDifference`, `setSymDifference`, `setDistinct`, `setIsSubset`, `distance`, 4th-order Runge-Kutta `solveODE`, bitwise functions, and base formatters (`hex`, `bin`, `oct`).
  - **Mathematical & CODATA Physical Constants**: `pi`, `tau`, `e`, `phi`, `i`, `speedOfLight`, `gravity`, `atm`, `gravitationConstant`, `planckConstant`, `reducedPlanckConstant`, `elementaryCharge`, `avogadro`, `boltzmann`, `gasConstant`, `stefanBoltzmann`, `faraday`, `coulomb`, `electronMass`, `protonMass`, `neutronMass`, `bohrRadius`, `rydberg`, `fineStructure`.

## Keyboard Shortcuts

| Shortcut | Action |
| :--- | :--- |
| `⌘/` | Toggle Syntax Reference |
| `⇧⌘C` | Copy All Lines with Results |
| `⇧⌘D` | Load Demo Sheet |
| `⌘K` | Clear Sheet |
| `⌘Z` | Undo |
| `Return` | Insert New Line Below |
| `↑` / `↓` | Move Focus Between Lines |

## Project Structure

```text
├── Makefile                        # Build, app bundle packaging, and test tasks
├── Package.swift                   # SwiftPM manifest (macOS 14+)
├── Sources/Numeric/
│   ├── NumericApp.swift            # App entry point, window setup & menu commands
│   ├── AppIcon.swift               # Programmatic app icon renderer & iconset exporter
│   ├── Math/
│   │   ├── MathEngine.swift        # Lexer, parser, AST evaluator & document runner
│   │   ├── MathFunctions.swift     # Built-in mathematical, statistical & utility functions
│   │   ├── MathUnit.swift          # Dimensional analysis & unit conversion registry
│   │   ├── MathValue.swift         # Value types, complex math & precision formatting
│   │   ├── MatrixOps.swift         # Linear algebra & matrix manipulation
│   │   ├── SyntaxCatalog.swift     # Built-in reference catalog
│   │   └── SyntaxHighlighter.swift # Live expression tokenizer & syntax highlighter
│   └── UI/
│       ├── CalculatorView.swift    # Sheet editor, status bar & reference sheet UI
│       ├── CalculatorViewModel.swift # State management, undo stack & persistence
│       └── Theme.swift             # Light/dark color palettes
└── Tests/NumericTests/
    └── MathEngineTests.swift       # Unit test suite for the math engine
```

## Build & Run

Using `make`:

```bash
# Build release binary and package Numeric.app bundle (with generated AppIcon.icns)
make app

# Build and launch Numeric.app
make run

# Run the unit test suite
make test

# Clean build artifacts and Numeric.app
make clean
```

Or directly via Swift Package Manager:

```bash
swift build -c release
swift test
```
