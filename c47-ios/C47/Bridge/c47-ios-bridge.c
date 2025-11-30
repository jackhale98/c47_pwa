// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors
// iOS Bridge Layer Implementation for C47 Calculator Engine

#include "c47-ios-bridge.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <pthread.h>

// ============================================================================
// Internal State
// ============================================================================

// Thread safety mutex
static pthread_mutex_t engine_mutex = PTHREAD_MUTEX_INITIALIZER;

// RPN Stack (X, Y, Z, T registers)
static double stack[4] = {0.0, 0.0, 0.0, 0.0};
#define STACK_X 0
#define STACK_Y 1
#define STACK_Z 2
#define STACK_T 3

// LastX register
static double lastX = 0.0;

// Memory registers (100 storage registers)
static double memory[100] = {0};

// Display buffer
static char display_buffer[256] = "0";
static char stack_buffers[4][64] = {"0", "0", "0", "0"};

// Calculator state
static C47AngleMode angle_mode = C47_ANGLE_DEGREES;
static bool shift_f_active = false;
static bool shift_g_active = false;
static bool alpha_active = false;
static bool stack_lift_enabled = true;
static bool entering_number = false;
static bool decimal_entered = false;
static int exponent_entry = 0;
static int last_error = 0;
static bool initialized = false;

// Number entry buffer
static char entry_buffer[64] = "";
static int entry_length = 0;

// ============================================================================
// Internal Helper Functions
// ============================================================================

static void lock_engine(void) {
    pthread_mutex_lock(&engine_mutex);
}

static void unlock_engine(void) {
    pthread_mutex_unlock(&engine_mutex);
}

static double deg_to_rad(double deg) {
    return deg * M_PI / 180.0;
}

static double rad_to_deg(double rad) {
    return rad * 180.0 / M_PI;
}

static double grad_to_rad(double grad) {
    return grad * M_PI / 200.0;
}

static double rad_to_grad(double rad) {
    return rad * 200.0 / M_PI;
}

static double to_radians(double value) {
    switch (angle_mode) {
        case C47_ANGLE_DEGREES:
            return deg_to_rad(value);
        case C47_ANGLE_GRADIANS:
            return grad_to_rad(value);
        case C47_ANGLE_RADIANS:
        default:
            return value;
    }
}

static double from_radians(double value) {
    switch (angle_mode) {
        case C47_ANGLE_DEGREES:
            return rad_to_deg(value);
        case C47_ANGLE_GRADIANS:
            return rad_to_grad(value);
        case C47_ANGLE_RADIANS:
        default:
            return value;
    }
}

static void lift_stack(void) {
    if (stack_lift_enabled) {
        stack[STACK_T] = stack[STACK_Z];
        stack[STACK_Z] = stack[STACK_Y];
        stack[STACK_Y] = stack[STACK_X];
    }
}

static void drop_stack(void) {
    lastX = stack[STACK_X];
    stack[STACK_X] = stack[STACK_Y];
    stack[STACK_Y] = stack[STACK_Z];
    stack[STACK_Z] = stack[STACK_T];
    // T register duplicates itself (authentic HP behavior)
}

static void update_display(void) {
    if (entering_number) {
        strncpy(display_buffer, entry_buffer, sizeof(display_buffer) - 1);
        display_buffer[sizeof(display_buffer) - 1] = '\0';
    } else {
        double value = stack[STACK_X];
        if (isnan(value)) {
            strcpy(display_buffer, "NaN");
        } else if (isinf(value)) {
            strcpy(display_buffer, value > 0 ? "Infinity" : "-Infinity");
        } else if (value == floor(value) && fabs(value) < 1e12) {
            snprintf(display_buffer, sizeof(display_buffer), "%.0f", value);
        } else {
            snprintf(display_buffer, sizeof(display_buffer), "%.10g", value);
        }
    }

    // Update stack string buffers
    for (int i = 0; i < 4; i++) {
        double val = stack[i];
        if (isnan(val)) {
            strcpy(stack_buffers[i], "NaN");
        } else if (isinf(val)) {
            strcpy(stack_buffers[i], val > 0 ? "Infinity" : "-Infinity");
        } else if (val == floor(val) && fabs(val) < 1e12) {
            snprintf(stack_buffers[i], sizeof(stack_buffers[i]), "%.0f", val);
        } else {
            snprintf(stack_buffers[i], sizeof(stack_buffers[i]), "%.10g", val);
        }
    }
}

static void finalize_entry(void) {
    if (entering_number && entry_length > 0) {
        stack[STACK_X] = atof(entry_buffer);
    }
    entering_number = false;
    decimal_entered = false;
    exponent_entry = 0;
    entry_length = 0;
    entry_buffer[0] = '\0';
    stack_lift_enabled = true;
}

static void start_new_entry(void) {
    lift_stack();
    stack[STACK_X] = 0.0;
    entering_number = true;
    decimal_entered = false;
    exponent_entry = 0;
    entry_length = 0;
    entry_buffer[0] = '\0';
    stack_lift_enabled = false;
}

// ============================================================================
// Public API Implementation
// ============================================================================

bool c47_ios_init(void) {
    lock_engine();

    // Reset all state
    for (int i = 0; i < 4; i++) {
        stack[i] = 0.0;
    }
    lastX = 0.0;
    memset(memory, 0, sizeof(memory));

    angle_mode = C47_ANGLE_DEGREES;
    shift_f_active = false;
    shift_g_active = false;
    alpha_active = false;
    stack_lift_enabled = true;
    entering_number = false;
    decimal_entered = false;
    exponent_entry = 0;
    last_error = 0;
    entry_length = 0;
    entry_buffer[0] = '\0';

    update_display();
    initialized = true;

    unlock_engine();
    return true;
}

void c47_ios_reset(void) {
    c47_ios_init();
}

void c47_ios_shutdown(void) {
    lock_engine();
    initialized = false;
    unlock_engine();
}

void c47_ios_key_press(int key_code) {
    lock_engine();

    if (!initialized) {
        unlock_engine();
        return;
    }

    last_error = 0;

    switch (key_code) {
        // Digit keys
        case C47_KEY_0:
        case C47_KEY_1:
        case C47_KEY_2:
        case C47_KEY_3:
        case C47_KEY_4:
        case C47_KEY_5:
        case C47_KEY_6:
        case C47_KEY_7:
        case C47_KEY_8:
        case C47_KEY_9: {
            if (!entering_number) {
                start_new_entry();
            }
            if (entry_length < sizeof(entry_buffer) - 1) {
                entry_buffer[entry_length++] = '0' + key_code;
                entry_buffer[entry_length] = '\0';
            }
            break;
        }

        case C47_KEY_DOT: {
            if (!entering_number) {
                start_new_entry();
                entry_buffer[entry_length++] = '0';
            }
            if (!decimal_entered && exponent_entry == 0) {
                decimal_entered = true;
                if (entry_length < sizeof(entry_buffer) - 1) {
                    entry_buffer[entry_length++] = '.';
                    entry_buffer[entry_length] = '\0';
                }
            }
            break;
        }

        case C47_KEY_CHS: {
            if (entering_number) {
                if (exponent_entry > 0) {
                    // Toggle exponent sign - find 'e' and toggle sign after it
                    char* exp = strchr(entry_buffer, 'e');
                    if (exp && *(exp + 1) == '-') {
                        // Remove minus
                        memmove(exp + 1, exp + 2, strlen(exp + 2) + 1);
                        entry_length--;
                    } else if (exp) {
                        // Add minus
                        memmove(exp + 2, exp + 1, strlen(exp + 1) + 1);
                        *(exp + 1) = '-';
                        entry_length++;
                    }
                } else {
                    // Toggle mantissa sign
                    if (entry_buffer[0] == '-') {
                        memmove(entry_buffer, entry_buffer + 1, entry_length);
                        entry_length--;
                    } else {
                        memmove(entry_buffer + 1, entry_buffer, entry_length + 1);
                        entry_buffer[0] = '-';
                        entry_length++;
                    }
                }
            } else {
                stack[STACK_X] = -stack[STACK_X];
            }
            break;
        }

        case C47_KEY_EEX: {
            if (!entering_number) {
                start_new_entry();
                entry_buffer[entry_length++] = '1';
            }
            if (exponent_entry == 0) {
                if (entry_length < sizeof(entry_buffer) - 3) {
                    entry_buffer[entry_length++] = 'e';
                    entry_buffer[entry_length] = '\0';
                    exponent_entry = 1;
                }
            }
            break;
        }

        case C47_KEY_ENTER: {
            if (entering_number) {
                finalize_entry();
                stack_lift_enabled = false;
            } else {
                lift_stack();
                // X duplicates to Y (already happened in lift)
            }
            stack_lift_enabled = false;
            break;
        }

        case C47_KEY_BACKSPACE: {
            if (entering_number && entry_length > 0) {
                char removed = entry_buffer[--entry_length];
                entry_buffer[entry_length] = '\0';
                if (removed == '.') decimal_entered = false;
                if (removed == 'e') exponent_entry = 0;
                if (entry_length == 0 || (entry_length == 1 && entry_buffer[0] == '-')) {
                    entering_number = false;
                    entry_length = 0;
                    entry_buffer[0] = '\0';
                }
            }
            break;
        }

        // Arithmetic operations
        case C47_KEY_PLUS: {
            finalize_entry();
            lastX = stack[STACK_X];
            double result = stack[STACK_Y] + stack[STACK_X];
            drop_stack();
            stack[STACK_X] = result;
            stack_lift_enabled = true;
            break;
        }

        case C47_KEY_MINUS: {
            finalize_entry();
            lastX = stack[STACK_X];
            double result = stack[STACK_Y] - stack[STACK_X];
            drop_stack();
            stack[STACK_X] = result;
            stack_lift_enabled = true;
            break;
        }

        case C47_KEY_MULTIPLY: {
            finalize_entry();
            lastX = stack[STACK_X];
            double result = stack[STACK_Y] * stack[STACK_X];
            drop_stack();
            stack[STACK_X] = result;
            stack_lift_enabled = true;
            break;
        }

        case C47_KEY_DIVIDE: {
            finalize_entry();
            lastX = stack[STACK_X];
            if (stack[STACK_X] == 0.0) {
                last_error = 1; // Division by zero
                stack[STACK_X] = INFINITY;
            } else {
                double result = stack[STACK_Y] / stack[STACK_X];
                drop_stack();
                stack[STACK_X] = result;
            }
            stack_lift_enabled = true;
            break;
        }

        // Scientific functions
        case C47_KEY_SQRT: {
            finalize_entry();
            lastX = stack[STACK_X];
            if (stack[STACK_X] < 0) {
                last_error = 2; // Negative sqrt
            }
            stack[STACK_X] = sqrt(stack[STACK_X]);
            stack_lift_enabled = true;
            break;
        }

        case C47_KEY_SQUARE: {
            finalize_entry();
            lastX = stack[STACK_X];
            stack[STACK_X] = stack[STACK_X] * stack[STACK_X];
            stack_lift_enabled = true;
            break;
        }

        case C47_KEY_RECIPROCAL: {
            finalize_entry();
            lastX = stack[STACK_X];
            if (stack[STACK_X] == 0.0) {
                last_error = 1;
                stack[STACK_X] = INFINITY;
            } else {
                stack[STACK_X] = 1.0 / stack[STACK_X];
            }
            stack_lift_enabled = true;
            break;
        }

        case C47_KEY_POWER: {
            finalize_entry();
            lastX = stack[STACK_X];
            double result = pow(stack[STACK_Y], stack[STACK_X]);
            drop_stack();
            stack[STACK_X] = result;
            stack_lift_enabled = true;
            break;
        }

        case C47_KEY_PERCENT: {
            finalize_entry();
            lastX = stack[STACK_X];
            stack[STACK_X] = stack[STACK_Y] * stack[STACK_X] / 100.0;
            stack_lift_enabled = true;
            break;
        }

        // Trigonometric functions
        case C47_KEY_SIN: {
            finalize_entry();
            lastX = stack[STACK_X];
            stack[STACK_X] = sin(to_radians(stack[STACK_X]));
            stack_lift_enabled = true;
            break;
        }

        case C47_KEY_COS: {
            finalize_entry();
            lastX = stack[STACK_X];
            stack[STACK_X] = cos(to_radians(stack[STACK_X]));
            stack_lift_enabled = true;
            break;
        }

        case C47_KEY_TAN: {
            finalize_entry();
            lastX = stack[STACK_X];
            stack[STACK_X] = tan(to_radians(stack[STACK_X]));
            stack_lift_enabled = true;
            break;
        }

        case C47_KEY_ASIN: {
            finalize_entry();
            lastX = stack[STACK_X];
            if (fabs(stack[STACK_X]) > 1.0) {
                last_error = 3; // Domain error
            }
            stack[STACK_X] = from_radians(asin(stack[STACK_X]));
            stack_lift_enabled = true;
            break;
        }

        case C47_KEY_ACOS: {
            finalize_entry();
            lastX = stack[STACK_X];
            if (fabs(stack[STACK_X]) > 1.0) {
                last_error = 3;
            }
            stack[STACK_X] = from_radians(acos(stack[STACK_X]));
            stack_lift_enabled = true;
            break;
        }

        case C47_KEY_ATAN: {
            finalize_entry();
            lastX = stack[STACK_X];
            stack[STACK_X] = from_radians(atan(stack[STACK_X]));
            stack_lift_enabled = true;
            break;
        }

        // Hyperbolic functions
        case C47_KEY_SINH: {
            finalize_entry();
            lastX = stack[STACK_X];
            stack[STACK_X] = sinh(stack[STACK_X]);
            stack_lift_enabled = true;
            break;
        }

        case C47_KEY_COSH: {
            finalize_entry();
            lastX = stack[STACK_X];
            stack[STACK_X] = cosh(stack[STACK_X]);
            stack_lift_enabled = true;
            break;
        }

        case C47_KEY_TANH: {
            finalize_entry();
            lastX = stack[STACK_X];
            stack[STACK_X] = tanh(stack[STACK_X]);
            stack_lift_enabled = true;
            break;
        }

        case C47_KEY_ASINH: {
            finalize_entry();
            lastX = stack[STACK_X];
            stack[STACK_X] = asinh(stack[STACK_X]);
            stack_lift_enabled = true;
            break;
        }

        case C47_KEY_ACOSH: {
            finalize_entry();
            lastX = stack[STACK_X];
            if (stack[STACK_X] < 1.0) {
                last_error = 3;
            }
            stack[STACK_X] = acosh(stack[STACK_X]);
            stack_lift_enabled = true;
            break;
        }

        case C47_KEY_ATANH: {
            finalize_entry();
            lastX = stack[STACK_X];
            if (fabs(stack[STACK_X]) >= 1.0) {
                last_error = 3;
            }
            stack[STACK_X] = atanh(stack[STACK_X]);
            stack_lift_enabled = true;
            break;
        }

        // Logarithmic functions
        case C47_KEY_LN: {
            finalize_entry();
            lastX = stack[STACK_X];
            if (stack[STACK_X] <= 0) {
                last_error = 4; // Log of non-positive
            }
            stack[STACK_X] = log(stack[STACK_X]);
            stack_lift_enabled = true;
            break;
        }

        case C47_KEY_LOG: {
            finalize_entry();
            lastX = stack[STACK_X];
            if (stack[STACK_X] <= 0) {
                last_error = 4;
            }
            stack[STACK_X] = log10(stack[STACK_X]);
            stack_lift_enabled = true;
            break;
        }

        case C47_KEY_EXP: {
            finalize_entry();
            lastX = stack[STACK_X];
            stack[STACK_X] = exp(stack[STACK_X]);
            stack_lift_enabled = true;
            break;
        }

        case C47_KEY_POW10: {
            finalize_entry();
            lastX = stack[STACK_X];
            stack[STACK_X] = pow(10.0, stack[STACK_X]);
            stack_lift_enabled = true;
            break;
        }

        // Stack operations
        case C47_KEY_SWAP: {
            finalize_entry();
            double temp = stack[STACK_X];
            stack[STACK_X] = stack[STACK_Y];
            stack[STACK_Y] = temp;
            break;
        }

        case C47_KEY_ROLL_DOWN: {
            finalize_entry();
            double temp = stack[STACK_X];
            stack[STACK_X] = stack[STACK_Y];
            stack[STACK_Y] = stack[STACK_Z];
            stack[STACK_Z] = stack[STACK_T];
            stack[STACK_T] = temp;
            break;
        }

        case C47_KEY_ROLL_UP: {
            finalize_entry();
            double temp = stack[STACK_T];
            stack[STACK_T] = stack[STACK_Z];
            stack[STACK_Z] = stack[STACK_Y];
            stack[STACK_Y] = stack[STACK_X];
            stack[STACK_X] = temp;
            break;
        }

        case C47_KEY_LASTX: {
            finalize_entry();
            lift_stack();
            stack[STACK_X] = lastX;
            stack_lift_enabled = true;
            break;
        }

        case C47_KEY_CLX: {
            entering_number = false;
            entry_length = 0;
            entry_buffer[0] = '\0';
            stack[STACK_X] = 0.0;
            stack_lift_enabled = false;
            break;
        }

        case C47_KEY_CLEAR: {
            entering_number = false;
            entry_length = 0;
            entry_buffer[0] = '\0';
            for (int i = 0; i < 4; i++) {
                stack[i] = 0.0;
            }
            lastX = 0.0;
            stack_lift_enabled = true;
            break;
        }

        // Constants
        case C47_KEY_PI: {
            finalize_entry();
            lift_stack();
            stack[STACK_X] = M_PI;
            stack_lift_enabled = true;
            break;
        }

        case C47_KEY_E: {
            finalize_entry();
            lift_stack();
            stack[STACK_X] = M_E;
            stack_lift_enabled = true;
            break;
        }

        // Shift keys
        case C47_KEY_SHIFT_F: {
            shift_f_active = !shift_f_active;
            shift_g_active = false;
            break;
        }

        case C47_KEY_SHIFT_G: {
            shift_g_active = !shift_g_active;
            shift_f_active = false;
            break;
        }

        case C47_KEY_ALPHA: {
            alpha_active = !alpha_active;
            break;
        }

        // Additional functions
        case C47_KEY_ABS: {
            finalize_entry();
            lastX = stack[STACK_X];
            stack[STACK_X] = fabs(stack[STACK_X]);
            stack_lift_enabled = true;
            break;
        }

        case C47_KEY_INT: {
            finalize_entry();
            lastX = stack[STACK_X];
            stack[STACK_X] = trunc(stack[STACK_X]);
            stack_lift_enabled = true;
            break;
        }

        case C47_KEY_FRAC: {
            finalize_entry();
            lastX = stack[STACK_X];
            stack[STACK_X] = stack[STACK_X] - trunc(stack[STACK_X]);
            stack_lift_enabled = true;
            break;
        }

        case C47_KEY_FACTORIAL: {
            finalize_entry();
            lastX = stack[STACK_X];
            stack[STACK_X] = tgamma(stack[STACK_X] + 1);
            stack_lift_enabled = true;
            break;
        }

        default:
            break;
    }

    // Clear shift state after non-shift key (unless it was a shift key)
    if (key_code != C47_KEY_SHIFT_F && key_code != C47_KEY_SHIFT_G && key_code != C47_KEY_ALPHA) {
        shift_f_active = false;
        shift_g_active = false;
    }

    update_display();
    unlock_engine();
}

void c47_ios_key_release(int key_code) {
    // Currently not used, but available for future features
    (void)key_code;
}

const char* c47_ios_get_display(void) {
    return display_buffer;
}

const char* c47_ios_get_x_string(void) {
    return stack_buffers[STACK_X];
}

void c47_ios_get_stack(double* x, double* y, double* z, double* t) {
    lock_engine();
    if (x) *x = stack[STACK_X];
    if (y) *y = stack[STACK_Y];
    if (z) *z = stack[STACK_Z];
    if (t) *t = stack[STACK_T];
    unlock_engine();
}

double c47_ios_get_lastx(void) {
    return lastX;
}

void c47_ios_get_stack_strings(char* x, char* y, char* z, char* t) {
    lock_engine();
    if (x) strncpy(x, stack_buffers[STACK_X], 63);
    if (y) strncpy(y, stack_buffers[STACK_Y], 63);
    if (z) strncpy(z, stack_buffers[STACK_Z], 63);
    if (t) strncpy(t, stack_buffers[STACK_T], 63);
    unlock_engine();
}

C47AngleMode c47_ios_get_angle_mode(void) {
    return angle_mode;
}

void c47_ios_set_angle_mode(C47AngleMode mode) {
    lock_engine();
    angle_mode = mode;
    unlock_engine();
}

uint32_t c47_ios_get_flags(void) {
    uint32_t flags = 0;
    flags |= (angle_mode & 0x03);
    flags |= (shift_f_active ? 0x04 : 0);
    flags |= (shift_g_active ? 0x08 : 0);
    flags |= (alpha_active ? 0x10 : 0);
    flags |= (stack_lift_enabled ? 0x20 : 0);
    flags |= (entering_number ? 0x40 : 0);
    return flags;
}

bool c47_ios_is_shift_f_active(void) {
    return shift_f_active;
}

bool c47_ios_is_shift_g_active(void) {
    return shift_g_active;
}

bool c47_ios_is_alpha_active(void) {
    return alpha_active;
}

void c47_ios_store_memory(int register_num, double value) {
    if (register_num >= 0 && register_num < 100) {
        lock_engine();
        memory[register_num] = value;
        unlock_engine();
    }
}

double c47_ios_recall_memory(int register_num) {
    if (register_num >= 0 && register_num < 100) {
        return memory[register_num];
    }
    return 0.0;
}

void c47_ios_clear_memory(void) {
    lock_engine();
    memset(memory, 0, sizeof(memory));
    unlock_engine();
}

bool c47_ios_save_state(const char* path) {
    if (!path) return false;

    lock_engine();
    FILE* file = fopen(path, "wb");
    if (!file) {
        unlock_engine();
        return false;
    }

    // Write magic number and version
    uint32_t magic = 0x43343749; // "C47I"
    uint32_t version = 1;
    fwrite(&magic, sizeof(magic), 1, file);
    fwrite(&version, sizeof(version), 1, file);

    // Write state
    fwrite(stack, sizeof(stack), 1, file);
    fwrite(&lastX, sizeof(lastX), 1, file);
    fwrite(memory, sizeof(memory), 1, file);
    fwrite(&angle_mode, sizeof(angle_mode), 1, file);

    fclose(file);
    unlock_engine();
    return true;
}

bool c47_ios_load_state(const char* path) {
    if (!path) return false;

    lock_engine();
    FILE* file = fopen(path, "rb");
    if (!file) {
        unlock_engine();
        return false;
    }

    // Check magic number and version
    uint32_t magic, version;
    if (fread(&magic, sizeof(magic), 1, file) != 1 || magic != 0x43343749) {
        fclose(file);
        unlock_engine();
        return false;
    }
    if (fread(&version, sizeof(version), 1, file) != 1 || version != 1) {
        fclose(file);
        unlock_engine();
        return false;
    }

    // Read state
    fread(stack, sizeof(stack), 1, file);
    fread(&lastX, sizeof(lastX), 1, file);
    fread(memory, sizeof(memory), 1, file);
    fread(&angle_mode, sizeof(angle_mode), 1, file);

    // Reset entry state
    entering_number = false;
    entry_length = 0;
    entry_buffer[0] = '\0';
    shift_f_active = false;
    shift_g_active = false;
    alpha_active = false;
    stack_lift_enabled = true;

    update_display();

    fclose(file);
    unlock_engine();
    return true;
}

int c47_ios_get_state_buffer(uint8_t* buffer, int buffer_size) {
    if (!buffer || buffer_size < 0) return -1;

    lock_engine();

    int required_size = sizeof(uint32_t) * 2 + sizeof(stack) + sizeof(lastX) +
                        sizeof(memory) + sizeof(angle_mode);

    if (buffer_size < required_size) {
        unlock_engine();
        return required_size; // Return required size
    }

    uint8_t* ptr = buffer;

    // Magic and version
    uint32_t magic = 0x43343749;
    uint32_t version = 1;
    memcpy(ptr, &magic, sizeof(magic)); ptr += sizeof(magic);
    memcpy(ptr, &version, sizeof(version)); ptr += sizeof(version);

    // State data
    memcpy(ptr, stack, sizeof(stack)); ptr += sizeof(stack);
    memcpy(ptr, &lastX, sizeof(lastX)); ptr += sizeof(lastX);
    memcpy(ptr, memory, sizeof(memory)); ptr += sizeof(memory);
    memcpy(ptr, &angle_mode, sizeof(angle_mode)); ptr += sizeof(angle_mode);

    unlock_engine();
    return (int)(ptr - buffer);
}

bool c47_ios_set_state_buffer(const uint8_t* buffer, int buffer_size) {
    if (!buffer || buffer_size < (int)(sizeof(uint32_t) * 2)) return false;

    const uint8_t* ptr = buffer;

    // Check magic and version
    uint32_t magic, version;
    memcpy(&magic, ptr, sizeof(magic)); ptr += sizeof(magic);
    memcpy(&version, ptr, sizeof(version)); ptr += sizeof(version);

    if (magic != 0x43343749 || version != 1) return false;

    lock_engine();

    memcpy(stack, ptr, sizeof(stack)); ptr += sizeof(stack);
    memcpy(&lastX, ptr, sizeof(lastX)); ptr += sizeof(lastX);
    memcpy(memory, ptr, sizeof(memory)); ptr += sizeof(memory);
    memcpy(&angle_mode, ptr, sizeof(angle_mode)); ptr += sizeof(angle_mode);

    // Reset entry state
    entering_number = false;
    entry_length = 0;
    entry_buffer[0] = '\0';
    shift_f_active = false;
    shift_g_active = false;
    alpha_active = false;
    stack_lift_enabled = true;

    update_display();

    unlock_engine();
    return true;
}

int c47_ios_get_error_code(void) {
    return last_error;
}

static const char* error_messages[] = {
    "No error",
    "Division by zero",
    "Invalid argument (negative sqrt)",
    "Domain error",
    "Logarithm of non-positive number",
    "Unknown error"
};

const char* c47_ios_get_error_message(int error_code) {
    if (error_code < 0 || error_code > 5) {
        return error_messages[5];
    }
    return error_messages[error_code];
}

void c47_ios_clear_error(void) {
    lock_engine();
    last_error = 0;
    unlock_engine();
}
