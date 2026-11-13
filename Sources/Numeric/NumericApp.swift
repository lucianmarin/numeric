import SwiftUI
import AppKit

@main
struct NumericApp: App {
    @StateObject private var viewModel = CalculatorViewModel()

    static func exportIconsetIfRequested() -> Bool {
        let args = CommandLine.arguments
        if let idx = args.firstIndex(of: "--export-iconset"), idx + 1 < args.count {
            let dir = URL(fileURLWithPath: args[idx + 1])
            try? AppIcon.writeIconset(to: dir)
            return true
        }
        return false
    }

    init() {
        if Self.exportIconsetIfRequested() {
            exit(0)
        }
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.applicationIconImage = AppIcon.loadOrRenderImage()
    }

    var body: some Scene {
        WindowGroup("Numeric") {
            CalculatorView(viewModel: viewModel)
                .frame(minWidth: 348, minHeight: 420)
                .onAppear {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
        }
        .defaultSize(width: 760, height: 620)
        .commands {
            CommandGroup(replacing: .undoRedo) {
                Button("Undo") {
                    viewModel.undo()
                }
                .keyboardShortcut("z", modifiers: .command)
                .disabled(!viewModel.canUndo)
            }
            CommandMenu("Calculator") {
                Button("Syntax Reference") {
                    viewModel.isReferenceOpen.toggle()
                }
                .keyboardShortcut("/", modifiers: .command)

                Button("Copy All with Results") {
                    _ = viewModel.copyAllWithResults()
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])

                Divider()

                Button("Load Demo Sheet") {
                    viewModel.loadDemo()
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])

                Button("Clear Sheet") {
                    viewModel.clearAll()
                }
                .keyboardShortcut("k", modifiers: .command)
            }
        }
    }
}
