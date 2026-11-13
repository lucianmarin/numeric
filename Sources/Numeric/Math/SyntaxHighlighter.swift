import SwiftUI

public struct SyntaxColorPalette: Sendable {
    public let text: Color
    public let comment: Color
    public let number: Color
    public let function: Color
    public let constant: Color
    public let unit: Color
    public let variable: Color
    public let op: Color
    public let lineRef: Color
    public let string: Color

    public init(
        text: Color,
        comment: Color,
        number: Color,
        function: Color,
        constant: Color,
        unit: Color,
        variable: Color,
        op: Color,
        lineRef: Color,
        string: Color
    ) {
        self.text = text
        self.comment = comment
        self.number = number
        self.function = function
        self.constant = constant
        self.unit = unit
        self.variable = variable
        self.op = op
        self.lineRef = lineRef
        self.string = string
    }
}

public enum SyntaxHighlighter {
    private static let keywordOps: Set<String> = ["in", "to", "mod", "and", "or", "not", "xor"]

    public static func highlightLine(_ line: String, palette: SyntaxColorPalette) -> AttributedString {
        var result = AttributedString(line)
        result.foregroundColor = palette.text

        let chars = Array(line)
        let n = chars.count
        var i = 0

        func colorRange(_ start: Int, _ end: Int, _ color: Color, italic: Bool = false, bold: Bool = false) {
            guard start >= 0, end <= n, start < end else { return }
            let startIdx = line.index(line.startIndex, offsetBy: start)
            let endIdx = line.index(line.startIndex, offsetBy: end)
            if let attrStart = AttributedString.Index(startIdx, within: result),
               let attrEnd = AttributedString.Index(endIdx, within: result) {
                result[attrStart..<attrEnd].foregroundColor = color
            }
        }

        while i < n {
            let c = chars[i]

            if c.isWhitespace {
                i += 1
                continue
            }

            // Comment (# or //)
            if c == "#" || (c == "/" && i + 1 < n && chars[i + 1] == "/") {
                colorRange(i, n, palette.comment, italic: true)
                break
            }

            // Strings
            if c == "\"" || c == "'" {
                let prevNonSpace = chars[..<i].last { !$0.isWhitespace }
                let isTranspose = (c == "'") && (prevNonSpace != nil) &&
                    (prevNonSpace!.isLetter || prevNonSpace!.isNumber || prevNonSpace == "]" || prevNonSpace == ")")
                if !isTranspose {
                    let quote = c
                    let start = i
                    i += 1
                    while i < n && chars[i] != quote {
                        if chars[i] == "\\" && i + 1 < n { i += 2 } else { i += 1 }
                    }
                    if i < n { i += 1 }
                    colorRange(start, i, palette.string)
                    continue
                }
            }

            // Line ref ($1, $2, ...)
            if c == "$" && i + 1 < n && chars[i + 1].isNumber {
                let start = i
                i += 1
                while i < n && chars[i].isNumber { i += 1 }
                colorRange(start, i, palette.lineRef, bold: true)
                continue
            }

            // Numbers (hex, bin, oct, float, scientific, imaginary)
            if c.isNumber || (c == "." && i + 1 < n && chars[i + 1].isNumber) {
                let start = i
                if c == "0" && i + 1 < n && "xXbBoO".contains(chars[i + 1]) {
                    i += 2
                    while i < n && (chars[i].isHexDigit || chars[i] == "_") {
                        i += 1
                    }
                } else {
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
                    if i < n && chars[i] == "i" && (i + 1 >= n || (!chars[i + 1].isLetter && !chars[i + 1].isNumber)) {
                        i += 1
                    }
                }
                colorRange(start, i, palette.number)
                continue
            }

            // Identifiers
            if c.isLetter || c == "_" || c == "°" || c == "µ" || c == "μ" || c == "Ω" {
                let start = i
                while i < n && (chars[i].isLetter || chars[i].isNumber || chars[i] == "_" || chars[i] == "°" || chars[i] == "µ" || chars[i] == "μ" || chars[i] == "Ω") {
                    i += 1
                }
                let word = String(chars[start..<i])
                var nextNonSpaceIdx = i
                while nextNonSpaceIdx < n && chars[nextNonSpaceIdx] == " " { nextNonSpaceIdx += 1 }
                let isCall = nextNonSpaceIdx < n && chars[nextNonSpaceIdx] == "("

                let color: Color
                if keywordOps.contains(word) {
                    color = palette.op
                } else if isCall || MathFunctions.builtinFunctions.contains(word) {
                    color = palette.function
                } else if MathFunctions.constants[word] != nil || word == "ans" || word == "end" {
                    color = palette.constant
                } else if UnitRegistry.isKnownUnit(word) {
                    color = palette.unit
                } else {
                    color = palette.variable
                }
                colorRange(start, i, color)
                continue
            }

            // Operators
            if "+-*/%^=<>!&|~?:".contains(c) {
                colorRange(i, i + 1, palette.op)
            }
            i += 1
        }

        return result
    }
}
