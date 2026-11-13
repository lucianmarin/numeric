import Foundation

public enum MatrixOps {
    public static func transpose(_ m: MathValue) throws -> MathValue {
        guard case .matrix(let rows) = m else {
            throw MathEvalError("Expected matrix for transpose")
        }
        if rows.isEmpty { return m }
        let rCount = rows.count
        let cCount = rows.first?.count ?? 0
        var out: [[MathValue]] = []
        for c in 0..<cCount {
            var row: [MathValue] = []
            for r in 0..<rCount {
                row.append(rows[r][c])
            }
            out.append(row)
        }
        return .matrix(out)
    }

    public static func ctranspose(_ m: MathValue) throws -> MathValue {
        guard case .matrix(let rows) = m else {
            throw MathEvalError("Expected matrix for conjugate transpose")
        }
        if rows.isEmpty { return m }
        let rCount = rows.count
        let cCount = rows.first?.count ?? 0
        var out: [[MathValue]] = []
        for c in 0..<cCount {
            var row: [MathValue] = []
            for r in 0..<rCount {
                let v = rows[r][c]
                if case .complex(let re, let im) = v {
                    row.append(ComplexOps.conj((re, im)))
                } else {
                    row.append(v)
                }
            }
            out.append(row)
        }
        return .matrix(out)
    }

    public static func mapElementWise(_ m: MathValue, _ op: (MathValue) throws -> MathValue) throws -> MathValue {
        guard case .matrix(let rows) = m else {
            return try op(m)
        }
        let mapped = try rows.map { row in
            try row.map { try op($0) }
        }
        return .matrix(mapped)
    }

    public static func zipElementWise(
        _ a: MathValue,
        _ b: MathValue,
        _ op: (MathValue, MathValue) throws -> MathValue
    ) throws -> MathValue {
        switch (a, b) {
        case (.matrix(let aRows), .matrix(let bRows)):
            let aR = aRows.count
            let aC = aRows.first?.count ?? 0
            let bR = bRows.count
            let bC = bRows.first?.count ?? 0
            guard aR == bR && aC == bC else {
                throw MathEvalError("Matrix dimension mismatch: [\(aR), \(aC)] vs [\(bR), \(bC)]")
            }
            var out: [[MathValue]] = []
            for r in 0..<aR {
                var row: [MathValue] = []
                for c in 0..<aC {
                    row.append(try op(aRows[r][c], bRows[r][c]))
                }
                out.append(row)
            }
            return .matrix(out)
        case (.matrix, _):
            return try mapElementWise(a) { try op($0, b) }
        case (_, .matrix):
            return try mapElementWise(b) { try op(a, $0) }
        default:
            return try op(a, b)
        }
    }

    public static func multiply(
        _ a: MathValue,
        _ b: MathValue,
        addOp: (MathValue, MathValue) throws -> MathValue,
        mulOp: (MathValue, MathValue) throws -> MathValue
    ) throws -> MathValue {
        guard case .matrix(let aRows) = a, case .matrix(let bRows) = b else {
            throw MathEvalError("Expected matrices for matrix multiplication")
        }
        let aR = aRows.count
        let aC = aRows.first?.count ?? 0
        let bR = bRows.count
        let bC = bRows.first?.count ?? 0

        // 1xN * 1xN dot product [1,2,3] * [4,5,6] -> 32
        if aR == 1 && bR == 1 && aC == bC {
            var sum: MathValue = .number(0.0)
            for i in 0..<aC {
                sum = try addOp(sum, try mulOp(aRows[0][i], bRows[0][i]))
            }
            return sum
        }

        // Matrix A (m x n) * vector b (1 x n) treated as column vector (n x 1) -> 1 x m vector
        if bR == 1 && aC == bC && aR > 1 {
            var res: [MathValue] = []
            for r in 0..<aR {
                var sum: MathValue = .number(0.0)
                for k in 0..<aC {
                    sum = try addOp(sum, try mulOp(aRows[r][k], bRows[0][k]))
                }
                res.append(sum)
            }
            return MathValue.vector(res)
        }

        guard aC == bR else {
            throw MathEvalError("Cannot multiply matrices of dimensions [\(aR), \(aC)] and [\(bR), \(bC)]")
        }

        var out: [[MathValue]] = []
        for r in 0..<aR {
            var row: [MathValue] = []
            for c in 0..<bC {
                var sum: MathValue = .number(0.0)
                for k in 0..<aC {
                    sum = try addOp(sum, try mulOp(aRows[r][k], bRows[k][c]))
                }
                row.append(sum)
            }
            out.append(row)
        }
        return .matrix(out)
    }

    public static func det(_ m: MathValue) throws -> Double {
        guard case .matrix(let rows) = m else {
            throw MathEvalError("Expected matrix for det()")
        }
        let n = rows.count
        let cCount = rows.first?.count ?? 0
        guard n == cCount else {
            throw MathEvalError("Matrix must be square to compute determinant")
        }
        if n == 0 { return 1.0 }
        if n == 1 { return try rows[0][0].asDouble() }
        if n == 2 {
            let a00 = try rows[0][0].asDouble()
            let a01 = try rows[0][1].asDouble()
            let a10 = try rows[1][0].asDouble()
            let a11 = try rows[1][1].asDouble()
            return a00 * a11 - a01 * a10
        }

        var a = try m.toDoubleMatrix()
        var d = 1.0
        for i in 0..<n {
            var pivot = i
            for r in (i + 1)..<n {
                if abs(a[r][i]) > abs(a[pivot][i]) {
                    pivot = r
                }
            }
            if abs(a[pivot][i]) < 1e-15 { return 0.0 }
            if pivot != i {
                a.swapAt(i, pivot)
                d = -d
            }
            d *= a[i][i]
            for r in (i + 1)..<n {
                let factor = a[r][i] / a[i][i]
                for c in (i + 1)..<n {
                    a[r][c] -= factor * a[i][c]
                }
            }
        }
        return d
    }

    public static func inv(_ m: MathValue) throws -> MathValue {
        guard case .matrix(let rows) = m else {
            throw MathEvalError("Expected matrix for inv()")
        }
        let n = rows.count
        let cCount = rows.first?.count ?? 0
        guard n == cCount else {
            throw MathEvalError("Matrix must be square to invert")
        }

        var a: [[Double]] = []
        for r in 0..<n {
            var row: [Double] = []
            for c in 0..<(2 * n) {
                if c < n {
                    row.append(try rows[r][c].asDouble())
                } else {
                    row.append((c - n) == r ? 1.0 : 0.0)
                }
            }
            a.append(row)
        }

        for i in 0..<n {
            var pivot = i
            for r in (i + 1)..<n {
                if abs(a[r][i]) > abs(a[pivot][i]) {
                    pivot = r
                }
            }
            if abs(a[pivot][i]) < 1e-14 {
                throw MathEvalError("Cannot invert singular matrix")
            }
            if pivot != i {
                a.swapAt(i, pivot)
            }
            let div = a[i][i]
            for c in 0..<(2 * n) {
                a[i][c] /= div
            }
            for r in 0..<n {
                if r != i {
                    let factor = a[r][i]
                    for c in 0..<(2 * n) {
                        a[r][c] -= factor * a[i][c]
                    }
                }
            }
        }

        var invRows: [[MathValue]] = []
        for r in 0..<n {
            var row: [MathValue] = []
            for c in 0..<n {
                row.append(.number(a[r][c + n]))
            }
            invRows.append(row)
        }
        return .matrix(invRows)
    }

    public static func trace(_ m: MathValue) throws -> Double {
        guard case .matrix(let rows) = m else {
            throw MathEvalError("Expected matrix for trace()")
        }
        let n = rows.count
        let cCount = rows.first?.count ?? 0
        guard n == cCount else {
            throw MathEvalError("Matrix must be square for trace")
        }
        var sum = 0.0
        for i in 0..<n {
            sum += try rows[i][i].asDouble()
        }
        return sum
    }

    public static func lusolve(_ aMat: MathValue, _ bMat: MathValue) throws -> MathValue {
        guard case .matrix(let aRows) = aMat else {
            throw MathEvalError("Expected matrix A in lusolve")
        }
        let n = aRows.count
        guard n == (aRows.first?.count ?? 0) else {
            throw MathEvalError("Matrix A must be square")
        }
        let bVec = try bMat.flatValues().map { try $0.asDouble() }
        guard bVec.count == n else {
            throw MathEvalError("Dimension mismatch in lusolve")
        }

        var aug: [[Double]] = []
        for r in 0..<n {
            var row: [Double] = []
            for c in 0..<n {
                row.append(try aRows[r][c].asDouble())
            }
            row.append(bVec[r])
            aug.append(row)
        }

        for i in 0..<n {
            var pivot = i
            for r in (i + 1)..<n {
                if abs(aug[r][i]) > abs(aug[pivot][i]) {
                    pivot = r
                }
            }
            if abs(aug[pivot][i]) < 1e-14 {
                throw MathEvalError("Linear system is singular")
            }
            if pivot != i {
                aug.swapAt(i, pivot)
            }
            for r in (i + 1)..<n {
                let factor = aug[r][i] / aug[i][i]
                for c in i...n {
                    aug[r][c] -= factor * aug[i][c]
                }
            }
        }

        var x = Array(repeating: 0.0, count: n)
        for i in stride(from: n - 1, through: 0, by: -1) {
            var sum = aug[i][n]
            if i + 1 < n {
                for j in (i + 1)..<n {
                    sum -= aug[i][j] * x[j]
                }
            }
            x[i] = sum / aug[i][i]
        }

        return .matrix(x.map { [.number($0)] })
    }

    public static func eye(_ rows: Int, _ cols: Int? = nil) -> MathValue {
        let cCount = cols ?? rows
        var out: [[MathValue]] = []
        for r in 0..<rows {
            var row: [MathValue] = []
            for c in 0..<cCount {
                row.append(.number(r == c ? 1.0 : 0.0))
            }
            out.append(row)
        }
        return .matrix(out)
    }

    public static func zeros(_ rows: Int, _ cols: Int = 1) -> MathValue {
        if cols == 1 {
            return MathValue.vector(Array(repeating: .number(0.0), count: rows))
        }
        return .matrix(Array(repeating: Array(repeating: .number(0.0), count: cols), count: rows))
    }

    public static func ones(_ rows: Int, _ cols: Int = 1) -> MathValue {
        if cols == 1 {
            return MathValue.vector(Array(repeating: .number(1.0), count: rows))
        }
        return .matrix(Array(repeating: Array(repeating: .number(1.0), count: cols), count: rows))
    }

    public static func diag(_ m: MathValue) throws -> MathValue {
        guard case .matrix(let rows) = m else {
            throw MathEvalError("Expected matrix or vector for diag()")
        }
        if m.isVector {
            let items = rows[0]
            let n = items.count
            var out: [[MathValue]] = []
            for r in 0..<n {
                var row: [MathValue] = []
                for c in 0..<n {
                    row.append(r == c ? items[r] : .number(0.0))
                }
                out.append(row)
            }
            return .matrix(out)
        } else {
            let n = min(m.rowCount, m.colCount)
            let items = (0..<n).map { rows[$0][$0] }
            return MathValue.vector(items)
        }
    }

    public static func dot(_ a: MathValue, _ b: MathValue) throws -> Double {
        let av = try a.flatValues().map { try $0.asDouble() }
        let bv = try b.flatValues().map { try $0.asDouble() }
        guard av.count == bv.count else {
            throw MathEvalError("Vectors must have equal length for dot product")
        }
        return zip(av, bv).reduce(0.0) { $0 + $1.0 * $1.1 }
    }

    public static func cross(_ a: MathValue, _ b: MathValue) throws -> MathValue {
        let av = try a.flatValues().map { try $0.asDouble() }
        let bv = try b.flatValues().map { try $0.asDouble() }
        guard av.count == 3 && bv.count == 3 else {
            throw MathEvalError("cross() requires 3D vectors")
        }
        return MathValue.vector([
            .number(av[1] * bv[2] - av[2] * bv[1]),
            .number(av[2] * bv[0] - av[0] * bv[2]),
            .number(av[0] * bv[1] - av[1] * bv[0])
        ])
    }

    public static func norm(_ m: MathValue) throws -> Double {
        let vals = try m.flatValues().map { try $0.asDouble() }
        return sqrt(vals.reduce(0.0) { $0 + $1 * $1 })
    }

    public static func kron(_ a: MathValue, _ b: MathValue) throws -> MathValue {
        guard case .matrix(let aRows) = a, case .matrix(let bRows) = b else {
            throw MathEvalError("Expected matrices for kron()")
        }
        var out: [[MathValue]] = []
        for ar in aRows {
            for br in bRows {
                var row: [MathValue] = []
                for av in ar {
                    for bv in br {
                        let prod = try av.asDouble() * bv.asDouble()
                        row.append(.number(prod))
                    }
                }
                out.append(row)
            }
        }
        return .matrix(out)
    }

    public static func reshape(_ m: MathValue, sizes: [Int]) throws -> MathValue {
        let flat = m.flatValues()
        if sizes.count == 1 {
            guard sizes[0] == flat.count else {
                throw MathEvalError("Cannot reshape \(flat.count) elements to [\(sizes[0])]")
            }
            return MathValue.vector(flat)
        }
        let r = sizes[0]
        let c = sizes[1]
        guard r * c == flat.count else {
            throw MathEvalError("Cannot reshape \(flat.count) elements to [\(r), \(c)]")
        }
        var out: [[MathValue]] = []
        for rowIdx in 0..<r {
            var row: [MathValue] = []
            for colIdx in 0..<c {
                row.append(flat[rowIdx * c + colIdx])
            }
            out.append(row)
        }
        return .matrix(out)
    }
}
