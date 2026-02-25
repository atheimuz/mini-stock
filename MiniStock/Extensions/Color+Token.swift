import SwiftUI

extension Color {
    // MARK: - Background
    static let widgetBackground = Color(hex: 0x1A1A1A)
    static let tileRiseBackground = Color(hex: 0x4A2E10)
    static let tileFallBackground = Color(hex: 0x1A3B2A)
    static let tileFlatBackground = Color(hex: 0x2C2C2E)

    // MARK: - Tile Text
    static let tileRiseText = Color(hex: 0xE8843A)
    static let tileFallText = Color(hex: 0x4CAF82)
    static let tileFlatText = Color(hex: 0x8E8E93)

    // MARK: - Text
    static let textPrimary = Color(hex: 0xE5E5EA)
    static let textSecondary = Color(hex: 0x636366)

    // MARK: - Accent (Popover)
    static let accentRise = Color(hex: 0xE8843A)
    static let accentFall = Color(hex: 0x4CAF82)
    static let accentFlat = Color(hex: 0x8E8E93)

    // MARK: - Border
    static let widgetBorder = Color(hex: 0x3A3A3C)
    static let tileHoverBorder = Color.white.opacity(0.15)

    // MARK: - Toast
    static let toastBackground = Color(hex: 0x3A3A3C)
    static let toastText = Color(hex: 0xE5E5EA)
    static let toastAction = Color(hex: 0xE8843A)

    // MARK: - Indicator
    static let indicatorActive = Color(hex: 0xE8843A)
    static let indicatorError = Color(hex: 0xFF453A)

    // MARK: - Hex Initializer
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
