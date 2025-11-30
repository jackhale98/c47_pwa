// SPDX-License-Identifier: GPL-3.0-only
// SettingsView.swift
// C47 Calculator for iOS - Native iOS Settings

import SwiftUI

/// Native iOS Settings screen using standard iOS UI patterns
struct SettingsView: View {
    @ObservedObject var viewModel: CalculatorViewModel
    @Environment(\.dismiss) private var dismiss

    /// Haptic feedback setting
    @AppStorage("hapticFeedback") private var hapticFeedback: Bool = true

    /// Sound effects setting
    @AppStorage("soundEffects") private var soundEffects: Bool = false

    /// Display precision (number of decimal places)
    @AppStorage("displayPrecision") private var displayPrecision: Int = 10

    /// Stack lift behavior
    @AppStorage("autoStackLift") private var autoStackLift: Bool = true

    var body: some View {
        NavigationView {
            Form {
                // MARK: - Angle Mode Section
                Section {
                    Picker("Angle Mode", selection: Binding(
                        get: { viewModel.angleMode },
                        set: { viewModel.setAngleMode($0) }
                    )) {
                        Text("Degrees").tag(AngleMode.degrees)
                        Text("Radians").tag(AngleMode.radians)
                        Text("Gradians").tag(AngleMode.gradians)
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Calculator Mode")
                } footer: {
                    Text("Choose the angle unit for trigonometric functions.")
                }

                // MARK: - Display Section
                Section {
                    Stepper("Precision: \(displayPrecision) digits", value: $displayPrecision, in: 2...15)
                } header: {
                    Text("Display")
                } footer: {
                    Text("Number of significant digits to display.")
                }

                // MARK: - Behavior Section
                Section {
                    Toggle("Auto Stack Lift", isOn: $autoStackLift)
                } header: {
                    Text("Stack Behavior")
                } footer: {
                    Text("Automatically lift stack when entering new values after a calculation.")
                }

                // MARK: - Feedback Section
                Section {
                    Toggle("Haptic Feedback", isOn: $hapticFeedback)
                    Toggle("Sound Effects", isOn: $soundEffects)
                } header: {
                    Text("Feedback")
                } footer: {
                    Text("Enable tactile and audio feedback on button presses.")
                }

                // MARK: - Actions Section
                Section {
                    Button(role: .destructive) {
                        viewModel.reset()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset Calculator")
                        }
                    }

                    Button(role: .destructive) {
                        viewModel.clearAllRegisters()
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear All Registers")
                        }
                    }
                } header: {
                    Text("Actions")
                }

                // MARK: - About Section
                Section {
                    NavigationLink {
                        AboutView()
                    } label: {
                        HStack {
                            Image(systemName: "info.circle")
                            Text("About C47 Calculator")
                        }
                    }

                    NavigationLink {
                        HelpView()
                    } label: {
                        HStack {
                            Image(systemName: "questionmark.circle")
                            Text("Help & Documentation")
                        }
                    }

                    Link(destination: URL(string: "https://47calc.com/")!) {
                        HStack {
                            Image(systemName: "globe")
                            Text("C47 Project Website")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Information")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - About View

struct AboutView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    // App icon placeholder
                    Image(systemName: "function")
                        .font(.system(size: 60))
                        .foregroundColor(C47Theme.fGold)
                        .frame(width: 100, height: 100)
                        .background(C47Theme.keyBackground)
                        .cornerRadius(20)

                    Text("C47 Calculator")
                        .font(.title2.bold())

                    Text("Version 1.0")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }

            Section {
                Text("C47 Calculator is an advanced RPN (Reverse Polish Notation) scientific calculator based on the open-source C47 project.")
                    .font(.body)
            } header: {
                Text("Description")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    FeatureRow(icon: "square.stack.3d.up", text: "4-level RPN stack (X, Y, Z, T)")
                    FeatureRow(icon: "function", text: "Scientific functions (trig, log, exp)")
                    FeatureRow(icon: "angle", text: "Degrees, radians, gradians")
                    FeatureRow(icon: "memorychip", text: "100 storage registers")
                    FeatureRow(icon: "arrow.clockwise", text: "Automatic state persistence")
                }
            } header: {
                Text("Features")
            }

            Section {
                Link("C47 Project Website", destination: URL(string: "https://47calc.com/")!)
                Link("C47 Wiki Documentation", destination: URL(string: "https://c47.miraheze.org/wiki/Main_Page")!)
                Link("Source Code (GitLab)", destination: URL(string: "https://gitlab.com/rpncalculators/c43")!)
            } header: {
                Text("Resources")
            }

            Section {
                Text("© 2024 The WP43 and C47 Authors")
                Text("Licensed under GPL-3.0")
            } header: {
                Text("License")
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundColor(C47Theme.gBlue)
            Text(text)
        }
    }
}

// MARK: - Help View

struct HelpView: View {
    var body: some View {
        List {
            Section {
                Text("C47 uses Reverse Polish Notation (RPN), where operators follow their operands. Instead of typing \"2 + 3 =\", you enter \"2 ENTER 3 +\".")
            } header: {
                Text("RPN Basics")
            }

            Section {
                HelpItem(
                    title: "Enter a Number",
                    description: "Type digits, then press ENTER to push onto the stack."
                )
                HelpItem(
                    title: "Perform Operations",
                    description: "Enter operands first, then press the operator key (+, −, ×, ÷)."
                )
                HelpItem(
                    title: "Example: 5 + 3",
                    description: "Press: 5 → ENTER → 3 → +"
                )
            } header: {
                Text("Basic Operations")
            }

            Section {
                HelpItem(
                    title: "X ⇄ Y (Swap)",
                    description: "Exchanges the X and Y registers."
                )
                HelpItem(
                    title: "R↓ (Roll Down)",
                    description: "Rolls the stack down: T→Z→Y→X→T"
                )
                HelpItem(
                    title: "LASTx",
                    description: "Recalls the last X value before the previous operation."
                )
                HelpItem(
                    title: "CLx",
                    description: "Clears only the X register."
                )
            } header: {
                Text("Stack Operations")
            }

            Section {
                HelpItem(
                    title: "f (Gold Shift)",
                    description: "Access functions printed in gold above the keys."
                )
                HelpItem(
                    title: "g (Blue Shift)",
                    description: "Access functions printed in blue below the keys."
                )
            } header: {
                Text("Shift Keys")
            }

            Section {
                HelpItem(
                    title: "STO n",
                    description: "Store X register to memory register n (0-99)."
                )
                HelpItem(
                    title: "RCL n",
                    description: "Recall memory register n to X register."
                )
            } header: {
                Text("Memory Operations")
            }
        }
        .navigationTitle("Help")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Help Item

struct HelpItem: View {
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview("Settings") {
    SettingsView(viewModel: CalculatorViewModel())
}

#Preview("About") {
    NavigationView {
        AboutView()
    }
}

#Preview("Help") {
    NavigationView {
        HelpView()
    }
}
