// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors
// iOS Bridge Layer for C47 Calculator Engine

#ifndef C47_IOS_BRIDGE_H
#define C47_IOS_BRIDGE_H

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// ============================================================================
// Initialization & Lifecycle
// ============================================================================

/// Initialize the C47 calculator engine
/// @return true if initialization successful, false otherwise
bool c47_ios_init(void);

/// Reset the calculator to initial state
void c47_ios_reset(void);

/// Shutdown and cleanup the calculator engine
void c47_ios_shutdown(void);

// ============================================================================
// Key Input
// ============================================================================

/// Process a key press event
/// @param key_code The key code to process (see KeyCode enum)
void c47_ios_key_press(int key_code);

/// Process a key release event (for shift key handling)
/// @param key_code The key code being released
void c47_ios_key_release(int key_code);

// ============================================================================
// Display & State
// ============================================================================

/// Get the current display string
/// @return Pointer to display string (do not free)
const char* c47_ios_get_display(void);

/// Get the current X register value as a string
/// @return Pointer to X register string (do not free)
const char* c47_ios_get_x_string(void);

/// Get stack register values
/// @param x Pointer to store X register value
/// @param y Pointer to store Y register value
/// @param z Pointer to store Z register value
/// @param t Pointer to store T register value
void c47_ios_get_stack(double* x, double* y, double* z, double* t);

/// Get the LastX register value
/// @return LastX value
double c47_ios_get_lastx(void);

/// Get stack register as formatted strings
/// @param x Buffer for X register string (at least 64 chars)
/// @param y Buffer for Y register string (at least 64 chars)
/// @param z Buffer for Z register string (at least 64 chars)
/// @param t Buffer for T register string (at least 64 chars)
void c47_ios_get_stack_strings(char* x, char* y, char* z, char* t);

// ============================================================================
// Calculator Modes
// ============================================================================

/// Angle mode constants
typedef enum {
    C47_ANGLE_DEGREES = 0,
    C47_ANGLE_RADIANS = 1,
    C47_ANGLE_GRADIANS = 2
} C47AngleMode;

/// Get the current angle mode
/// @return Current angle mode
C47AngleMode c47_ios_get_angle_mode(void);

/// Set the angle mode
/// @param mode The angle mode to set
void c47_ios_set_angle_mode(C47AngleMode mode);

/// Get calculator flags as a bitmask
/// @return Flags bitmask
uint32_t c47_ios_get_flags(void);

/// Check if shift (f) key is active
/// @return true if shift is active
bool c47_ios_is_shift_f_active(void);

/// Check if shift (g) key is active
/// @return true if shift is active
bool c47_ios_is_shift_g_active(void);

/// Check if alpha mode is active
/// @return true if alpha mode is active
bool c47_ios_is_alpha_active(void);

// ============================================================================
// Memory Operations
// ============================================================================

/// Store value in memory register
/// @param register_num Register number (0-99)
/// @param value Value to store
void c47_ios_store_memory(int register_num, double value);

/// Recall value from memory register
/// @param register_num Register number (0-99)
/// @return Value from register
double c47_ios_recall_memory(int register_num);

/// Clear all memory registers
void c47_ios_clear_memory(void);

// ============================================================================
// State Persistence
// ============================================================================

/// Save calculator state to file
/// @param path File path to save state
/// @return true if save successful
bool c47_ios_save_state(const char* path);

/// Load calculator state from file
/// @param path File path to load state from
/// @return true if load successful
bool c47_ios_load_state(const char* path);

/// Get state as a byte buffer for serialization
/// @param buffer Buffer to write state to
/// @param buffer_size Size of buffer
/// @return Number of bytes written, or -1 on error
int c47_ios_get_state_buffer(uint8_t* buffer, int buffer_size);

/// Restore state from a byte buffer
/// @param buffer Buffer containing state data
/// @param buffer_size Size of data in buffer
/// @return true if restore successful
bool c47_ios_set_state_buffer(const uint8_t* buffer, int buffer_size);

// ============================================================================
// Error Handling
// ============================================================================

/// Get the last error code
/// @return Error code (0 = no error)
int c47_ios_get_error_code(void);

/// Get error message for error code
/// @param error_code The error code
/// @return Error message string
const char* c47_ios_get_error_message(int error_code);

/// Clear any error state
void c47_ios_clear_error(void);

// ============================================================================
// Key Codes (matching C47 keyboard layout)
// ============================================================================

typedef enum {
    // Digit keys
    C47_KEY_0 = 0,
    C47_KEY_1 = 1,
    C47_KEY_2 = 2,
    C47_KEY_3 = 3,
    C47_KEY_4 = 4,
    C47_KEY_5 = 5,
    C47_KEY_6 = 6,
    C47_KEY_7 = 7,
    C47_KEY_8 = 8,
    C47_KEY_9 = 9,

    // Entry keys
    C47_KEY_DOT = 10,
    C47_KEY_CHS = 11,       // Change sign (+/-)
    C47_KEY_EEX = 12,       // Enter exponent
    C47_KEY_ENTER = 13,
    C47_KEY_BACKSPACE = 14,

    // Basic arithmetic
    C47_KEY_PLUS = 20,
    C47_KEY_MINUS = 21,
    C47_KEY_MULTIPLY = 22,
    C47_KEY_DIVIDE = 23,

    // Scientific functions
    C47_KEY_SQRT = 30,
    C47_KEY_SQUARE = 31,
    C47_KEY_RECIPROCAL = 32,
    C47_KEY_POWER = 33,
    C47_KEY_PERCENT = 34,

    // Trigonometric
    C47_KEY_SIN = 40,
    C47_KEY_COS = 41,
    C47_KEY_TAN = 42,
    C47_KEY_ASIN = 43,
    C47_KEY_ACOS = 44,
    C47_KEY_ATAN = 45,

    // Logarithmic
    C47_KEY_LN = 50,
    C47_KEY_LOG = 51,
    C47_KEY_EXP = 52,
    C47_KEY_POW10 = 53,

    // Stack operations
    C47_KEY_SWAP = 60,      // x<>y
    C47_KEY_ROLL_DOWN = 61,
    C47_KEY_ROLL_UP = 62,
    C47_KEY_LASTX = 63,
    C47_KEY_CLX = 64,
    C47_KEY_CLEAR = 65,

    // Memory
    C47_KEY_STO = 70,
    C47_KEY_RCL = 71,

    // Constants
    C47_KEY_PI = 80,
    C47_KEY_E = 81,

    // Mode/Shift keys
    C47_KEY_SHIFT_F = 90,
    C47_KEY_SHIFT_G = 91,
    C47_KEY_ALPHA = 92,
    C47_KEY_MODE = 93,

    // Statistics
    C47_KEY_SIGMA_PLUS = 100,
    C47_KEY_SIGMA_MINUS = 101,

    // Additional functions
    C47_KEY_ABS = 110,
    C47_KEY_INT = 111,
    C47_KEY_FRAC = 112,
    C47_KEY_FACTORIAL = 113,

    // Hyperbolic
    C47_KEY_SINH = 120,
    C47_KEY_COSH = 121,
    C47_KEY_TANH = 122,
    C47_KEY_ASINH = 123,
    C47_KEY_ACOSH = 124,
    C47_KEY_ATANH = 125

} C47KeyCode;

#ifdef __cplusplus
}
#endif

#endif // C47_IOS_BRIDGE_H
