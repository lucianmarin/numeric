import SwiftUI
import AppKit

public struct CalculatorView: View {
    @ObservedObject var viewModel: CalculatorViewModel
    @Environment(\.colorScheme) private var systemColorScheme

    public init(viewModel: CalculatorViewModel) {
        self.viewModel = viewModel
    }

    private var isDark: Bool {
        switch viewModel.themeMode {
        case .system: return systemColorScheme == .dark
        case .dark: return true
        case .light: return false
        }
    }

    private var colors: AppColors {
        isDark ? .dark : .light
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                LinesEditorList(viewModel: viewModel, colors: colors)

                Divider()
                    .overlay(colors.border)

                BottomStatusBar(viewModel: viewModel, colors: colors)
            }
            .background(colors.bgMain.ignoresSafeArea())
            .background(TransparentTitleBarConfigurator(bgColor: NSColor(colors.bgMain)))

            if let toast = viewModel.toastMessage {
                Text(toast)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(colors.textMain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(colors.bgElevated)
                            .shadow(color: .black.opacity(0.2), radius: 8, y: 3)
                    )
                    .overlay(
                        Capsule()
                            .stroke(colors.border, lineWidth: 1)
                    )
                    .padding(.bottom, 42)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.16), value: viewModel.toastMessage)
        .preferredColorScheme(preferredScheme)
        .sheet(isPresented: $viewModel.isReferenceOpen) {
            SyntaxReferenceSheet(viewModel: viewModel, colors: colors)
        }
    }

    private var preferredScheme: ColorScheme? {
        switch viewModel.themeMode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

private struct StatusBarTextButton: View {
    let title: String
    let helpText: String
    var disabled: Bool = false
    let colors: AppColors
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(disabled ? colors.textFaint.opacity(0.45) : colors.textFaint)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .help(helpText)
    }
}

private struct LinesEditorList: View {
    @ObservedObject var viewModel: CalculatorViewModel
    let colors: AppColors

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(viewModel.lines.enumerated()), id: \.offset) { index, lineText in
                    let evalLine = index < viewModel.evaluation.lines.count
                        ? viewModel.evaluation.lines[index]
                        : LineEvaluation(lineNumber: index + 1, rawLine: lineText)

                    FormulaResultRow(
                        index: index,
                        text: lineText,
                        evalLine: evalLine,
                        isFocused: viewModel.focusedLineIndex == index,
                        colors: colors,
                        onTextChange: { newText in
                            viewModel.updateLine(at: index, to: newText)
                        },
                        onFocus: {
                            viewModel.focusedLineIndex = index
                        },
                        onReturn: {
                            viewModel.insertLineAfter(index)
                        },
                        onBackspaceEmpty: {
                            viewModel.deleteLineIfEmpty(at: index)
                        },
                        onMoveUp: {
                            viewModel.moveFocusUp(from: index)
                        },
                        onMoveDown: {
                            viewModel.moveFocusDown(from: index)
                        },
                        onCopyResult: { res in
                            viewModel.copyToPasteboard(res)
                        }
                    )
                }

                // Clickable bottom area to add or focus the last line
                Color.clear
                    .frame(height: 120)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if let last = viewModel.lines.last, !last.isEmpty {
                            viewModel.insertLineAfter(viewModel.lines.count - 1)
                        } else {
                            viewModel.focusedLineIndex = max(0, viewModel.lines.count - 1)
                        }
                    }
            }
        }
        .background(colors.bgMain)
    }
}

/// Single row with a left `$number` gutter, formula aligned to the left, and result aligned to the right on the same line.
private struct FormulaResultRow: View {
    let index: Int
    let text: String
    let evalLine: LineEvaluation
    let isFocused: Bool
    let colors: AppColors
    let onTextChange: (String) -> Void
    let onFocus: () -> Void
    let onReturn: () -> Void
    let onBackspaceEmpty: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onCopyResult: (String) -> Void

    @State private var isHoveringResult = false

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // Left gutter displaying line variable ($1, $2, ...)
            Text("$\(index + 1)")
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundStyle(colors.textFaint)
                .frame(width: 28, alignment: .trailing)
                .allowsHitTesting(false)

            // Left-aligned formula editor with live syntax highlighting overlay
            ZStack(alignment: .leading) {
                if text.isEmpty && index == 0 {
                    Text("Type a math expression, unit conversion, or variable...")
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundStyle(colors.textFaint)
                        .allowsHitTesting(false)
                }

                Text(SyntaxHighlighter.highlightLine(text, palette: colors.syntaxPalette))
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .lineLimit(1)
                    .allowsHitTesting(false)

                MacLineTextField(
                    text: text,
                    isFocused: isFocused,
                    cursorColor: NSColor(colors.accent),
                    onTextChange: onTextChange,
                    onFocus: onFocus,
                    onReturn: onReturn,
                    onBackspaceEmpty: onBackspaceEmpty,
                    onMoveUp: onMoveUp,
                    onMoveDown: onMoveDown
                )
                .frame(maxWidth: .infinity, minHeight: 20)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Right-aligned result on the same line
            if let result = evalLine.formattedResult {
                Button {
                    onCopyResult(result)
                } label: {
                    HStack(spacing: 4) {
                        Text(result)
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(colors.resultColor)
                            .lineLimit(1)

                        if isHoveringResult {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(colors.textMuted)
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(isHoveringResult ? colors.bgSurface : Color.clear)
                    )
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    isHoveringResult = hovering
                }
                .help("Click to copy \(result)")
            } else if evalLine.isError, isFocused, let err = evalLine.errorMessage {
                Text(err)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(colors.errorColor)
                    .lineLimit(1)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(colors.errorBg)
                    )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 4)
        .background(isFocused ? colors.bgSurface.opacity(0.55) : Color.clear)
    }
}

/// AppKit NSTextField wrapper for seamless single-line editing, Return, Backspace on empty line, and Up/Down arrow navigation.
private struct MacLineTextField: NSViewRepresentable {
    let text: String
    let isFocused: Bool
    let cursorColor: NSColor
    let onTextChange: (String) -> Void
    let onFocus: () -> Void
    let onReturn: () -> Void
    let onBackspaceEmpty: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> CustomNSTextField {
        let tf = CustomNSTextField()
        tf.delegate = context.coordinator
        tf.isBordered = false
        tf.drawsBackground = false
        tf.focusRingType = .none
        tf.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        tf.textColor = .clear // Underlying text is transparent; SyntaxHighlighter renders colored text underneath
        tf.cell?.wraps = false
        tf.cell?.isScrollable = true
        tf.CursorColor = cursorColor
        tf.onFocus = onFocus
        tf.onBackspaceEmpty = onBackspaceEmpty
        tf.stringValue = text
        return tf
    }

    func updateNSView(_ nsView: CustomNSTextField, context: Context) {
        context.coordinator.parent = self
        nsView.CursorColor = cursorColor
        nsView.onFocus = onFocus
        nsView.onBackspaceEmpty = onBackspaceEmpty

        if nsView.stringValue != text {
            nsView.stringValue = text
        }

        if isFocused {
            DispatchQueue.main.async {
                guard let window = nsView.window else { return }
                if window.firstResponder !== nsView.currentEditor() {
                    window.makeFirstResponder(nsView)
                    if let editor = nsView.currentEditor() as? NSTextView {
                        editor.insertionPointColor = cursorColor
                        let len = (nsView.stringValue as NSString).length
                        editor.selectedRange = NSRange(location: len, length: 0)
                    }
                } else if let editor = nsView.currentEditor() as? NSTextView {
                    editor.insertionPointColor = cursorColor
                }
            }
        }
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: MacLineTextField

        init(_ parent: MacLineTextField) {
            self.parent = parent
        }

        func controlTextDidBeginEditing(_ obj: Notification) {
            parent.onFocus()
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let tf = obj.object as? NSTextField else { return }
            parent.onTextChange(tf.stringValue)
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                parent.onReturn()
                return true
            }
            if commandSelector == #selector(NSResponder.moveUp(_:)) {
                parent.onMoveUp()
                return true
            }
            if commandSelector == #selector(NSResponder.moveDown(_:)) {
                parent.onMoveDown()
                return true
            }
            if commandSelector == #selector(NSResponder.deleteBackward(_:)) {
                if control.stringValue.isEmpty {
                    parent.onBackspaceEmpty()
                    return true
                }
            }
            return false
        }
    }
}

final class CustomNSTextField: NSTextField {
    var CursorColor: NSColor = .systemBlue
    var onFocus: (() -> Void)?
    var onBackspaceEmpty: (() -> Void)?

    override func mouseDown(with event: NSEvent) {
        onFocus?()
        super.mouseDown(with: event)
        if let editor = currentEditor() as? NSTextView {
            editor.insertionPointColor = CursorColor
        }
    }

    override func becomeFirstResponder() -> Bool {
        let ok = super.becomeFirstResponder()
        if ok {
            onFocus?()
            if let editor = currentEditor() as? NSTextView {
                editor.insertionPointColor = CursorColor
            }
        }
        return ok
    }
}

/// Basic bottom status bar displaying Syntax Reference, Undo, and Clear on the left, and Sum and Average on the right.
private struct BottomStatusBar: View {
    @ObservedObject var viewModel: CalculatorViewModel
    let colors: AppColors

    private static func formatStatusNumber(_ value: Double) -> String {
        guard value.isFinite else { return MathValue.formatNumber(value) }
        let rounded = (value * 10).rounded() / 10
        let clean = abs(rounded) < 1e-9 ? 0.0 : rounded
        if abs(clean - clean.rounded()) < 1e-9 {
            return String(format: "%.0f", clean)
        }
        return String(format: "%.1f", clean)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Left: Syntax Reference, Undo, and Clear buttons
            HStack(spacing: 14) {
                StatusBarTextButton(
                    title: "SYNTAX",
                    helpText: "Syntax Reference",
                    colors: colors
                ) {
                    viewModel.isReferenceOpen = true
                }

                StatusBarTextButton(
                    title: "UNDO",
                    helpText: "Undo",
                    disabled: !viewModel.canUndo,
                    colors: colors
                ) {
                    viewModel.undo()
                }

                StatusBarTextButton(
                    title: "CLEAR",
                    helpText: "Clear Sheet",
                    colors: colors
                ) {
                    viewModel.clearAll()
                }
            }

            Spacer()

            // Right: Basic Sum and Average status metrics
            HStack(spacing: 14) {
                let sumStr = Self.formatStatusNumber(viewModel.evaluation.sum)
                let avgStr = Self.formatStatusNumber(viewModel.evaluation.average)

                Button {
                    viewModel.copyToPasteboard(sumStr, label: "Sum")
                } label: {
                    HStack(spacing: 4) {
                        Text("SUM")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(colors.textFaint)
                        Text(sumStr)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(colors.textMain)
                    }
                }
                .buttonStyle(.plain)
                .help("Click to copy Sum (\(sumStr))")

                Button {
                    viewModel.copyToPasteboard(avgStr, label: "Average")
                } label: {
                    HStack(spacing: 4) {
                        Text("AVG")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(colors.textFaint)
                        Text(avgStr)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(colors.textMain)
                    }
                }
                .buttonStyle(.plain)
                .help("Click to copy Average (\(avgStr))")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Color.clear)
    }
}

private struct TransparentTitleBarConfigurator: NSViewRepresentable {
    let bgColor: NSColor

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                configure(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = nsView.window {
                configure(window)
            }
        }
    }

    private func configure(_ window: NSWindow) {
        window.titlebarAppearsTransparent = true
        window.titlebarSeparatorStyle = .none
        window.backgroundColor = bgColor
    }
}

private struct SyntaxReferenceSheet: View {
    @ObservedObject var viewModel: CalculatorViewModel
    let colors: AppColors
    @State private var searchQuery = ""
    @State private var selectedCategory = "All"

    private var categoryNames: [String] {
        ["All"] + SyntaxCatalog.categories.map(\.category)
    }

    private var filteredCategories: [SyntaxCategory] {
        let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return SyntaxCatalog.categories
            .filter { selectedCategory == "All" || $0.category == selectedCategory }
            .compactMap { cat in
                if q.isEmpty { return cat }
                let items = cat.items.filter {
                    $0.name.lowercased().contains(q) ||
                    $0.syntax.lowercased().contains(q) ||
                    $0.desc.lowercased().contains(q) ||
                    $0.example.lowercased().contains(q)
                }
                return items.isEmpty ? nil : SyntaxCategory(category: cat.category, items: items)
            }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("MathJS Syntax Reference")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(colors.textMain)
                    Text("Click any example to insert it into your sheet")
                        .font(.system(size: 12))
                        .foregroundStyle(colors.textMuted)
                }
                Spacer()
                Button("Done") {
                    viewModel.isReferenceOpen = false
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding(16)
            .background(colors.bgSurface)

            Divider().overlay(colors.border)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(colors.textMuted)
                TextField("Search functions, constants, units, operators...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(colors.textMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(colors.bgMain)

            Divider().overlay(colors.border)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(categoryNames, id: \.self) { name in
                        let selected = selectedCategory == name
                        Button {
                            selectedCategory = name
                        } label: {
                            Text(name)
                                .font(.system(size: 11, weight: selected ? .semibold : .medium))
                                .foregroundStyle(selected ? .white : colors.textMuted)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(selected ? colors.accent : colors.bgMain)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .background(colors.bgSurface)

            Divider().overlay(colors.border)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(filteredCategories) { cat in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(cat.category.uppercased())
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(colors.accent)

                            ForEach(cat.items) { item in
                                Button {
                                    viewModel.insertExampleLine(item.example)
                                    viewModel.isReferenceOpen = false
                                } label: {
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading, spacing: 3) {
                                            HStack(spacing: 8) {
                                                Text(item.name)
                                                    .font(.system(size: 13, weight: .semibold))
                                                    .foregroundStyle(colors.textMain)
                                                Text(item.syntax)
                                                    .font(.system(size: 11, design: .monospaced))
                                                    .foregroundStyle(colors.accent)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 4)
                                                            .fill(colors.accentSoft.opacity(0.35))
                                                    )
                                            }
                                            Text(item.desc)
                                                .font(.system(size: 12))
                                                .foregroundStyle(colors.textMuted)
                                        }
                                        Spacer()
                                        Text(item.example)
                                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                                            .foregroundStyle(colors.resultColor)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(
                                                RoundedRectangle(cornerRadius: 5)
                                                    .fill(colors.bgSurface)
                                            )
                                    }
                                    .padding(10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(colors.bgElevated)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(colors.border, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(colors.bgMain)
        }
        .frame(width: 680, height: 520)
    }
}
