// SPDX-License-Identifier: GPL-3.0-only
// CalculatorViewModel.swift
// C47 Calculator for iOS - Main ViewModel

import Foundation
import Combine
import SwiftUI

/// Main view model for the C47 calculator
/// Manages calculator state and user interactions
@MainActor
final class CalculatorViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Current display string
    @Published private(set) var display: String = "0"

    /// Stack register strings
    @Published private(set) var stackX: String = "0"
    @Published private(set) var stackY: String = "0"
    @Published private(set) var stackZ: String = "0"
    @Published private(set) var stackT: String = "0"

    /// LastX register string
    @Published private(set) var lastXString: String = "0"

    /// Current angle mode
    @Published private(set) var angleMode: AngleMode = .degrees

    /// Shift key states
    @Published private(set) var isShiftFActive: Bool = false
    @Published private(set) var isShiftGActive: Bool = false
    @Published private(set) var isAlphaActive: Bool = false

    /// Error state
    @Published private(set) var errorMessage: String?
    @Published private(set) var hasError: Bool = false

    /// Whether calculator is in number entry mode
    @Published private(set) var isEnteringNumber: Bool = false

    // MARK: - Private Properties

    /// The calculator engine
    private let engine: C47Engine

    /// Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()

    /// File URL for state persistence
    private var stateFileURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("c47_state.dat")
    }

    // MARK: - Initialization

    init(engine: C47Engine = .shared) {
        self.engine = engine

        // Load saved state if available
        loadSavedState()

        // Update initial state
        updateState()
    }

    // MARK: - Public Methods

    /// Process a key press
    /// - Parameter key: The key that was pressed
    func pressKey(_ key: KeyCode) {
        // Clear error on any key press
        if hasError {
            engine.clearError()
        }

        // Press the key
        engine.pressKey(key)

        // Update state
        updateState()

        // Provide haptic feedback
        provideHapticFeedback(for: key)
    }

    /// Toggle shift F key
    func toggleShiftF() {
        pressKey(.shiftF)
    }

    /// Toggle shift G key
    func toggleShiftG() {
        pressKey(.shiftG)
    }

    /// Toggle alpha mode
    func toggleAlpha() {
        pressKey(.alpha)
    }

    /// Cycle through angle modes
    func cycleAngleMode() {
        engine.cycleAngleMode()
        updateState()
    }

    /// Set angle mode directly
    /// - Parameter mode: The angle mode to set
    func setAngleMode(_ mode: AngleMode) {
        engine.setAngleMode(mode)
        updateState()
    }

    /// Reset the calculator
    func reset() {
        engine.reset()
        updateState()
    }

    /// Clear the current entry/display
    func clear() {
        pressKey(.clear)
    }

    /// Clear just the X register
    func clearX() {
        pressKey(.clx)
    }

    /// Clear all memory registers
    func clearAllRegisters() {
        engine.clearAllRegisters()
        updateState()
    }

    // MARK: - Stack Operations

    /// Swap X and Y registers
    func swap() {
        pressKey(.swap)
    }

    /// Roll stack down
    func rollDown() {
        pressKey(.rollDown)
    }

    /// Roll stack up
    func rollUp() {
        pressKey(.rollUp)
    }

    /// Recall LastX
    func recallLastX() {
        pressKey(.lastX)
    }

    // MARK: - State Persistence

    /// Save the current state
    func saveState() {
        guard let url = stateFileURL else { return }

        Task.detached { [weak self] in
            guard let self = self else { return }
            await MainActor.run {
                self.engine.saveState(to: url)
            }
        }
    }

    /// Load saved state
    func loadSavedState() {
        guard let url = stateFileURL,
              FileManager.default.fileExists(atPath: url.path) else {
            return
        }

        engine.loadState(from: url)
        updateState()
    }

    // MARK: - Private Methods

    /// Update the view model state from the engine
    private func updateState() {
        let state = engine.getState()

        display = state.display
        stackX = state.stackXString
        stackY = state.stackYString
        stackZ = state.stackZString
        stackT = state.stackTString
        lastXString = state.lastXString
        angleMode = state.angleMode
        isShiftFActive = state.isShiftFActive
        isShiftGActive = state.isShiftGActive
        isAlphaActive = state.isAlphaActive
        hasError = state.hasError
        errorMessage = state.errorMessage
    }

    /// Provide haptic feedback for a key press
    private func provideHapticFeedback(for key: KeyCode) {
        #if os(iOS)
        let generator: UIImpactFeedbackGenerator

        switch key {
        case .enter:
            generator = UIImpactFeedbackGenerator(style: .medium)
        case .plus, .minus, .multiply, .divide, .power:
            generator = UIImpactFeedbackGenerator(style: .light)
        case .clear:
            generator = UIImpactFeedbackGenerator(style: .heavy)
        default:
            generator = UIImpactFeedbackGenerator(style: .light)
        }

        generator.prepare()
        generator.impactOccurred()
        #endif
    }
}

// MARK: - Key Input Helpers

extension CalculatorViewModel {
    /// Enter a digit
    func enterDigit(_ digit: Int) {
        guard digit >= 0 && digit <= 9 else { return }
        let key = KeyCode(rawValue: Int32(digit)) ?? .digit0
        pressKey(key)
    }

    /// Enter a decimal point
    func enterDecimal() {
        pressKey(.dot)
    }

    /// Change sign
    func changeSign() {
        pressKey(.chs)
    }

    /// Enter exponent
    func enterExponent() {
        pressKey(.eex)
    }

    /// Press enter
    func enter() {
        pressKey(.enter)
    }

    /// Press backspace
    func backspace() {
        pressKey(.backspace)
    }
}

// MARK: - Arithmetic Operations

extension CalculatorViewModel {
    func add() { pressKey(.plus) }
    func subtract() { pressKey(.minus) }
    func multiply() { pressKey(.multiply) }
    func divide() { pressKey(.divide) }
    func power() { pressKey(.power) }
    func percent() { pressKey(.percent) }
}

// MARK: - Scientific Functions

extension CalculatorViewModel {
    func squareRoot() { pressKey(.sqrt) }
    func square() { pressKey(.square) }
    func reciprocal() { pressKey(.reciprocal) }

    func sin() { pressKey(.sin) }
    func cos() { pressKey(.cos) }
    func tan() { pressKey(.tan) }
    func asin() { pressKey(.asin) }
    func acos() { pressKey(.acos) }
    func atan() { pressKey(.atan) }

    func ln() { pressKey(.ln) }
    func log() { pressKey(.log) }
    func exp() { pressKey(.exp) }
    func pow10() { pressKey(.pow10) }

    func sinh() { pressKey(.sinh) }
    func cosh() { pressKey(.cosh) }
    func tanh() { pressKey(.tanh) }

    func abs() { pressKey(.abs) }
    func intPart() { pressKey(.int) }
    func fracPart() { pressKey(.frac) }
    func factorial() { pressKey(.factorial) }

    func pi() { pressKey(.pi) }
    func eulerE() { pressKey(.e) }
}

// MARK: - Scene Phase Handling

extension CalculatorViewModel {
    /// Handle scene becoming inactive
    func sceneWillResignActive() {
        saveState()
    }

    /// Handle scene becoming active
    func sceneDidBecomeActive() {
        // State is already loaded in init
    }
}
