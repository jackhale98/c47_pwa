// SPDX-License-Identifier: GPL-3.0-only
// KeypadView.swift
// C47 Calculator for iOS - Calculator Keypad View

import SwiftUI

/// The calculator keypad with all buttons
struct KeypadView: View {
    @ObservedObject var viewModel: CalculatorViewModel

    /// Layout style for the keypad
    var layoutStyle: KeypadLayout = .scientific

    /// Spacing between buttons
    var buttonSpacing: CGFloat = 8

    var body: some View {
        let layout = layoutStyle.keys

        VStack(spacing: buttonSpacing) {
            ForEach(layout.indices, id: \.self) { rowIndex in
                HStack(spacing: buttonSpacing) {
                    ForEach(layout[rowIndex], id: \.self) { key in
                        CalculatorButton(
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

// MARK: - Calculator Button

struct CalculatorButton: View {
    let key: KeyCode
    var isShiftFActive: Bool = false
    var isShiftGActive: Bool = false
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            action()
        }) {
            VStack(spacing: 2) {
                // Shifted function labels (smaller, above)
                if let shiftLabel = currentShiftLabel {
                    Text(shiftLabel)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(shiftLabelColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }

                // Primary label
                Text(key.primaryLabel)
                    .font(.system(size: buttonFontSize, weight: .semibold, design: .rounded))
                    .foregroundColor(foregroundColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(backgroundColor)
            .cornerRadius(buttonCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: buttonCornerRadius)
                    .stroke(borderColor, lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
        .aspectRatio(buttonAspectRatio, contentMode: .fit)
    }

    // MARK: - Computed Properties

    private var currentShiftLabel: String? {
        if isShiftFActive {
            return key.shiftFLabel
        } else if isShiftGActive {
            return key.shiftGLabel
        }
        return nil
    }

    private var shiftLabelColor: Color {
        if isShiftFActive {
            return .yellow
        } else if isShiftGActive {
            return .cyan
        }
        return .clear
    }

    private var backgroundColor: Color {
        switch key {
        case .enter:
            return Color(red: 0.0, green: 0.4, blue: 0.0)
        case .plus, .minus, .multiply, .divide:
            return Color(red: 0.6, green: 0.4, blue: 0.0)
        case .shiftF:
            return isShiftFActive ? .yellow : Color(red: 0.6, green: 0.5, blue: 0.0)
        case .shiftG:
            return isShiftGActive ? .cyan : Color(red: 0.0, green: 0.4, blue: 0.5)
        case .clear, .clx:
            return Color(red: 0.5, green: 0.2, blue: 0.2)
        case .digit0, .digit1, .digit2, .digit3, .digit4,
             .digit5, .digit6, .digit7, .digit8, .digit9, .dot:
            return Color(red: 0.25, green: 0.25, blue: 0.25)
        default:
            return Color(red: 0.35, green: 0.35, blue: 0.35)
        }
    }

    private var foregroundColor: Color {
        switch key {
        case .shiftF where isShiftFActive:
            return .black
        case .shiftG where isShiftGActive:
            return .black
        default:
            return .white
        }
    }

    private var borderColor: Color {
        backgroundColor.opacity(0.5)
    }

    private var buttonFontSize: CGFloat {
        switch key {
        case .enter:
            return 14
        case .digit0, .digit1, .digit2, .digit3, .digit4,
             .digit5, .digit6, .digit7, .digit8, .digit9:
            return 20
        case .plus, .minus, .multiply, .divide:
            return 22
        default:
            return 12
        }
    }

    private var buttonCornerRadius: CGFloat {
        8
    }

    private var buttonAspectRatio: CGFloat {
        key == .enter ? 2.0 : 1.0
    }
}

// MARK: - Simple Keypad (Basic Calculator)

struct SimpleKeypadView: View {
    @ObservedObject var viewModel: CalculatorViewModel

    let buttonSpacing: CGFloat = 10

    var body: some View {
        VStack(spacing: buttonSpacing) {
            // Row 1: Clear operations
            HStack(spacing: buttonSpacing) {
                SimpleButton(label: "AC", color: .red.opacity(0.7)) {
                    viewModel.clear()
                }
                SimpleButton(label: "+/−", color: .gray) {
                    viewModel.changeSign()
                }
                SimpleButton(label: "%", color: .gray) {
                    viewModel.percent()
                }
                SimpleButton(label: "÷", color: .orange) {
                    viewModel.divide()
                }
            }

            // Row 2
            HStack(spacing: buttonSpacing) {
                SimpleButton(label: "7") { viewModel.enterDigit(7) }
                SimpleButton(label: "8") { viewModel.enterDigit(8) }
                SimpleButton(label: "9") { viewModel.enterDigit(9) }
                SimpleButton(label: "×", color: .orange) {
                    viewModel.multiply()
                }
            }

            // Row 3
            HStack(spacing: buttonSpacing) {
                SimpleButton(label: "4") { viewModel.enterDigit(4) }
                SimpleButton(label: "5") { viewModel.enterDigit(5) }
                SimpleButton(label: "6") { viewModel.enterDigit(6) }
                SimpleButton(label: "−", color: .orange) {
                    viewModel.subtract()
                }
            }

            // Row 4
            HStack(spacing: buttonSpacing) {
                SimpleButton(label: "1") { viewModel.enterDigit(1) }
                SimpleButton(label: "2") { viewModel.enterDigit(2) }
                SimpleButton(label: "3") { viewModel.enterDigit(3) }
                SimpleButton(label: "+", color: .orange) {
                    viewModel.add()
                }
            }

            // Row 5
            HStack(spacing: buttonSpacing) {
                SimpleButton(label: "0", span: 2) { viewModel.enterDigit(0) }
                SimpleButton(label: ".") { viewModel.enterDecimal() }
                SimpleButton(label: "⏎", color: .green) {
                    viewModel.enter()
                }
            }
        }
    }
}

// MARK: - Simple Button

struct SimpleButton: View {
    let label: String
    var color: Color = Color(white: 0.3)
    var span: Int = 1
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 24, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(color)
                .cornerRadius(10)
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
        .aspectRatio(span == 2 ? 2.2 : 1.0, contentMode: .fit)
    }
}

// MARK: - Preview

#Preview("Scientific Keypad") {
    KeypadView(viewModel: CalculatorViewModel(), layoutStyle: .scientific)
        .padding()
        .background(Color.black)
}

#Preview("Simple Keypad") {
    SimpleKeypadView(viewModel: CalculatorViewModel())
        .padding()
        .background(Color.black)
}
