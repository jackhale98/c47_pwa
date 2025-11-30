// SPDX-License-Identifier: GPL-3.0-only
// KeypadView.swift
// C47 Calculator for iOS - Authentic C47 Keypad

import SwiftUI

/// The calculator keypad with authentic C47 button styling
struct KeypadView: View {
    @ObservedObject var viewModel: CalculatorViewModel

    /// Layout style for the keypad
    var layoutStyle: KeypadLayout = .scientific

    /// Spacing between buttons
    var buttonSpacing: CGFloat = 4

    var body: some View {
        let layout = layoutStyle.keys

        VStack(spacing: buttonSpacing) {
            ForEach(layout.indices, id: \.self) { rowIndex in
                HStack(spacing: buttonSpacing) {
                    ForEach(layout[rowIndex], id: \.self) { key in
                        C47Button(
                            key: key,
                            isShiftFActive: viewModel.isShiftFActive,
                            isShiftGActive: viewModel.isShiftGActive
                        ) {
                            viewModel.pressKey(key)
                        }
                    }
                }
            }
        }
        .padding(4)
        .background(C47Theme.bezelBackground)
    }
}

// MARK: - Keypad Layout Enum

enum KeypadLayout {
    case compact
    case standard
    case scientific

    var keys: [[KeyCode]] {
        switch self {
        case .compact:
            return KeyCode.compactLayout
        case .standard:
            return KeyCode.standardLayout
        case .scientific:
            return KeyCode.scientificLayout
        }
    }
}

// MARK: - Authentic C47 Button

struct C47Button: View {
    let key: KeyCode
    var isShiftFActive: Bool = false
    var isShiftGActive: Bool = false
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            action()
        }) {
            VStack(spacing: 1) {
                // F-shifted label (gold, above key)
                if let fLabel = key.shiftFLabel {
                    Text(fLabel)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(C47Theme.fGold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }

                // Primary label
                Text(key.primaryLabel)
                    .font(.system(size: buttonFontSize, weight: .medium, design: .monospaced))
                    .foregroundColor(foregroundColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                // G-shifted label (blue, below key)
                if let gLabel = key.shiftGLabel {
                    Text(gLabel)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(C47Theme.gBlue)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(isPressed ? pressedBackground : backgroundColor)
            .cornerRadius(3)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(borderColor, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .aspectRatio(buttonAspectRatio, contentMode: .fit)
    }

    // MARK: - Computed Properties

    private var backgroundColor: Color {
        switch key {
        case .shiftF:
            return isShiftFActive ? C47Theme.fHoverGold : C47Theme.fGold
        case .shiftG:
            return isShiftGActive ? C47Theme.gHoverBlue : C47Theme.gBlue
        case .alpha:
            return C47Theme.alphaGold
        default:
            return C47Theme.keyBackground
        }
    }

    private var pressedBackground: Color {
        switch key {
        case .shiftF:
            return C47Theme.fHoverGold
        case .shiftG:
            return C47Theme.gHoverBlue
        case .alpha:
            return C47Theme.alphaHoverGold
        default:
            return C47Theme.keyHover
        }
    }

    private var foregroundColor: Color {
        switch key {
        case .shiftF, .shiftG, .alpha:
            return .black
        default:
            return C47Theme.keyLabelColor
        }
    }

    private var borderColor: Color {
        switch key {
        case .shiftF:
            return C47Theme.fGold.opacity(0.5)
        case .shiftG:
            return C47Theme.gBlue.opacity(0.5)
        default:
            return C47Theme.keyBorder
        }
    }

    private var buttonFontSize: CGFloat {
        switch key {
        case .digit0, .digit1, .digit2, .digit3, .digit4,
             .digit5, .digit6, .digit7, .digit8, .digit9:
            return 22
        case .plus, .minus, .multiply, .divide:
            return 18
        case .enter:
            return 12
        case .shiftF, .shiftG:
            return 18
        default:
            return 11
        }
    }

    private var buttonAspectRatio: CGFloat {
        1.0
    }
}

// MARK: - Simple Keypad (Basic Calculator Style)

struct SimpleKeypadView: View {
    @ObservedObject var viewModel: CalculatorViewModel

    let buttonSpacing: CGFloat = 6

    var body: some View {
        VStack(spacing: buttonSpacing) {
            // Row 1: Clear operations
            HStack(spacing: buttonSpacing) {
                SimpleC47Button(label: "AC", style: .clear) {
                    viewModel.clear()
                }
                SimpleC47Button(label: "+/−", style: .function) {
                    viewModel.changeSign()
                }
                SimpleC47Button(label: "%", style: .function) {
                    viewModel.percent()
                }
                SimpleC47Button(label: "÷", style: .operation) {
                    viewModel.divide()
                }
            }

            // Row 2
            HStack(spacing: buttonSpacing) {
                SimpleC47Button(label: "7", style: .numeric) { viewModel.enterDigit(7) }
                SimpleC47Button(label: "8", style: .numeric) { viewModel.enterDigit(8) }
                SimpleC47Button(label: "9", style: .numeric) { viewModel.enterDigit(9) }
                SimpleC47Button(label: "×", style: .operation) {
                    viewModel.multiply()
                }
            }

            // Row 3
            HStack(spacing: buttonSpacing) {
                SimpleC47Button(label: "4", style: .numeric) { viewModel.enterDigit(4) }
                SimpleC47Button(label: "5", style: .numeric) { viewModel.enterDigit(5) }
                SimpleC47Button(label: "6", style: .numeric) { viewModel.enterDigit(6) }
                SimpleC47Button(label: "−", style: .operation) {
                    viewModel.subtract()
                }
            }

            // Row 4
            HStack(spacing: buttonSpacing) {
                SimpleC47Button(label: "1", style: .numeric) { viewModel.enterDigit(1) }
                SimpleC47Button(label: "2", style: .numeric) { viewModel.enterDigit(2) }
                SimpleC47Button(label: "3", style: .numeric) { viewModel.enterDigit(3) }
                SimpleC47Button(label: "+", style: .operation) {
                    viewModel.add()
                }
            }

            // Row 5
            HStack(spacing: buttonSpacing) {
                SimpleC47Button(label: "0", style: .numeric, span: 2) { viewModel.enterDigit(0) }
                SimpleC47Button(label: ".", style: .numeric) { viewModel.enterDecimal() }
                SimpleC47Button(label: "ENTER", style: .enter) {
                    viewModel.enter()
                }
            }
        }
        .padding(4)
        .background(C47Theme.bezelBackground)
    }
}

// MARK: - Simple C47 Button

enum SimpleButtonStyle {
    case numeric
    case operation
    case function
    case enter
    case clear
}

struct SimpleC47Button: View {
    let label: String
    var style: SimpleButtonStyle = .numeric
    var span: Int = 1
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: fontSize, weight: .medium, design: .monospaced))
                .foregroundColor(foregroundColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(isPressed ? pressedColor : backgroundColor)
                .cornerRadius(3)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(C47Theme.keyBorder, lineWidth: 2)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .aspectRatio(span == 2 ? 2.1 : 1.0, contentMode: .fit)
    }

    private var backgroundColor: Color {
        switch style {
        case .numeric:
            return C47Theme.numericKeyBackground
        case .operation:
            return C47Theme.operationKey
        case .function:
            return C47Theme.keyBackground
        case .enter:
            return C47Theme.enterKey
        case .clear:
            return C47Theme.clearKey
        }
    }

    private var pressedColor: Color {
        C47Theme.keyHover
    }

    private var foregroundColor: Color {
        C47Theme.keyLabelColor
    }

    private var fontSize: CGFloat {
        switch style {
        case .numeric:
            return 24
        case .operation:
            return 20
        case .enter:
            return 12
        default:
            return 14
        }
    }
}

// MARK: - Preview

#Preview("C47 Scientific Keypad") {
    KeypadView(viewModel: CalculatorViewModel(), layoutStyle: .scientific)
        .background(C47Theme.bezelBackground)
}

#Preview("C47 Simple Keypad") {
    SimpleKeypadView(viewModel: CalculatorViewModel())
        .background(C47Theme.bezelBackground)
}
