import SwiftUI
import AppKit

public let defaultDemoContent = """
# Numeric — Native MathJS Calculator for macOS
# Variables, units, matrices, complex numbers & $line references

price = 120
tax_rate = 18%
total = price + (price * tax_rate)

# Reference any line with $1, $2... or ans
discounted = $6 * 0.9

# Physical units & automatic conversions
distance = 42.195 km in miles
speed = 100 km / (1 hour) to m/s
temp = 98.6 degF in degC

# Linear algebra & matrices
A = [1, 2; 3, 4]
det(A)
inv(A)

# Complex numbers & custom functions
z = (3 + 4i) * (1 - 2i)
abs(z)
hyp(a, b) = sqrt(a^2 + b^2)
hyp(5, 12)
"""

@MainActor
public final class CalculatorViewModel: ObservableObject {
    private static let docKey = "numeric_doc_v1"
    private static let themeKey = "numeric_theme_v1"

    @Published public var lines: [String] = []
    @Published public var focusedLineIndex: Int? = 0
    @Published public var evaluation: DocumentEvaluation = MathEngine.evaluateDocument("")
    @Published public var themeMode: ThemeMode = .system
    @Published public var toastMessage: String? = nil
    @Published public var isReferenceOpen: Bool = false

    private var undoStack: [[String]] = []
    private let maxUndoSize = 50
    private var toastTask: Task<Void, Never>?

    public init() {
        let savedDoc = UserDefaults.standard.string(forKey: Self.docKey) ?? defaultDemoContent
        let savedTheme = UserDefaults.standard.string(forKey: Self.themeKey) ?? ThemeMode.system.rawValue
        self.themeMode = ThemeMode(rawValue: savedTheme) ?? .system
        let initialLines = savedDoc.components(separatedBy: "\n")
        self.lines = initialLines.isEmpty ? [""] : initialLines
        recompute(persist: false)
    }

    public var documentText: String {
        lines.joined(separator: "\n")
    }

    public var canUndo: Bool {
        !undoStack.isEmpty
    }

    public func updateLine(at index: Int, to newText: String) {
        guard lines.indices.contains(index) else { return }
        if newText.contains("\n") {
            pushUndoSnapshot()
            let parts = newText.components(separatedBy: "\n")
            lines.replaceSubrange(index...index, with: parts)
            focusedLineIndex = index + parts.count - 1
            recompute()
            return
        }
        if lines[index] != newText {
            pushUndoSnapshot()
            lines[index] = newText
            recompute()
        }
    }

    public func insertLineAfter(_ index: Int) {
        pushUndoSnapshot()
        let insertIdx = min(max(0, index + 1), lines.count)
        lines.insert("", at: insertIdx)
        focusedLineIndex = insertIdx
        recompute()
    }

    public func deleteLineIfEmpty(at index: Int) {
        guard lines.count > 1, lines.indices.contains(index), lines[index].isEmpty else { return }
        pushUndoSnapshot()
        lines.remove(at: index)
        focusedLineIndex = max(0, index - 1)
        recompute()
    }

    public func moveFocusUp(from index: Int) {
        if index > 0 {
            focusedLineIndex = index - 1
        }
    }

    public func moveFocusDown(from index: Int) {
        if index + 1 < lines.count {
            focusedLineIndex = index + 1
        }
    }

    public func insertOrAppendText(_ snippet: String) {
        pushUndoSnapshot()
        if let idx = focusedLineIndex, lines.indices.contains(idx) {
            if lines[idx].trimmingCharacters(in: .whitespaces).isEmpty {
                lines[idx] = snippet
            } else {
                lines[idx] += snippet
            }
        } else {
            lines.append(snippet)
            focusedLineIndex = lines.count - 1
        }
        recompute()
    }

    public func insertExampleLine(_ example: String) {
        pushUndoSnapshot()
        if let idx = focusedLineIndex, lines.indices.contains(idx), lines[idx].trimmingCharacters(in: .whitespaces).isEmpty {
            lines[idx] = example
        } else {
            let targetIdx = (focusedLineIndex ?? (lines.count - 1)) + 1
            let clamped = min(max(0, targetIdx), lines.count)
            lines.insert(example, at: clamped)
            focusedLineIndex = clamped
        }
        recompute()
        showToast("Inserted: \(example)")
    }

    public func clearAll() {
        guard !(lines.count == 1 && lines[0].isEmpty) else { return }
        pushUndoSnapshot()
        lines = [""]
        focusedLineIndex = 0
        recompute()
        showToast("Cleared sheet — Click Undo to restore")
    }

    public func undo() {
        guard let previous = undoStack.popLast() else { return }
        lines = previous.isEmpty ? [""] : previous
        if let f = focusedLineIndex, f >= lines.count {
            focusedLineIndex = lines.count - 1
        }
        recompute()
        showToast("Undid last change")
    }

    public func loadDemo() {
        pushUndoSnapshot()
        lines = defaultDemoContent.components(separatedBy: "\n")
        focusedLineIndex = 0
        recompute()
        showToast("Loaded sample calculations")
    }

    public func cycleTheme() {
        let next: ThemeMode
        switch themeMode {
        case .system: next = .light
        case .light: next = .dark
        case .dark: next = .system
        }
        themeMode = next
        UserDefaults.standard.set(next.rawValue, forKey: Self.themeKey)
    }

    public func copyToPasteboard(_ value: String, label: String? = nil) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
        let msg = label != nil ? "Copied \(label!): \(value)" : "Copied \(value)"
        showToast(msg)
    }

    public func copyAllWithResults() -> String {
        let formatted = evaluation.lines.map { line -> String in
            if let res = line.formattedResult {
                return "\(line.rawLine) = \(res)"
            }
            return line.rawLine
        }.joined(separator: "\n")
        copyToPasteboard(formatted, label: "all lines")
        return formatted
    }

    public func showToast(_ message: String) {
        toastTask?.cancel()
        toastMessage = message
        toastTask = Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if !Task.isCancelled {
                toastMessage = nil
            }
        }
    }

    private func pushUndoSnapshot() {
        if undoStack.last != lines {
            undoStack.append(lines)
            if undoStack.count > maxUndoSize {
                undoStack.removeFirst()
            }
        }
    }

    private func recompute(persist: Bool = true) {
        let text = documentText
        evaluation = MathEngine.evaluateDocument(text)
        if persist {
            UserDefaults.standard.set(text, forKey: Self.docKey)
        }
    }
}
