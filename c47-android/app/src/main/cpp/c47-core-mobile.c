/**
 * C47 Core Mobile Implementation
 * Adapted C47 calculator engine for Android/mobile platforms
 * Based on extracted C47 core functions
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <stdint.h>
#include <stdbool.h>
#include <android/log.h>

#define LOG_TAG "C47Core"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)

// Simplified C47 types for mobile
typedef bool bool_t;
typedef uint16_t calcRegister_t;

// Register definitions from C47
#define REGISTER_X 0
#define REGISTER_Y 1  
#define REGISTER_Z 2
#define REGISTER_T 3
#define MAX_REGISTERS 4

#define STORAGE_REGISTERS 100  // Memory registers 00-99
#define STACK_SIZE 4

// C43-inspired calculator state
typedef struct {
    double stack[STACK_SIZE];           // X, Y, Z, T registers
    double storage[STORAGE_REGISTERS];  // Storage registers 00-99
    double lastX;                       // Last X value
    char displayBuffer[32];             // Display string
    int angleMode;                      // 0=DEG, 1=RAD, 2=GRAD
    bool_t liftEnabled;                 // Stack lift flag
    bool_t shiftF;                      // F shift state
    bool_t shiftG;                      // G shift state
    int programCounter;                 // Program counter
    bool_t runningProgram;              // Program execution state
} c47_state_t;

// Global calculator state
static c47_state_t calc_state = {0};
static bool_t initialized = false;

// Function prototypes
static void update_display();
static void lift_stack_internal();
static void drop_stack_internal();
static double deg_to_rad(double deg);
static double rad_to_deg(double rad);
static void clear_register_internal(calcRegister_t reg);

/**
 * Initialize C43 calculator core
 */
void c47_init_calculator() {
    LOGI("Initializing C43 calculator core");
    
    if (initialized) {
        LOGD("C43 already initialized");
        return;
    }
    
    // Initialize calculator state
    memset(&calc_state, 0, sizeof(calc_state));
    
    // Initialize stack
    for (int i = 0; i < STACK_SIZE; i++) {
        calc_state.stack[i] = 0.0;
    }
    
    // Initialize storage registers
    for (int i = 0; i < STORAGE_REGISTERS; i++) {
        calc_state.storage[i] = 0.0;
    }
    
    calc_state.angleMode = 0; // Degrees
    calc_state.liftEnabled = true;
    strcpy(calc_state.displayBuffer, "0");
    
    initialized = true;
    update_display();
    LOGI("C43 calculator initialized");
}

/**
 * Reset calculator to initial state
 */
void c47_reset_calculator() {
    LOGI("Resetting C43 calculator");
    initialized = false;
    c47_init_calculator();
}

/**
 * Get register value as real number
 */
double c47_get_register_real(calcRegister_t reg) {
    if (!initialized) {
        c47_init_calculator();
    }
    
    if (reg < STACK_SIZE) {
        return calc_state.stack[reg];
    }
    return 0.0;
}

/**
 * Set register value
 */
void c47_set_register_real(calcRegister_t reg, double value) {
    if (!initialized) {
        c47_init_calculator();
    }
    
    if (reg < STACK_SIZE) {
        calc_state.stack[reg] = value;
        if (reg == REGISTER_X) {
            update_display();
        }
    }
}

/**
 * Get display string
 */
const char* c47_get_display_string() {
    if (!initialized) {
        c47_init_calculator();
    }
    return calc_state.displayBuffer;
}

/**
 * Stack Operations - Following C43 patterns
 */

void c47_lift_stack() {
    if (!initialized) c47_init_calculator();
    
    if (calc_state.liftEnabled) {
        lift_stack_internal();
    }
    calc_state.liftEnabled = true;
}

static void lift_stack_internal() {
    // Move T register value is lost, others move up
    calc_state.stack[REGISTER_T] = calc_state.stack[REGISTER_Z];
    calc_state.stack[REGISTER_Z] = calc_state.stack[REGISTER_Y];
    calc_state.stack[REGISTER_Y] = calc_state.stack[REGISTER_X];
    calc_state.stack[REGISTER_X] = 0.0;
    
    LOGD("Stack lifted: T=%f, Z=%f, Y=%f, X=%f", 
         calc_state.stack[REGISTER_T], calc_state.stack[REGISTER_Z],
         calc_state.stack[REGISTER_Y], calc_state.stack[REGISTER_X]);
}

void c47_drop_stack() {
    if (!initialized) c47_init_calculator();
    drop_stack_internal();
    update_display();
}

static void drop_stack_internal() {
    // Move stack down, T gets duplicated
    calc_state.stack[REGISTER_X] = calc_state.stack[REGISTER_Y];
    calc_state.stack[REGISTER_Y] = calc_state.stack[REGISTER_Z];
    calc_state.stack[REGISTER_Z] = calc_state.stack[REGISTER_T];
    // T stays the same (duplicated)
    
    LOGD("Stack dropped: T=%f, Z=%f, Y=%f, X=%f",
         calc_state.stack[REGISTER_T], calc_state.stack[REGISTER_Z],
         calc_state.stack[REGISTER_Y], calc_state.stack[REGISTER_X]);
}

void c47_clear_x() {
    if (!initialized) c47_init_calculator();
    calc_state.stack[REGISTER_X] = 0.0;
    calc_state.liftEnabled = false;
    update_display();
}

void c47_clear_stack() {
    if (!initialized) c47_init_calculator();
    for (int i = 0; i < STACK_SIZE; i++) {
        calc_state.stack[i] = 0.0;
    }
    update_display();
}

void c47_swap_xy() {
    if (!initialized) c47_init_calculator();
    double temp = calc_state.stack[REGISTER_X];
    calc_state.stack[REGISTER_X] = calc_state.stack[REGISTER_Y];
    calc_state.stack[REGISTER_Y] = temp;
    calc_state.liftEnabled = false;
    update_display();
}

void c47_roll_down() {
    if (!initialized) c47_init_calculator();
    double temp = calc_state.stack[REGISTER_X];
    calc_state.stack[REGISTER_X] = calc_state.stack[REGISTER_Y];
    calc_state.stack[REGISTER_Y] = calc_state.stack[REGISTER_Z];
    calc_state.stack[REGISTER_Z] = calc_state.stack[REGISTER_T];
    calc_state.stack[REGISTER_T] = temp;
    calc_state.liftEnabled = false;
    update_display();
}

void c47_roll_up() {
    if (!initialized) c47_init_calculator();
    double temp = calc_state.stack[REGISTER_T];
    calc_state.stack[REGISTER_T] = calc_state.stack[REGISTER_Z];
    calc_state.stack[REGISTER_Z] = calc_state.stack[REGISTER_Y];
    calc_state.stack[REGISTER_Y] = calc_state.stack[REGISTER_X];
    calc_state.stack[REGISTER_X] = temp;
    calc_state.liftEnabled = false;
    update_display();
}

/**
 * Arithmetic Operations - Following C43/RPN patterns
 */

void c47_add() {
    if (!initialized) c47_init_calculator();
    calc_state.lastX = calc_state.stack[REGISTER_X];
    calc_state.stack[REGISTER_X] = calc_state.stack[REGISTER_Y] + calc_state.stack[REGISTER_X];
    drop_stack_internal();
    calc_state.liftEnabled = true;
    update_display();
}

void c47_subtract() {
    if (!initialized) c47_init_calculator();
    calc_state.lastX = calc_state.stack[REGISTER_X];
    calc_state.stack[REGISTER_X] = calc_state.stack[REGISTER_Y] - calc_state.stack[REGISTER_X];
    drop_stack_internal();
    calc_state.liftEnabled = true;
    update_display();
}

void c47_multiply() {
    if (!initialized) c47_init_calculator();
    calc_state.lastX = calc_state.stack[REGISTER_X];
    calc_state.stack[REGISTER_X] = calc_state.stack[REGISTER_Y] * calc_state.stack[REGISTER_X];
    drop_stack_internal();
    calc_state.liftEnabled = true;
    update_display();
}

void c47_divide() {
    if (!initialized) c47_init_calculator();
    calc_state.lastX = calc_state.stack[REGISTER_X];
    
    if (calc_state.stack[REGISTER_X] != 0.0) {
        calc_state.stack[REGISTER_X] = calc_state.stack[REGISTER_Y] / calc_state.stack[REGISTER_X];
        drop_stack_internal();
    } else {
        LOGE("Division by zero error");
        strcpy(calc_state.displayBuffer, "Error: Div by 0");
        return;
    }
    
    calc_state.liftEnabled = true;
    update_display();
}

/**
 * Mathematical Functions - Following C43 precision patterns
 */

void c47_sqrt() {
    if (!initialized) c47_init_calculator();
    calc_state.lastX = calc_state.stack[REGISTER_X];
    
    if (calc_state.stack[REGISTER_X] >= 0.0) {
        calc_state.stack[REGISTER_X] = sqrt(calc_state.stack[REGISTER_X]);
    } else {
        LOGE("Square root of negative number");
        strcpy(calc_state.displayBuffer, "Error: √(neg)");
        return;
    }
    
    calc_state.liftEnabled = true;
    update_display();
}

void c47_square() {
    if (!initialized) c47_init_calculator();
    calc_state.lastX = calc_state.stack[REGISTER_X];
    calc_state.stack[REGISTER_X] = calc_state.stack[REGISTER_X] * calc_state.stack[REGISTER_X];
    calc_state.liftEnabled = true;
    update_display();
}

void c47_reciprocal() {
    if (!initialized) c47_init_calculator();
    calc_state.lastX = calc_state.stack[REGISTER_X];
    
    if (calc_state.stack[REGISTER_X] != 0.0) {
        calc_state.stack[REGISTER_X] = 1.0 / calc_state.stack[REGISTER_X];
    } else {
        LOGE("Reciprocal of zero error");
        strcpy(calc_state.displayBuffer, "Error: 1/0");
        return;
    }
    
    calc_state.liftEnabled = true;
    update_display();
}

void c47_exp() {
    if (!initialized) c47_init_calculator();
    calc_state.lastX = calc_state.stack[REGISTER_X];
    calc_state.stack[REGISTER_X] = exp(calc_state.stack[REGISTER_X]);
    calc_state.liftEnabled = true;
    update_display();
}

void c47_ln() {
    if (!initialized) c47_init_calculator();
    calc_state.lastX = calc_state.stack[REGISTER_X];
    
    if (calc_state.stack[REGISTER_X] > 0.0) {
        calc_state.stack[REGISTER_X] = log(calc_state.stack[REGISTER_X]);
    } else {
        LOGE("Natural log of non-positive number");
        strcpy(calc_state.displayBuffer, "Error: ln(≤0)");
        return;
    }
    
    calc_state.liftEnabled = true;
    update_display();
}

void c47_log10() {
    if (!initialized) c47_init_calculator();
    calc_state.lastX = calc_state.stack[REGISTER_X];
    
    if (calc_state.stack[REGISTER_X] > 0.0) {
        calc_state.stack[REGISTER_X] = log10(calc_state.stack[REGISTER_X]);
    } else {
        LOGE("Log10 of non-positive number");
        strcpy(calc_state.displayBuffer, "Error: log(≤0)");
        return;
    }
    
    calc_state.liftEnabled = true;
    update_display();
}

void c47_sin() {
    if (!initialized) c47_init_calculator();
    calc_state.lastX = calc_state.stack[REGISTER_X];
    
    double angle = calc_state.stack[REGISTER_X];
    if (calc_state.angleMode == 0) { // Degrees
        angle = deg_to_rad(angle);
    }
    
    calc_state.stack[REGISTER_X] = sin(angle);
    calc_state.liftEnabled = true;
    update_display();
}

void c47_cos() {
    if (!initialized) c47_init_calculator();
    calc_state.lastX = calc_state.stack[REGISTER_X];
    
    double angle = calc_state.stack[REGISTER_X];
    if (calc_state.angleMode == 0) { // Degrees
        angle = deg_to_rad(angle);
    }
    
    calc_state.stack[REGISTER_X] = cos(angle);
    calc_state.liftEnabled = true;
    update_display();
}

void c47_tan() {
    if (!initialized) c47_init_calculator();
    calc_state.lastX = calc_state.stack[REGISTER_X];
    
    double angle = calc_state.stack[REGISTER_X];
    if (calc_state.angleMode == 0) { // Degrees
        angle = deg_to_rad(angle);
    }
    
    calc_state.stack[REGISTER_X] = tan(angle);
    calc_state.liftEnabled = true;
    update_display();
}

void c47_power() {
    if (!initialized) c47_init_calculator();
    calc_state.lastX = calc_state.stack[REGISTER_X];
    
    // Y^X operation
    calc_state.stack[REGISTER_X] = pow(calc_state.stack[REGISTER_Y], calc_state.stack[REGISTER_X]);
    drop_stack_internal();
    calc_state.liftEnabled = true;
    update_display();
}

/**
 * Constants - Following C43 precision
 */

void c47_pi() {
    if (!initialized) c47_init_calculator();
    lift_stack_internal();
    calc_state.stack[REGISTER_X] = M_PI;
    calc_state.liftEnabled = false;
    update_display();
}

void c47_e() {
    if (!initialized) c47_init_calculator();
    lift_stack_internal();
    calc_state.stack[REGISTER_X] = M_E;
    calc_state.liftEnabled = false;
    update_display();
}

/**
 * Memory Operations - Following C43 patterns
 */

void c47_store(uint16_t register_num, double value) {
    if (!initialized) c47_init_calculator();
    
    if (register_num < STORAGE_REGISTERS) {
        calc_state.storage[register_num] = value;
        LOGD("Stored %f to register %d", value, register_num);
    }
}

double c47_recall(uint16_t register_num) {
    if (!initialized) c47_init_calculator();
    
    if (register_num < STORAGE_REGISTERS) {
        return calc_state.storage[register_num];
    }
    return 0.0;
}

/**
 * State Management
 */

void c47_save_state(const char* filename) {
    if (!initialized) return;
    
    FILE* file = fopen(filename, "wb");
    if (file) {
        fwrite(&calc_state, sizeof(c47_state_t), 1, file);
        fclose(file);
        LOGI("State saved to: %s", filename);
    } else {
        LOGE("Failed to save state to: %s", filename);
    }
}

void c47_load_state(const char* filename) {
    FILE* file = fopen(filename, "rb");
    if (file) {
        if (fread(&calc_state, sizeof(c47_state_t), 1, file) == 1) {
            initialized = true;
            update_display();
            LOGI("State loaded from: %s", filename);
        }
        fclose(file);
    } else {
        LOGD("State file not found: %s", filename);
    }
}

/**
 * Key Press Handler - Simplified C43 key system
 */
void c47_key_press(uint16_t keyId) {
    LOGD("C43 key press: %d", keyId);
    
    // Handle digit keys (10-19 for 0-9)
    if (keyId >= 10 && keyId <= 19) {
        int digit = keyId - 10;
        // TODO: Implement digit entry logic similar to C43
        LOGD("Digit key: %d", digit);
    }
    // Handle decimal point
    else if (keyId == 1010) {
        LOGD("Decimal point key");
    }
    // Handle other keys through function mapping
}

void c47_function_call(uint16_t functionId) {
    LOGD("C43 function call: %d", functionId);
    // Map C43 function IDs to operations
}

// Helper Functions

static void update_display() {
    double value = calc_state.stack[REGISTER_X];
    
    if (value == (long)value && fabs(value) < 1e10) {
        snprintf(calc_state.displayBuffer, sizeof(calc_state.displayBuffer), "%.0f", value);
    } else {
        snprintf(calc_state.displayBuffer, sizeof(calc_state.displayBuffer), "%.10g", value);
    }
    
    LOGD("Display updated: %s", calc_state.displayBuffer);
}

static double deg_to_rad(double deg) {
    return deg * M_PI / 180.0;
}

static double rad_to_deg(double rad) {
    return rad * 180.0 / M_PI;
}