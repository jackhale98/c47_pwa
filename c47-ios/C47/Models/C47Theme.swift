// SPDX-License-Identifier: GPL-3.0-only
// C47Theme.swift
// C47 Calculator for iOS - Authentic C47 Theme Colors

import SwiftUI

/// Authentic C47 calculator theme colors
/// Based on c47_narrow_screen_pre.css for mobile devices
enum C47Theme {
    // MARK: - Primary Colors

    /// Gold color for f-shift key and f-shifted labels
    static let fGold = Color(hex: "E5AE5A")

    /// Hover state for f-shift
    static let fHoverGold = Color(hex: "FFFF00")

    /// Blue color for g-shift key and g-shifted labels
    static let gBlue = Color(hex: "7EB6BA")

    /// Hover state for g-shift
    static let gHoverBlue = Color(hex: "00FFFF")

    /// Alpha key color (coral/orange)
    static let alphaGold = Color(hex: "E36C50")

    /// Alpha hover color
    static let alphaHoverGold = Color(hex: "FF8669")

    /// Combined f+g shift color
    static let fgGold = Color(hex: "F1B053")

    /// Combined f+g hover color
    static let fgHoverGold = Color(hex: "E7D7A0")

    // MARK: - Key Colors

    /// Standard key background
    static let keyBackground = Color(hex: "212121")

    /// Key border color
    static let keyBorder = Color(hex: "25292F")

    /// Key label color (white)
    static let keyLabelColor = Color.white

    /// Key hover/pressed state
    static let keyHover = Color(hex: "744A2E")

    /// Numeric key background (same as key)
    static let numericKeyBackground = Color(hex: "212121")

    /// Numeric key border
    static let numericKeyBorder = Color(hex: "25292F")

    // MARK: - Bezel & Frame Colors

    /// Main bezel background (dark gray/brown for mobile)
    static let bezelBackground = Color(hex: "2B2A29")

    /// Function key area background
    static let funcKeyBackground = Color(hex: "808080")

    /// Menu background (very dark)
    static let menuBackground = Color(hex: "181818")

    // MARK: - Screen Colors

    /// LCD screen background
    static let screenColor = Color(hex: "222222")

    /// Area behind the screen
    static let behindScreen = Color(hex: "413D38")

    /// LCD display text color (green phosphor)
    static let displayGreen = Color(hex: "00FF00")

    /// Secondary display text (dimmer green)
    static let displayGreenDim = Color(hex: "00CC00").opacity(0.7)

    // MARK: - Text Colors

    /// Gray for letter labels
    static let letterGrey = Color(hex: "A5A5A5")

    // MARK: - Semantic Colors

    /// Enter key background (green)
    static let enterKey = Color(hex: "2D5016")

    /// Clear/delete key background (red tint)
    static let clearKey = Color(hex: "5C2020")

    /// Arithmetic operation key background
    static let operationKey = Color(hex: "4A3520")
}

// MARK: - Color Extension for Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Button Styles

/// Style for standard calculator keys
struct C47KeyStyle {
    let background: Color
    let foreground: Color
    let border: Color
    let pressedBackground: Color
    let fontSize: CGFloat
    let cornerRadius: CGFloat

    static let numeric = C47KeyStyle(
        background: C47Theme.numericKeyBackground,
        foreground: C47Theme.keyLabelColor,
        border: C47Theme.numericKeyBorder,
        pressedBackground: C47Theme.keyHover,
        fontSize: 24,
        cornerRadius: 3
    )

    static let function = C47KeyStyle(
        background: C47Theme.keyBackground,
        foreground: C47Theme.keyLabelColor,
        border: C47Theme.keyBorder,
        pressedBackground: C47Theme.keyHover,
        fontSize: 14,
        cornerRadius: 3
    )

    static let fShift = C47KeyStyle(
        background: C47Theme.fGold,
        foreground: .black,
        border: C47Theme.keyBorder,
        pressedBackground: C47Theme.fHoverGold,
        fontSize: 18,
        cornerRadius: 3
    )

    static let gShift = C47KeyStyle(
        background: C47Theme.gBlue,
        foreground: .black,
        border: C47Theme.keyBorder,
        pressedBackground: C47Theme.gHoverBlue,
        fontSize: 18,
        cornerRadius: 3
    )

    static let alpha = C47KeyStyle(
        background: C47Theme.alphaGold,
        foreground: .black,
        border: C47Theme.keyBorder,
        pressedBackground: C47Theme.alphaHoverGold,
        fontSize: 14,
        cornerRadius: 3
    )

    static let enter = C47KeyStyle(
        background: C47Theme.enterKey,
        foreground: C47Theme.keyLabelColor,
        border: C47Theme.keyBorder,
        pressedBackground: C47Theme.keyHover,
        fontSize: 14,
        cornerRadius: 3
    )

    static let clear = C47KeyStyle(
        background: C47Theme.clearKey,
        foreground: C47Theme.keyLabelColor,
        border: C47Theme.keyBorder,
        pressedBackground: C47Theme.keyHover,
        fontSize: 14,
        cornerRadius: 3
    )

    static let operation = C47KeyStyle(
        background: C47Theme.operationKey,
        foreground: C47Theme.keyLabelColor,
        border: C47Theme.keyBorder,
        pressedBackground: C47Theme.keyHover,
        fontSize: 20,
        cornerRadius: 3
    )
}
