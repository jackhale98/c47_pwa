// SPDX-License-Identifier: GPL-3.0-only
// DisplayView.swift
// C47 Calculator for iOS - Calculator Display View

import SwiftUI

/// The calculator display showing stack registers and main display
struct DisplayView: View {
    @ObservedObject var viewModel: CalculatorViewModel

    /// Whether to show the full stack (all 4 registers)
    var showFullStack: Bool = true

    /// Color scheme for the display
    var displayColor: Color = Color(red: 0.0, green: 0.8, blue: 0.0)

    var body: some View {
        VStack(spacing: 0) {
            // Status bar
            statusBar

            // Stack display
            if showFullStack {
                stackDisplay
            }

            // Main display (X register)
            mainDisplay

            // Error display if any
            if viewModel.hasError {
                errorDisplay
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.5), lineWidth: 2)
        )
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack {
            // Angle mode indicator
            Text(viewModel.angleMode.label)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(displayColor.opacity(0.8))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.black.opacity(0.3))
                .cornerRadius(4)
                .onTapGesture {
                    viewModel.cycleAngleMode()
                }

            Spacer()

            // Shift indicators
            HStack(spacing: 8) {
                if viewModel.isShiftFActive {
                    Text("f")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.yellow)
                }
                if viewModel.isShiftGActive {
                    Text("g")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)
                }
                if viewModel.isAlphaActive {
                    Text("α")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.bottom, 4)
    }

    // MARK: - Stack Display

    private var stackDisplay: some View {
        VStack(alignment: .trailing, spacing: 2) {
            stackRegisterRow(label: "T:", value: viewModel.stackT)
            stackRegisterRow(label: "Z:", value: viewModel.stackZ)
            stackRegisterRow(label: "Y:", value: viewModel.stackY)
        }
        .padding(.bottom, 4)
    }

    private func stackRegisterRow(label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(displayColor.opacity(0.5))
                .frame(width: 20, alignment: .leading)

            Text(value)
                .font(.system(size: 14, weight: .regular, design: .monospaced))
                .foregroundColor(displayColor.opacity(0.7))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    // MARK: - Main Display

    private var mainDisplay: some View {
        HStack(spacing: 8) {
            Text("X:")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(displayColor.opacity(0.7))
                .frame(width: 24, alignment: .leading)

            Text(viewModel.display)
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(displayColor)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Error Display

    private var errorDisplay: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .font(.system(size: 12))

            Text(viewModel.errorMessage ?? "Error")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.red)
                .lineLimit(1)

            Spacer()
        }
        .padding(.top, 4)
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
                    .foregroundColor(.green.opacity(0.7))

                Spacer()

                if viewModel.isShiftFActive {
                    Text("f")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.yellow)
                }
                if viewModel.isShiftGActive {
                    Text("g")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.cyan)
                }
            }

            // Y register (small)
            HStack {
                Spacer()
                Text(viewModel.stackY)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.green.opacity(0.6))
                    .lineLimit(1)
            }

            // X register (main)
            HStack {
                Spacer()
                Text(viewModel.display)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .padding(10)
        .background(Color.black)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview("Full Display") {
    DisplayView(viewModel: CalculatorViewModel())
        .padding()
        .background(Color.gray.opacity(0.3))
}

#Preview("Compact Display") {
    CompactDisplayView(viewModel: CalculatorViewModel())
        .padding()
        .background(Color.gray.opacity(0.3))
}
