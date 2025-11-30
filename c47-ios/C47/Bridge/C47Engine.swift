// SPDX-License-Identifier: GPL-3.0-only
// C47Engine.swift
// C47 Calculator for iOS - Swift Wrapper for C47 Engine

import Foundation

/// Thread-safe Swift wrapper for the C47 calculator engine
/// This class provides a Swift-friendly interface to the C47 core engine
final class C47Engine {

    // MARK: - Singleton

    /// Shared instance of the calculator engine
    static let shared = C47Engine()

    // MARK: - Private Properties

    /// Serial queue for thread-safe access to the engine
    private let engineQueue = DispatchQueue(label: "com.c47.engine", qos: .userInteractive)

    /// Whether the engine has been initialized
    private var isInitialized = false

    // MARK: - Initialization

    private init() {
        // Initialize the C engine
        _ = initialize()
    }

    deinit {
        shutdown()
    }

    // MARK: - Public Methods

    /// Initialize the calculator engine
    /// - Returns: true if initialization successful
    @discardableResult
    func initialize() -> Bool {
        engineQueue.sync {
            guard !isInitialized else { return true }
            let result = c47_ios_init()
            isInitialized = result
            return result
        }
    }

    /// Reset the calculator to initial state
    func reset() {
        engineQueue.sync {
            c47_ios_reset()
        }
    }

    /// Shutdown the calculator engine
    func shutdown() {
        engineQueue.sync {
            guard isInitialized else { return }
            c47_ios_shutdown()
            isInitialized = false
        }
    }

    // MARK: - Key Input

    /// Process a key press
    /// - Parameter key: The key code to process
    func pressKey(_ key: KeyCode) {
        engineQueue.sync {
            c47_ios_key_press(key.rawValue)
        }
    }

    /// Process a key press using raw key code
    /// - Parameter keyCode: Raw key code value
    func pressKey(rawCode keyCode: Int32) {
        engineQueue.sync {
            c47_ios_key_press(keyCode)
        }
    }

    /// Process a key release
    /// - Parameter key: The key code being released
    func releaseKey(_ key: KeyCode) {
        engineQueue.sync {
            c47_ios_key_release(key.rawValue)
        }
    }

    // MARK: - Display & State

    /// Get the current display string
    /// - Returns: The display string
    func getDisplay() -> String {
        engineQueue.sync {
            guard let cString = c47_ios_get_display() else {
                return "0"
            }
            return String(cString: cString)
        }
    }

    /// Get the X register as a string
    /// - Returns: X register string
    func getXString() -> String {
        engineQueue.sync {
            guard let cString = c47_ios_get_x_string() else {
                return "0"
            }
            return String(cString: cString)
        }
    }

    /// Get all stack register values
    /// - Returns: Tuple containing (X, Y, Z, T) values
    func getStack() -> (x: Double, y: Double, z: Double, t: Double) {
        engineQueue.sync {
            var x: Double = 0, y: Double = 0, z: Double = 0, t: Double = 0
            c47_ios_get_stack(&x, &y, &z, &t)
            return (x, y, z, t)
        }
    }

    /// Get the LastX register value
    /// - Returns: LastX value
    func getLastX() -> Double {
        engineQueue.sync {
            c47_ios_get_lastx()
        }
    }

    /// Get stack values as formatted strings
    /// - Returns: Tuple containing (X, Y, Z, T) strings
    func getStackStrings() -> (x: String, y: String, z: String, t: String) {
        engineQueue.sync {
            var xBuf = [CChar](repeating: 0, count: 64)
            var yBuf = [CChar](repeating: 0, count: 64)
            var zBuf = [CChar](repeating: 0, count: 64)
            var tBuf = [CChar](repeating: 0, count: 64)

            c47_ios_get_stack_strings(&xBuf, &yBuf, &zBuf, &tBuf)

            return (
                String(cString: xBuf),
                String(cString: yBuf),
                String(cString: zBuf),
                String(cString: tBuf)
            )
        }
    }

    /// Get the complete calculator state
    /// - Returns: CalculatorState struct with all current values
    func getState() -> CalculatorState {
        engineQueue.sync {
            let display = String(cString: c47_ios_get_display() ?? "0")
            let stack = self.getStackSync()
            let lastX = c47_ios_get_lastx()
            let angleMode = AngleMode(fromC47Mode: c47_ios_get_angle_mode())
            let errorCode = Int(c47_ios_get_error_code())

            var errorMessage: String? = nil
            if errorCode != 0, let msg = c47_ios_get_error_message(Int32(errorCode)) {
                errorMessage = String(cString: msg)
            }

            return CalculatorState(
                display: display,
                stackX: stack.x,
                stackY: stack.y,
                stackZ: stack.z,
                stackT: stack.t,
                lastX: lastX,
                angleMode: angleMode,
                isShiftFActive: c47_ios_is_shift_f_active(),
                isShiftGActive: c47_ios_is_shift_g_active(),
                isAlphaActive: c47_ios_is_alpha_active(),
                errorCode: errorCode,
                errorMessage: errorMessage
            )
        }
    }

    // Private sync version without queue (called from within queue context)
    private func getStackSync() -> (x: Double, y: Double, z: Double, t: Double) {
        var x: Double = 0, y: Double = 0, z: Double = 0, t: Double = 0
        c47_ios_get_stack(&x, &y, &z, &t)
        return (x, y, z, t)
    }

    // MARK: - Angle Mode

    /// Get the current angle mode
    /// - Returns: Current AngleMode
    func getAngleMode() -> AngleMode {
        engineQueue.sync {
            AngleMode(fromC47Mode: c47_ios_get_angle_mode())
        }
    }

    /// Set the angle mode
    /// - Parameter mode: The angle mode to set
    func setAngleMode(_ mode: AngleMode) {
        engineQueue.sync {
            c47_ios_set_angle_mode(mode.c47Mode)
        }
    }

    /// Cycle to the next angle mode
    func cycleAngleMode() {
        let current = getAngleMode()
        setAngleMode(current.next())
    }

    // MARK: - Shift States

    /// Check if shift F is active
    var isShiftFActive: Bool {
        engineQueue.sync {
            c47_ios_is_shift_f_active()
        }
    }

    /// Check if shift G is active
    var isShiftGActive: Bool {
        engineQueue.sync {
            c47_ios_is_shift_g_active()
        }
    }

    /// Check if alpha mode is active
    var isAlphaActive: Bool {
        engineQueue.sync {
            c47_ios_is_alpha_active()
        }
    }

    // MARK: - Calculator Flags

    /// Get all calculator flags as a bitmask
    /// - Returns: Flags bitmask
    func getFlags() -> UInt32 {
        engineQueue.sync {
            c47_ios_get_flags()
        }
    }

    // MARK: - Memory Operations

    /// Store a value in a memory register
    /// - Parameters:
    ///   - value: The value to store
    ///   - register: The register number (0-99)
    func store(_ value: Double, inRegister register: Int) {
        guard register >= 0 && register < 100 else { return }
        engineQueue.sync {
            c47_ios_store_memory(Int32(register), value)
        }
    }

    /// Recall a value from a memory register
    /// - Parameter register: The register number (0-99)
    /// - Returns: The value in the register
    func recall(fromRegister register: Int) -> Double {
        guard register >= 0 && register < 100 else { return 0.0 }
        return engineQueue.sync {
            c47_ios_recall_memory(Int32(register))
        }
    }

    /// Clear all memory registers
    func clearMemory() {
        engineQueue.sync {
            c47_ios_clear_memory()
        }
    }

    /// Clear all registers (stack and memory) - convenience alias
    func clearAllRegisters() {
        engineQueue.sync {
            c47_ios_clear_memory()
            c47_ios_reset()
        }
    }

    // MARK: - State Persistence

    /// Save calculator state to a file
    /// - Parameter url: File URL to save to
    /// - Returns: true if save successful
    @discardableResult
    func saveState(to url: URL) -> Bool {
        engineQueue.sync {
            c47_ios_save_state(url.path)
        }
    }

    /// Load calculator state from a file
    /// - Parameter url: File URL to load from
    /// - Returns: true if load successful
    @discardableResult
    func loadState(from url: URL) -> Bool {
        engineQueue.sync {
            c47_ios_load_state(url.path)
        }
    }

    /// Get state as Data for serialization
    /// - Returns: Data containing state, or nil on error
    func getStateData() -> Data? {
        engineQueue.sync {
            // First call to get required size
            let requiredSize = c47_ios_get_state_buffer(nil, 0)
            guard requiredSize > 0 else { return nil }

            var buffer = [UInt8](repeating: 0, count: Int(requiredSize))
            let written = c47_ios_get_state_buffer(&buffer, Int32(buffer.count))
            guard written > 0 else { return nil }

            return Data(buffer[0..<Int(written)])
        }
    }

    /// Restore state from Data
    /// - Parameter data: Data containing state
    /// - Returns: true if restore successful
    @discardableResult
    func setStateData(_ data: Data) -> Bool {
        engineQueue.sync {
            data.withUnsafeBytes { buffer -> Bool in
                guard let ptr = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                    return false
                }
                return c47_ios_set_state_buffer(ptr, Int32(data.count))
            }
        }
    }

    // MARK: - Error Handling

    /// Get the last error code
    /// - Returns: Error code (0 = no error)
    func getErrorCode() -> Int {
        engineQueue.sync {
            Int(c47_ios_get_error_code())
        }
    }

    /// Get error message for an error code
    /// - Parameter code: The error code
    /// - Returns: Error message string
    func getErrorMessage(for code: Int) -> String {
        guard let cString = c47_ios_get_error_message(Int32(code)) else {
            return "Unknown error"
        }
        return String(cString: cString)
    }

    /// Get the current error message if there is an error
    /// - Returns: Error message or nil if no error
    func getCurrentError() -> String? {
        let code = getErrorCode()
        guard code != 0 else { return nil }
        return getErrorMessage(for: code)
    }

    /// Clear any error state
    func clearError() {
        engineQueue.sync {
            c47_ios_clear_error()
        }
    }

    /// Check if there is an error
    var hasError: Bool {
        getErrorCode() != 0
    }
}

// MARK: - Convenience Extensions

extension C47Engine {
    /// Enter a number from a string
    /// - Parameter numberString: The number to enter
    func enterNumber(_ numberString: String) {
        for char in numberString {
            switch char {
            case "0": pressKey(.digit0)
            case "1": pressKey(.digit1)
            case "2": pressKey(.digit2)
            case "3": pressKey(.digit3)
            case "4": pressKey(.digit4)
            case "5": pressKey(.digit5)
            case "6": pressKey(.digit6)
            case "7": pressKey(.digit7)
            case "8": pressKey(.digit8)
            case "9": pressKey(.digit9)
            case ".", ",": pressKey(.dot)
            case "-": pressKey(.chs)
            case "e", "E": pressKey(.eex)
            default: break
            }
        }
    }

    /// Perform a calculation sequence
    /// - Parameter sequence: Array of key codes to press
    func execute(sequence: [KeyCode]) {
        for key in sequence {
            pressKey(key)
        }
    }
}
