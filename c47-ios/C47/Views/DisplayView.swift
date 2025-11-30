// SPDX-License-Identifier: GPL-3.0-only
// DisplayView.swift
// C47 Calculator for iOS - Authentic C47 LCD Display

import SwiftUI

/// Authentic C47 LCD display matching the simulator appearance
struct DisplayView: View {
    @ObservedObject var viewModel: CalculatorViewModel

    /// Whether to show the full stack (all 4 registers)
    var showFullStack: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            // LCD Screen area with authentic styling
            VStack(spacing: 0) {
                // Status bar
                statusBar
                    .padding(.horizontal, 8)
                    .padding(.top, 4)

                // Stack display
                if showFullStack {
                    stackDisplay
                        .padding(.horizontal, 8)
                        .padding(.top, 2)
                }

                // Main display (X register)
                mainDisplay
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)

                // Error display if any
                if viewModel.hasError {
                    errorDisplay
                        .padding(.horizontal, 8)
                        .padding(.bottom, 4)
                }
            }
            .background(C47Theme.screenColor)
            .cornerRadius(2)
            .padding(4)
            .background(C47Theme.behindScreen)
            .cornerRadius(4)

            // Softkey area (6 menu keys below screen)
            softkeyRow
                .padding(.top, 4)
                .padding(.horizontal, 4)
        }
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack(spacing: 12) {
            // Angle mode indicator
            Text(viewModel.angleMode.label)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(C47Theme.displayGreen)
                .onTapGesture {
                    viewModel.cycleAngleMode()
                }

            Spacer()

            // Shift indicators
            HStack(spacing: 6) {
                if viewModel.isShiftFActive {
                    Text("f")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(C47Theme.fGold)
                }
                if viewModel.isShiftGActive {
                    Text("g")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(C47Theme.gBlue)
                }
                if viewModel.isAlphaActive {
                    Text("α")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(C47Theme.alphaGold)
                }
            }

            // Error indicator
            if viewModel.hasError {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.red)
            }
        }
    }

    // MARK: - Stack Display

    private var stackDisplay: some View {
        VStack(alignment: .trailing, spacing: 1) {
            stackRegisterRow(label: "T", value: viewModel.stackT)
            stackRegisterRow(label: "Z", value: viewModel.stackZ)
            stackRegisterRow(label: "Y", value: viewModel.stackY)
        }
    }

    private func stackRegisterRow(label: String, value: String) -> some View {
        HStack(spacing: 4) {
            Text("\(label):")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(C47Theme.displayGreen.opacity(0.5))
                .frame(width: 16, alignment: .leading)

            Spacer()

            Text(value)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(C47Theme.displayGreen.opacity(0.7))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
    }

    // MARK: - Main Display

    private var mainDisplay: some View {
        HStack(spacing: 4) {
            Text("X:")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(C47Theme.displayGreen.opacity(0.8))
                .frame(width: 20, alignment: .leading)

            Spacer()

            Text(viewModel.display)
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(C47Theme.displayGreen)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
        }
        .padding(.top, 4)
    }

    // MARK: - Error Display

    private var errorDisplay: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .font(.system(size: 10))

            Text(viewModel.errorMessage ?? "Error")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.red)
                .lineLimit(1)

            Spacer()
        }
    }

    // MARK: - Softkey Row (Menu Keys)

    private var softkeyRow: some View {
        HStack(spacing: 3) {
            ForEach(0..<6, id: \.self) { _ in
                SoftkeyButton(label: "") {
                    // Softkey action - will be dynamic based on menu state
                }
            }
        }
    }
}

// MARK: - Softkey Button

struct SoftkeyButton: View {
    let label: String
    var fLabel: String?
    var gLabel: String?
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 1) {
                // F-shifted label
                if let fLabel = fLabel {
                    Text(fLabel)
                        .font(.system(size: 7, weight: .medium))
                        .foregroundColor(C47Theme.fGold)
                }

                // Main label
                Text(label)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(C47Theme.keyLabelColor)

                // G-shifted label
                if let gLabel = gLabel {
                    Text(gLabel)
                        .font(.system(size: 7, weight: .medium))
                        .foregroundColor(C47Theme.gBlue)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 32)
            .background(isPressed ? C47Theme.keyHover : C47Theme.keyBackground)
            .cornerRadius(3)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(C47Theme.keyBorder, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Compact Display View

/// A more compact display for smaller screens
struct CompactDisplayView: View {
    @ObservedObject var viewModel: CalculatorViewModel

    var body: some View {
        VStack(spacing: 4) {
            // Status bar
            HStack {
                Text(viewModel.angleMode.label)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(C47Theme.displayGreen.opacity(0.7))

                Spacer()

                if viewModel.isShiftFActive {
                    Text("f")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(C47Theme.fGold)
                }
                if viewModel.isShiftGActive {
                    Text("g")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(C47Theme.gBlue)
                }
            }

            // Y register (small)
            HStack {
                Spacer()
                Text(viewModel.stackY)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(C47Theme.displayGreen.opacity(0.6))
                    .lineLimit(1)
            }

            // X register (main)
            HStack {
                Spacer()
                Text(viewModel.display)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(C47Theme.displayGreen)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .padding(10)
        .background(C47Theme.screenColor)
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(C47Theme.behindScreen, lineWidth: 2)
        )
    }
}

// MARK: - Preview

#Preview("C47 Display") {
    DisplayView(viewModel: CalculatorViewModel())
        .padding()
        .background(C47Theme.bezelBackground)
}

#Preview("Compact Display") {
    CompactDisplayView(viewModel: CalculatorViewModel())
        .padding()
        .background(C47Theme.bezelBackground)
}
