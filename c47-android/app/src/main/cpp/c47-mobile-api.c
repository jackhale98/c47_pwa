/**
 * C47 Mobile API - C implementation of calculator functions
 * This file provides a mobile-friendly API to the C47 calculator engine
 * 
 * Note: This is a template implementation. The actual functions need to be
 * extracted and adapted from the C43 GitLab repository source code.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <android/log.h>

#define LOG_TAG "C47MobileAPI"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)

// Calculator state structure
typedef struct {
    double stack[4];  // X, Y, Z, T registers
    double memory[10]; // Memory registers 0-9
    char display[32];  // Display buffer
    int flags;         // Calculator flags
    int angle_mode;    // 0=DEG, 1=RAD, 2=GRAD
    int shift_state;   // SHIFT key state
    int alpha_state;   // ALPHA key state
} calculator_state_t;

// Global calculator state
static calculator_state_t calc_state = {0};
static int initialized = 0;

// Forward declarations - these need to be implemented based on C43 source
static void update_display();
static double deg_to_rad(double deg);
static double rad_to_deg(double rad);

/**
 * Initialize the calculator engine
 */
void c47_init() {
    LOGI("Initializing C47 calculator engine");
    
    if (initialized) {
        LOGD("Calculator already initialized");
        return;
    }
    
    // Initialize calculator state
    memset(&calc_state, 0, sizeof(calc_state));
    calc_state.stack[0] = 0.0;  // X register
    calc_state.stack[1] = 0.0;  // Y register
    calc_state.stack[2] = 0.0;  // Z register
    calc_state.stack[3] = 0.0;  // T register
    
    calc_state.angle_mode = 0; // Degrees by default
    strcpy(calc_state.display, "0");
    
    initialized = 1;
    LOGI("Calculator initialized successfully");
}

/**
 * Reset calculator to initial state
 */
void c47_reset() {
    LOGI("Resetting calculator");
    initialized = 0;
    c47_init();
}

/**
 * Process a key press
 */
void c47_key_press(int key_code) {
    LOGD("Processing key: %d", key_code);
    
    if (!initialized) {
        c47_init();
    }
    
    switch (key_code) {
        case 0: case 1: case 2: case 3: case 4:
        case 5: case 6: case 7: case 8: case 9:
            // Number keys
            // TODO: Implement number entry logic from C43 source
            break;
            
        case 10: // Decimal point
            // TODO: Implement decimal point logic
            break;
            
        case 13: // ENTER
            // Push X to Y, Y to Z, Z to T
            calc_state.stack[3] = calc_state.stack[2];
            calc_state.stack[2] = calc_state.stack[1]; 
            calc_state.stack[1] = calc_state.stack[0];
            break;
            
        case 14: // PLUS
            calc_state.stack[0] = calc_state.stack[1] + calc_state.stack[0];
            calc_state.stack[1] = calc_state.stack[2];
            calc_state.stack[2] = calc_state.stack[3];
            calc_state.stack[3] = 0.0;
            break;
            
        case 15: // MINUS
            calc_state.stack[0] = calc_state.stack[1] - calc_state.stack[0];
            calc_state.stack[1] = calc_state.stack[2];
            calc_state.stack[2] = calc_state.stack[3];
            calc_state.stack[3] = 0.0;
            break;
            
        case 16: // MULTIPLY
            calc_state.stack[0] = calc_state.stack[1] * calc_state.stack[0];
            calc_state.stack[1] = calc_state.stack[2];
            calc_state.stack[2] = calc_state.stack[3];
            calc_state.stack[3] = 0.0;
            break;
            
        case 17: // DIVIDE
            if (calc_state.stack[0] != 0.0) {
                calc_state.stack[0] = calc_state.stack[1] / calc_state.stack[0];
                calc_state.stack[1] = calc_state.stack[2];
                calc_state.stack[2] = calc_state.stack[3];
                calc_state.stack[3] = 0.0;
            }
            break;
            
        case 18: // SQRT
            if (calc_state.stack[0] >= 0.0) {
                calc_state.stack[0] = sqrt(calc_state.stack[0]);
            }
            break;
            
        case 19: // X^2
            calc_state.stack[0] = calc_state.stack[0] * calc_state.stack[0];
            break;
            
        case 21: // SIN
            {
                double angle = calc_state.stack[0];
                if (calc_state.angle_mode == 0) { // Degrees
                    angle = deg_to_rad(angle);
                }
                calc_state.stack[0] = sin(angle);
            }
            break;
            
        case 22: // COS
            {
                double angle = calc_state.stack[0];
                if (calc_state.angle_mode == 0) { // Degrees
                    angle = deg_to_rad(angle);
                }
                calc_state.stack[0] = cos(angle);
            }
            break;
            
        case 23: // TAN
            {
                double angle = calc_state.stack[0];
                if (calc_state.angle_mode == 0) { // Degrees
                    angle = deg_to_rad(angle);
                }
                calc_state.stack[0] = tan(angle);
            }
            break;
            
        case 27: // LN
            if (calc_state.stack[0] > 0.0) {
                calc_state.stack[0] = log(calc_state.stack[0]);
            }
            break;
            
        case 28: // LOG
            if (calc_state.stack[0] > 0.0) {
                calc_state.stack[0] = log10(calc_state.stack[0]);
            }
            break;
            
        case 31: // PI
            // Push stack up
            calc_state.stack[3] = calc_state.stack[2];
            calc_state.stack[2] = calc_state.stack[1];
            calc_state.stack[1] = calc_state.stack[0];
            calc_state.stack[0] = M_PI;
            break;
            
        case 33: // CLEAR
            calc_state.stack[0] = 0.0;
            break;
            
        case 34: // SWAP X-Y
            {
                double temp = calc_state.stack[0];
                calc_state.stack[0] = calc_state.stack[1];
                calc_state.stack[1] = temp;
            }
            break;
            
        default:
            LOGD("Unhandled key: %d", key_code);
            break;
    }
    
    update_display();
}

/**
 * Get current display string
 */
const char* c47_get_display() {
    if (!initialized) {
        c47_init();
    }
    return calc_state.display;
}

/**
 * Get X register value
 */
double c47_get_x_register() {
    if (!initialized) {
        c47_init();
    }
    return calc_state.stack[0];
}

/**
 * Get Y register value
 */
double c47_get_y_register() {
    if (!initialized) {
        c47_init();
    }
    return calc_state.stack[1];
}

/**
 * Get Z register value
 */
double c47_get_z_register() {
    if (!initialized) {
        c47_init();
    }
    return calc_state.stack[2];
}

/**
 * Get T register value
 */
double c47_get_t_register() {
    if (!initialized) {
        c47_init();
    }
    return calc_state.stack[3];
}

/**
 * Push value onto stack
 */
void c47_push_stack(double value) {
    if (!initialized) {
        c47_init();
    }
    
    calc_state.stack[3] = calc_state.stack[2];
    calc_state.stack[2] = calc_state.stack[1];
    calc_state.stack[1] = calc_state.stack[0];
    calc_state.stack[0] = value;
    
    update_display();
}

/**
 * Pop value from stack
 */
double c47_pop_stack() {
    if (!initialized) {
        c47_init();
    }
    
    double value = calc_state.stack[0];
    calc_state.stack[0] = calc_state.stack[1];
    calc_state.stack[1] = calc_state.stack[2];
    calc_state.stack[2] = calc_state.stack[3];
    calc_state.stack[3] = 0.0;
    
    update_display();
    return value;
}

/**
 * Enter number string
 */
void c47_enter_number(const char* number) {
    if (!initialized) {
        c47_init();
    }
    
    double value = atof(number);
    calc_state.stack[0] = value;
    snprintf(calc_state.display, sizeof(calc_state.display), "%.10g", value);
}

/**
 * Execute function by name
 */
void c47_execute_function(const char* function) {
    if (!initialized) {
        c47_init();
    }
    
    LOGD("Executing function: %s", function);
    
    if (strcmp(function, "sqrt") == 0) {
        c47_key_press(18);
    } else if (strcmp(function, "sin") == 0) {
        c47_key_press(21);
    } else if (strcmp(function, "cos") == 0) {
        c47_key_press(22);
    } else if (strcmp(function, "tan") == 0) {
        c47_key_press(23);
    } else if (strcmp(function, "ln") == 0) {
        c47_key_press(27);
    } else if (strcmp(function, "log") == 0) {
        c47_key_press(28);
    } else if (strcmp(function, "pi") == 0) {
        c47_key_press(31);
    } else {
        LOGD("Unknown function: %s", function);
    }
}

/**
 * Get calculator flags
 */
int c47_get_flags() {
    if (!initialized) {
        c47_init();
    }
    return calc_state.flags | calc_state.angle_mode;
}

/**
 * Set angle mode
 */
void c47_set_angle_mode(int mode) {
    if (!initialized) {
        c47_init();
    }
    
    if (mode >= 0 && mode <= 2) {
        calc_state.angle_mode = mode;
        LOGD("Angle mode set to: %d", mode);
    }
}

/**
 * Save calculator state
 */
void c47_save_state(const char* filename) {
    if (!initialized) {
        return;
    }
    
    FILE* file = fopen(filename, "wb");
    if (file) {
        fwrite(&calc_state, sizeof(calc_state), 1, file);
        fclose(file);
        LOGI("State saved to: %s", filename);
    } else {
        LOGE("Failed to save state to: %s", filename);
    }
}

/**
 * Load calculator state
 */
void c47_load_state(const char* filename) {
    FILE* file = fopen(filename, "rb");
    if (file) {
        if (fread(&calc_state, sizeof(calc_state), 1, file) == 1) {
            initialized = 1;
            LOGI("State loaded from: %s", filename);
        } else {
            LOGE("Failed to read state from: %s", filename);
        }
        fclose(file);
    } else {
        LOGD("State file not found: %s (this is normal for first run)", filename);
    }
}

// Helper functions

static void update_display() {
    double value = calc_state.stack[0];
    
    if (value == (long)value && fabs(value) < 1e10) {
        snprintf(calc_state.display, sizeof(calc_state.display), "%.0f", value);
    } else {
        snprintf(calc_state.display, sizeof(calc_state.display), "%.10g", value);
    }
}

static double deg_to_rad(double deg) {
    return deg * M_PI / 180.0;
}

static double rad_to_deg(double rad) {
    return rad * 180.0 / M_PI;
}