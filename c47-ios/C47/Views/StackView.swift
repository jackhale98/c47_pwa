// SPDX-License-Identifier: GPL-3.0-only
// StackView.swift
// C47 Calculator for iOS - Stack Display View

import SwiftUI

/// A view showing the complete RPN stack
struct StackView: View {
    @ObservedObject var viewModel: CalculatorViewModel

    /// Whether the view is expanded to show all registers
    @State private var isExpanded: Bool = true

    /// Animation for stack operations
    @State private var stackAnimation: StackAnimation = .none

    var body: some View {
        VStack(spacing: 0) {
            // Header
            stackHeader

            // Stack registers
            VStack(spacing: 2) {
                if isExpanded {
                    StackRegisterRow(
                        label: "T",
                        value: viewModel.stackT,
                        animation: stackAnimation == .rollUp ? .push : (stackAnimation == .rollDown ? .pull : .none)
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))

                    StackRegisterRow(
                        label: "Z",
                        value: viewModel.stackZ,
                        animation: stackAnimation == .lift ? .push : .none
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                StackRegisterRow(
                    label: "Y",
                    value: viewModel.stackY,
                    animation: stackAnimation == .lift ? .push : (stackAnimation == .drop ? .pull : .none)
                )

                StackRegisterRow(
                    label: "X",
                    value: viewModel.display,
                    isMainRegister: true,
                    animation: .none
                )
            }
            .animation(.easeInOut(duration: 0.2), value: isExpanded)

            // LastX display
            if isExpanded {
                Divider()
                    .background(C47Theme.keyBorder)
                    .padding(.vertical, 4)

                HStack {
                    Text("LastX:")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(C47Theme.displayGreenDim)

                    Spacer()

                    Text(viewModel.lastXString)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(C47Theme.displayGreenDim)
                        .lineLimit(1)
                }
                .padding(.horizontal, 8)
                .onTapGesture {
                    viewModel.recallLastX()
                }
            }
        }
        .padding(8)
        .background(C47Theme.screenColor)
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(C47Theme.behindScreen, lineWidth: 2)
        )
    }

    // MARK: - Header

    private var stackHeader: some View {
        HStack {
            Text("STACK")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(C47Theme.displayGreenDim)

            Spacer()

            // Expand/collapse button
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 10))
                    .foregroundColor(C47Theme.displayGreenDim)
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 4)
    }
}

// MARK: - Stack Register Row

struct StackRegisterRow: View {
    let label: String
    let value: String
    var isMainRegister: Bool = false
    var animation: RegisterAnimation = .none

    @State private var offset: CGFloat = 0

    var body: some View {
        HStack(spacing: 4) {
            // Register label
            Text("\(label):")
                .font(.system(size: isMainRegister ? 14 : 11, weight: .medium, design: .monospaced))
                .foregroundColor(isMainRegister ? C47Theme.displayGreen.opacity(0.8) : C47Theme.displayGreen.opacity(0.5))
                .frame(width: 20, alignment: .leading)

            Spacer()

            // Register value
            Text(value)
                .font(.system(size: isMainRegister ? 24 : 14, weight: isMainRegister ? .bold : .regular, design: .monospaced))
                .foregroundColor(isMainRegister ? C47Theme.displayGreen : C47Theme.displayGreen.opacity(0.7))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .offset(y: offset)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, isMainRegister ? 4 : 2)
        .background(isMainRegister ? C47Theme.screenColor.opacity(0.5) : Color.clear)
        .cornerRadius(4)
        .onChange(of: animation) { _, newValue in
            animateRegister(newValue)
        }
    }

    private func animateRegister(_ anim: RegisterAnimation) {
        guard anim != .none else { return }

        withAnimation(.easeOut(duration: 0.1)) {
            offset = anim == .push ? -10 : 10
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeIn(duration: 0.1)) {
                offset = 0
            }
        }
    }
}

// MARK: - Stack Animation Enum

enum StackAnimation {
    case none
    case lift
    case drop
    case rollUp
    case rollDown
    case swap
}

enum RegisterAnimation {
    case none
    case push
    case pull
}

// MARK: - Horizontal Stack View (for landscape)

struct HorizontalStackView: View {
    @ObservedObject var viewModel: CalculatorViewModel

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .trailing, spacing: 2) {
                Text("T: \(viewModel.stackT)")
                Text("Z: \(viewModel.stackZ)")
            }
            .font(.system(size: 11, design: .monospaced))
            .foregroundColor(C47Theme.displayGreen.opacity(0.5))

            VStack(alignment: .trailing, spacing: 2) {
                Text("Y: \(viewModel.stackY)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(C47Theme.displayGreen.opacity(0.6))

                Text("X: \(viewModel.display)")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(C47Theme.displayGreen)
            }
        }
        .padding(8)
        .background(C47Theme.screenColor)
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(C47Theme.behindScreen, lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview("Stack View") {
    VStack {
        StackView(viewModel: CalculatorViewModel())
            .frame(width: 300)

        Spacer()

        HorizontalStackView(viewModel: CalculatorViewModel())
    }
    .padding()
    .background(C47Theme.bezelBackground)
}
