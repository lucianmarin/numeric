import SwiftUI

public enum ThemeMode: String, CaseIterable, Sendable {
    case system = "SYSTEM"
    case light = "LIGHT"
    case dark = "DARK"
}

public struct AppColors: Sendable {
    public let bgMain: Color
    public let bgSurface: Color
    public let bgElevated: Color
    public let border: Color
    public let borderSubtle: Color
    public let textMain: Color
    public let textMuted: Color
    public let textFaint: Color
    public let accent: Color
    public let accentSoft: Color
    public let resultColor: Color
    public let errorColor: Color
    public let errorBg: Color
    public let syntaxPalette: SyntaxColorPalette

    public static let light = AppColors(
        bgMain: Color(hex: 0xFAFAFC),
        bgSurface: Color(hex: 0xF1F5F9),
        bgElevated: Color(hex: 0xFFFFFF),
        border: Color(hex: 0xE2E8F0),
        borderSubtle: Color(hex: 0xEDF2F7),
        textMain: Color(hex: 0x0F172A),
        textMuted: Color(hex: 0x64748B),
        textFaint: Color(hex: 0x94A3B8),
        accent: Color(hex: 0x2563EB),
        accentSoft: Color(hex: 0xDBEAFE),
        resultColor: Color(hex: 0x059669),
        errorColor: Color(hex: 0xDC2626),
        errorBg: Color(hex: 0xFEF2F2),
        syntaxPalette: SyntaxColorPalette(
            text: Color(hex: 0x0F172A),
            comment: Color(hex: 0x94A3B8),
            number: Color(hex: 0xD97706),
            function: Color(hex: 0x7C3AED),
            constant: Color(hex: 0x0891B2),
            unit: Color(hex: 0x0D9488),
            variable: Color(hex: 0x2563EB),
            op: Color(hex: 0x64748B),
            lineRef: Color(hex: 0xDB2777),
            string: Color(hex: 0x16A34A)
        )
    )

    public static let dark = AppColors(
        bgMain: Color(hex: 0x0B0F17),
        bgSurface: Color(hex: 0x111827),
        bgElevated: Color(hex: 0x1E293B),
        border: Color(hex: 0x1E293B),
        borderSubtle: Color(hex: 0x151E2E),
        textMain: Color(hex: 0xF1F5F9),
        textMuted: Color(hex: 0x94A3B8),
        textFaint: Color(hex: 0x475569),
        accent: Color(hex: 0x3B82F6),
        accentSoft: Color(hex: 0x1E3A8A),
        resultColor: Color(hex: 0x34D399),
        errorColor: Color(hex: 0xF87171),
        errorBg: Color(hex: 0x2D161B),
        syntaxPalette: SyntaxColorPalette(
            text: Color(hex: 0xF1F5F9),
            comment: Color(hex: 0x64748B),
            number: Color(hex: 0xFBBF24),
            function: Color(hex: 0xA78BFA),
            constant: Color(hex: 0x22D3EE),
            unit: Color(hex: 0x2DD4BF),
            variable: Color(hex: 0x60A5FA),
            op: Color(hex: 0x94A3B8),
            lineRef: Color(hex: 0xF472B6),
            string: Color(hex: 0x4ADE80)
        )
    )
}

extension Color {
    public init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
