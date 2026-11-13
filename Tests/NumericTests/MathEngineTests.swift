import XCTest
@testable import Numeric

final class MathEngineTests: XCTestCase {
    private func eval(_ expr: String) throws -> String {
        try MathEngine.evaluateExpression(expr).format()
    }

    func testBasicArithmeticAndImplicitMultiplication() throws {
        XCTAssertEqual(try eval("2 + 3 * 4"), "14")
        XCTAssertEqual(try eval("2^10"), "1024")
        XCTAssertEqual(try eval("5!"), "120")
        XCTAssertEqual(try eval("200 * 15%"), "30")
        XCTAssertEqual(try eval("2 pi"), MathValue.formatNumber(2 * .pi))
    }

    func testComplexNumbers() throws {
        XCTAssertEqual(try eval("(2 + 3i) * (4 - 5i)"), "23 + 2i")
        XCTAssertEqual(try eval("sqrt(-4)"), "2i")
        XCTAssertEqual(try eval("abs(3 + 4i)"), "5")
        XCTAssertEqual(try eval("conj(3 + 4i)"), "3 - 4i")
    }

    func testMatricesAndLinearAlgebra() throws {
        XCTAssertEqual(try eval("det([1, 2; 3, 4])"), "-2")
        XCTAssertEqual(try eval("trace([1, 2; 3, 4])"), "5")
        XCTAssertEqual(try eval("dot([1, 2, 3], [4, 5, 6])"), "32")
        XCTAssertEqual(try eval("cross([1, 0, 0], [0, 1, 0])"), "[0, 0, 1]")
        XCTAssertEqual(try eval("[1, 2; 3, 4]'"), "[[1, 3], [2, 4]]")
        XCTAssertEqual(try eval("[10, 20, 30, 40, 50][2:end-1]"), "[20, 30, 40]")
    }

    func testPhysicalUnitsAndConversions() throws {
        XCTAssertEqual(try eval("5 km + 300 m"), "5.3 km")
        XCTAssertEqual(try eval("100 m in ft"), "328.08398950131 ft")
        XCTAssertEqual(try eval("98.6 degF in degC"), "37 degC")
        XCTAssertEqual(try eval("1 GiB in MB"), "1073.741824 MB")
        XCTAssertEqual(try eval("sin(30 deg)"), "0.5")
    }

    func testMultiLineDocumentVariablesFunctionsAndLineReferences() {
        let doc = """
        # Shopping calculation
        price = 120
        tax = 18%
        total = price * (1 + tax)
        $4 * 2
        f(x) = x^2 + 1
        f(5)
        """
        let res = MathEngine.evaluateDocument(doc)
        XCTAssertNil(res.lines[0].formattedResult)
        XCTAssertEqual(res.lines[1].formattedResult, "120")
        XCTAssertEqual(res.lines[2].formattedResult, "0.18")
        XCTAssertEqual(res.lines[3].formattedResult, "141.6")
        XCTAssertEqual(res.lines[4].formattedResult, "283.2")
        XCTAssertNil(res.lines[5].formattedResult)
        XCTAssertEqual(res.lines[6].formattedResult, "26")
        XCTAssertEqual(res.numericCount, 5)
        XCTAssertEqual(res.sum, 120.0 + 0.18 + 141.6 + 283.2 + 26.0, accuracy: 1e-9)
    }

    func testEverySyntaxCatalogExampleEvaluatesWithoutErrors() {
        for category in SyntaxCatalog.categories {
            for entry in category.items {
                let doc = """
                100
                \(entry.example)
                """
                let evaluated = MathEngine.evaluateDocument(doc)
                let exampleLine = evaluated.lines.last!
                XCTAssertFalse(
                    exampleLine.isError,
                    "Catalog example failed in [\(category.category) -> \(entry.name)]: '\(entry.example)' -> \(exampleLine.errorMessage ?? "")"
                )
            }
        }
    }

    @MainActor
    func testUndoTracksLineAdditionsAndDeletionsNotCharacterEdits() {
        let vm = CalculatorViewModel()
        vm.lines = [""]
        vm.updateLine(at: 0, to: "a")
        vm.updateLine(at: 0, to: "ab")
        vm.updateLine(at: 0, to: "abc")
        XCTAssertFalse(vm.canUndo)

        vm.insertLineAfter(0)
        XCTAssertTrue(vm.canUndo)
        XCTAssertEqual(vm.lines, ["abc", ""])

        vm.updateLine(at: 1, to: "123")
        vm.undo()
        XCTAssertEqual(vm.lines, ["abc"])
        XCTAssertFalse(vm.canUndo)
    }
}
