// SPDX-License-Identifier: GPL-3.0-only
// KeyCode.swift
// C47 Calculator for iOS - Key Code Definitions

import Foundation

/// Represents all key codes for the C47 calculator
/// Maps directly to C47KeyCode enum in c47-ios-bridge.h
enum KeyCode: Int32, CaseIterable {
    // MARK: - Digit Keys
    case digit0 = 0
    case digit1 = 1
    case digit2 = 2
    case digit3 = 3
    case digit4 = 4
    case digit5 = 5
    case digit6 = 6
    case digit7 = 7
    case digit8 = 8
    case digit9 = 9

    // MARK: - Entry Keys
    case dot = 10
    case chs = 11           // Change sign (+/-)
    case eex = 12           // Enter exponent
    case enter = 13
    case backspace = 14

    // MARK: - Basic Arithmetic
    case plus = 20
    case minus = 21
    case multiply = 22
    case divide = 23

    // MARK: - Scientific Functions
    case sqrt = 30
    case square = 31
    case reciprocal = 32
    case power = 33
    case percent = 34

    // MARK: - Trigonometric
    case sin = 40
    case cos = 41
    case tan = 42
    case asin = 43
    case acos = 44
    case atan = 45

    // MARK: - Logarithmic
    case ln = 50
    case log = 51
    case exp = 52
    case pow10 = 53

    // MARK: - Stack Operations
    case swap = 60          // x<>y
    case rollDown = 61
    case rollUp = 62
    case lastX = 63
    case clx = 64
    case clear = 65

    // MARK: - Memory
    case sto = 70
    case rcl = 71

    // MARK: - Constants
    case pi = 80
    case e = 81

    // MARK: - Mode/Shift Keys
    case shiftF = 90
    case shiftG = 91
    case alpha = 92
    case mode = 93

    // MARK: - Statistics
    case sigmaPlus = 100
    case sigmaMinus = 101

    // MARK: - Additional Functions
    case abs = 110
    case int = 111
    case frac = 112
    case factorial = 113

    // MARK: - Hyperbolic
    case sinh = 120
    case cosh = 121
    case tanh = 122
    case asinh = 123
    case acosh = 124
    case atanh = 125
}

// MARK: - KeyCode Display Properties
extension KeyCode {
    /// The primary label shown on the key
    var primaryLabel: String {
        switch self {
        case .digit0: return "0"
        case .digit1: return "1"
        case .digit2: return "2"
        case .digit3: return "3"
        case .digit4: return "4"
        case .digit5: return "5"
        case .digit6: return "6"
        case .digit7: return "7"
        case .digit8: return "8"
        case .digit9: return "9"
        case .dot: return "."
        case .chs: return "+/−"
        case .eex: return "EEX"
        case .enter: return "ENTER"
        case .backspace: return "←"
        case .plus: return "+"
        case .minus: return "−"
        case .multiply: return "×"
        case .divide: return "÷"
        case .sqrt: return "√x"
        case .square: return "x²"
        case .reciprocal: return "1/x"
        case .power: return "yˣ"
        case .percent: return "%"
        case .sin: return "SIN"
        case .cos: return "COS"
        case .tan: return "TAN"
        case .asin: return "ASIN"
        case .acos: return "ACOS"
        case .atan: return "ATAN"
        case .ln: return "LN"
        case .log: return "LOG"
        case .exp: return "eˣ"
        case .pow10: return "10ˣ"
        case .swap: return "x⇄y"
        case .rollDown: return "R↓"
        case .rollUp: return "R↑"
        case .lastX: return "LASTx"
        case .clx: return "CLx"
        case .clear: return "CLEAR"
        case .sto: return "STO"
        case .rcl: return "RCL"
        case .pi: return "π"
        case .e: return "e"
        case .shiftF: return "f"
        case .shiftG: return "g"
        case .alpha: return "ALPHA"
        case .mode: return "MODE"
        case .sigmaPlus: return "Σ+"
        case .sigmaMinus: return "Σ−"
        case .abs: return "|x|"
        case .int: return "INT"
        case .frac: return "FRAC"
        case .factorial: return "n!"
        case .sinh: return "SINH"
        case .cosh: return "COSH"
        case .tanh: return "TANH"
        case .asinh: return "ASINH"
        case .acosh: return "ACOSH"
        case .atanh: return "ATANH"
        }
    }

    /// The shifted (f) function label, if any
    var shiftFLabel: String? {
        switch self {
        case .digit0: return "x!"
        case .digit1: return "x⇄y"
        case .digit2: return "R↓"
        case .digit3: return "→HMS"
        case .digit4: return "→H"
        case .digit5: return "→RAD"
        case .digit6: return "→DEG"
        case .sqrt: return "x²"
        case .ln: return "eˣ"
        case .log: return "10ˣ"
        case .sin: return "ASIN"
        case .cos: return "ACOS"
        case .tan: return "ATAN"
        case .reciprocal: return "y√x"
        case .power: return "ˣ√y"
        case .percent: return "Δ%"
        default: return nil
        }
    }

    /// The shifted (g) function label, if any
    var shiftGLabel: String? {
        switch self {
        case .sin: return "SINH"
        case .cos: return "COSH"
        case .tan: return "TANH"
        case .ln: return "LN1+x"
        case .log: return "eˣ-1"
        case .sqrt: return "ABS"
        case .reciprocal: return "INT"
        case .power: return "FRAC"
        default: return nil
        }
    }

    /// Whether this is a digit key
    var isDigit: Bool {
        switch self {
        case .digit0, .digit1, .digit2, .digit3, .digit4,
             .digit5, .digit6, .digit7, .digit8, .digit9:
            return true
        default:
            return false
        }
    }

    /// Whether this is an operation key
    var isOperation: Bool {
        switch self {
        case .plus, .minus, .multiply, .divide, .power, .percent:
            return true
        default:
            return false
        }
    }

    /// Whether this is a function key
    var isFunction: Bool {
        switch self {
        case .sqrt, .square, .reciprocal, .sin, .cos, .tan,
             .asin, .acos, .atan, .ln, .log, .exp, .pow10,
             .sinh, .cosh, .tanh, .asinh, .acosh, .atanh,
             .abs, .int, .frac, .factorial:
            return true
        default:
            return false
        }
    }
}

// MARK: - Key Layout Definition
extension KeyCode {
    /// Standard C47-style keyboard layout
    /// Returns keys organized in rows for the main keypad
    static var standardLayout: [[KeyCode]] {
        [
            // Row 1: Top function row
            [.shiftF, .shiftG, .mode, .sto, .rcl],
            // Row 2
            [.sqrt, .square, .ln, .log, .swap],
            // Row 3
            [.sin, .cos, .tan, .reciprocal, .rollDown],
            // Row 4
            [.enter, .chs, .eex, .backspace, .divide],
            // Row 5
            [.digit7, .digit8, .digit9, .multiply],
            // Row 6
            [.digit4, .digit5, .digit6, .minus],
            // Row 7
            [.digit1, .digit2, .digit3, .plus],
            // Row 8: Bottom row
            [.digit0, .dot, .pi, .enter]
        ]
    }

    /// Compact layout for portrait mode on smaller devices
    static var compactLayout: [[KeyCode]] {
        [
            // Row 1
            [.clear, .chs, .percent, .divide],
            // Row 2
            [.digit7, .digit8, .digit9, .multiply],
            // Row 3
            [.digit4, .digit5, .digit6, .minus],
            // Row 4
            [.digit1, .digit2, .digit3, .plus],
            // Row 5
            [.digit0, .dot, .swap, .enter]
        ]
    }

    /// Scientific layout with more functions visible
    static var scientificLayout: [[KeyCode]] {
        [
            // Row 1
            [.shiftF, .shiftG, .clx, .clear],
            // Row 2
            [.sqrt, .square, .power, .reciprocal],
            // Row 3
            [.sin, .cos, .tan, .pi],
            // Row 4
            [.ln, .log, .exp, .e],
            // Row 5
            [.enter, .swap, .rollDown, .lastX],
            // Row 6
            [.digit7, .digit8, .digit9, .divide],
            // Row 7
            [.digit4, .digit5, .digit6, .multiply],
            // Row 8
            [.digit1, .digit2, .digit3, .minus],
            // Row 9
            [.digit0, .dot, .chs, .plus]
        ]
    }
}
