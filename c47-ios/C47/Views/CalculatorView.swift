// SPDX-License-Identifier: GPL-3.0-only
// CalculatorView.swift
// C47 Calculator for iOS - Main Calculator View

import SwiftUI

/// The main calculator view combining display and keypad
struct CalculatorView: View {
    @StateObject private var viewModel = CalculatorViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    /// Whether to show scientific functions
    @State private var showScientific: Bool = true

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height

            if isLandscape {
                landscapeLayout(geometry: geometry)
            } else {
                portraitLayout(geometry: geometry)
            }
        }
        .background(Color(white: 0.1))
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
    }

    // MARK: - Portrait Layout

    private func portraitLayout(geometry: GeometryProxy) -> some View {
        VStack(spacing: 12) {
            // Display area
            DisplayView(viewModel: viewModel, showFullStack: true)
                .frame(height: geometry.size.height * 0.25)

            // Mode selector
            modeSelector

            // Keypad
            if showScientific {
                KeypadView(viewModel: viewModel, layoutStyle: .scientific)
            } else {
                SimpleKeypadView(viewModel: viewModel)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 8)
    }

    // MARK: - Landscape Layout

    private func landscapeLayout(geometry: GeometryProxy) -> some View {
        HStack(spacing: 12) {
            // Left side: Display and stack
            VStack(spacing: 8) {
                StackView(viewModel: viewModel)

                Spacer()

                // Quick function buttons
                quickFunctionBar
            }
            .frame(width: geometry.size.width * 0.35)

            // Right side: Keypad
            VStack(spacing: 8) {
                // Mode selector
                modeSelector

                // Keypad
                KeypadView(viewModel: viewModel, layoutStyle: showScientific ? .scientific : .compact)
            }
        }
        .padding(12)
    }

    // MARK: - Mode Selector

    private var modeSelector: some View {
        HStack {
            // Scientific/Simple toggle
            Button {
                withAnimation {
                    showScientific.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: showScientific ? "function" : "number")
                        .font(.system(size: 12))
                    Text(showScientific ? "SCI" : "STD")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(4)
            }

            Spacer()

            // Angle mode
            Button {
                viewModel.cycleAngleMode()
            } label: {
                Text(viewModel.angleMode.label)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(4)
            }

            Spacer()

            // Clear button
            Button {
                viewModel.clear()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundColor(.red.opacity(0.7))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(4)
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Quick Function Bar

    private var quickFunctionBar: some View {
        HStack(spacing: 8) {
            QuickButton(label: "x⇄y") { viewModel.swap() }
            QuickButton(label: "R↓") { viewModel.rollDown() }
            QuickButton(label: "LASTx") { viewModel.recallLastX() }
            QuickButton(label: "CLx") { viewModel.clearX() }
        }
    }

    // MARK: - Scene Phase Handling

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            viewModel.sceneDidBecomeActive()
        case .inactive, .background:
            viewModel.sceneWillResignActive()
        @unknown default:
            break
        }
    }
}

// MARK: - Quick Button

struct QuickButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(4)
        }
    }
}

// MARK: - Calculator View with Custom Theme

struct ThemedCalculatorView: View {
    @StateObject private var viewModel = CalculatorViewModel()

    let displayColor: Color
    let backgroundColor: Color

    var body: some View {
        VStack(spacing: 12) {
            DisplayView(viewModel: viewModel, displayColor: displayColor)

            KeypadView(viewModel: viewModel, layoutStyle: .scientific)
        }
        .padding(12)
        .background(backgroundColor)
    }
}

// MARK: - Preview

#Preview("Calculator - Portrait") {
    CalculatorView()
        .preferredColorScheme(.dark)
}

#Preview("Calculator - Landscape") {
    CalculatorView()
        .preferredColorScheme(.dark)
        .previewInterfaceOrientation(.landscapeLeft)
}

#Preview("Themed Calculator") {
    ThemedCalculatorView(
        displayColor: .cyan,
        backgroundColor: Color(red: 0.1, green: 0.1, blue: 0.2)
    )
}
