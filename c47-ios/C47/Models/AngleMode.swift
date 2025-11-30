// SPDX-License-Identifier: GPL-3.0-only
// AngleMode.swift
// C47 Calculator for iOS - Angle Mode Definitions

import Foundation

/// Represents the angle mode for trigonometric calculations
enum AngleMode: Int32, CaseIterable, Identifiable {
    case degrees = 0
    case radians = 1
    case gradians = 2

    var id: Int32 { rawValue }

    /// Display label for the angle mode
    var label: String {
        switch self {
        case .degrees: return "DEG"
        case .radians: return "RAD"
        case .gradians: return "GRAD"
        }
    }

    /// Full name of the angle mode
    var fullName: String {
        switch self {
        case .degrees: return "Degrees"
        case .radians: return "Radians"
        case .gradians: return "Gradians"
        }
    }

    /// Symbol used in mathematical notation
    var symbol: String {
        switch self {
        case .degrees: return "°"
        case .radians: return "rad"
        case .gradians: return "gon"
        }
    }

    /// Cycle to the next angle mode
    func next() -> AngleMode {
        switch self {
        case .degrees: return .radians
        case .radians: return .gradians
        case .gradians: return .degrees
        }
    }

    /// Convert a C47AngleMode value to AngleMode
    init(fromC47Mode mode: C47AngleMode) {
        switch mode {
        case C47_ANGLE_DEGREES:
            self = .degrees
        case C47_ANGLE_RADIANS:
            self = .radians
        case C47_ANGLE_GRADIANS:
            self = .gradians
        default:
            self = .degrees
        }
    }

    /// Convert to C47AngleMode for the C bridge
    var c47Mode: C47AngleMode {
        switch self {
        case .degrees: return C47_ANGLE_DEGREES
        case .radians: return C47_ANGLE_RADIANS
        case .gradians: return C47_ANGLE_GRADIANS
        }
    }
}
