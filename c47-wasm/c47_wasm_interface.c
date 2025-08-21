// C47 WebAssembly Interface
// Exposes authentic C47 calculator functions to JavaScript

#include <emscripten.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

// Include C47 headers (we'll create simplified versions)
// #include "c47.h"  // Will be simplified for WASM build

// Global calculator state (simplified)
typedef struct {
    double x, y, z, t;  // RPN Stack registers
    int error_code;
    int angular_mode;   // 0=DEG, 1=RAD, 2=GRAD
    int display_mode;   // 0=NORMAL, 1=SCI, 2=ENG
    int last_operation;
} calc_state_t;

static calc_state_t calc_state = {0};

// Exported functions for JavaScript interface
EMSCRIPTEN_KEEPALIVE
int c47_init() {
    // Initialize the calculator state
    calc_state.x = 0.0;
    calc_state.y = 0.0;
    calc_state.z = 0.0;
    calc_state.t = 0.0;
    calc_state.error_code = 0;
    calc_state.angular_mode = 0; // DEG
    calc_state.display_mode = 0; // NORMAL
    calc_state.last_operation = 0;
    return 1; // Success
}

EMSCRIPTEN_KEEPALIVE
double c47_get_x() {
    return calc_state.x;
}

EMSCRIPTEN_KEEPALIVE
double c47_get_y() {
    return calc_state.y;
}

EMSCRIPTEN_KEEPALIVE
double c47_get_z() {
    return calc_state.z;
}

EMSCRIPTEN_KEEPALIVE
double c47_get_t() {
    return calc_state.t;
}

EMSCRIPTEN_KEEPALIVE
void c47_set_x(double value) {
    calc_state.x = value;
}

EMSCRIPTEN_KEEPALIVE
void c47_enter_number(double value) {
    // Lift stack and enter new number in X
    calc_state.t = calc_state.z;
    calc_state.z = calc_state.y;
    calc_state.y = calc_state.x;
    calc_state.x = value;
}

EMSCRIPTEN_KEEPALIVE
void c47_drop_stack() {
    // Drop X register, pull stack down
    calc_state.x = calc_state.y;
    calc_state.y = calc_state.z;
    calc_state.z = calc_state.t;
    calc_state.t = 0.0;
}

EMSCRIPTEN_KEEPALIVE
void c47_swap_xy() {
    double temp = calc_state.x;
    calc_state.x = calc_state.y;
    calc_state.y = temp;
}

// Basic arithmetic operations
EMSCRIPTEN_KEEPALIVE
void c47_add() {
    calc_state.x = calc_state.y + calc_state.x;
    c47_drop_stack();
}

EMSCRIPTEN_KEEPALIVE
void c47_subtract() {
    calc_state.x = calc_state.y - calc_state.x;
    c47_drop_stack();
}

EMSCRIPTEN_KEEPALIVE
void c47_multiply() {
    calc_state.x = calc_state.y * calc_state.x;
    c47_drop_stack();
}

EMSCRIPTEN_KEEPALIVE
void c47_divide() {
    if (calc_state.x != 0.0) {
        calc_state.x = calc_state.y / calc_state.x;
        c47_drop_stack();
    } else {
        calc_state.error_code = 1; // Division by zero
    }
}

// Mathematical functions
EMSCRIPTEN_KEEPALIVE
void c47_sin() {
    calc_state.x = sin(calc_state.x);
}

EMSCRIPTEN_KEEPALIVE
void c47_cos() {
    calc_state.x = cos(calc_state.x);
}

EMSCRIPTEN_KEEPALIVE
void c47_tan() {
    calc_state.x = tan(calc_state.x);
}

EMSCRIPTEN_KEEPALIVE
void c47_ln() {
    if (calc_state.x > 0.0) {
        calc_state.x = log(calc_state.x);
    } else {
        calc_state.error_code = 2; // Invalid argument
    }
}

EMSCRIPTEN_KEEPALIVE
void c47_exp() {
    calc_state.x = exp(calc_state.x);
}

EMSCRIPTEN_KEEPALIVE
void c47_sqrt() {
    if (calc_state.x >= 0.0) {
        calc_state.x = sqrt(calc_state.x);
    } else {
        calc_state.error_code = 2; // Invalid argument
    }
}

// Utility functions
EMSCRIPTEN_KEEPALIVE
int c47_get_error() {
    return calc_state.error_code;
}

EMSCRIPTEN_KEEPALIVE
void c47_clear_error() {
    calc_state.error_code = 0;
}

// Key press interface - maps to authentic C47 key codes
EMSCRIPTEN_KEEPALIVE
void c47_key_press(int key_code) {
    // This will map to the exact C47 keyboard layout
    // Key codes will match the authentic C47 assignment
    switch(key_code) {
        case 21: c47_add(); break;           // Σ+ key
        case 22: /* 1/x */ break;            // 1/x key  
        case 23: c47_sqrt(); break;          // √x key
        case 24: /* LOG */ break;            // LOG key
        case 25: c47_ln(); break;            // LN key
        case 26: /* XEQ */ break;            // XEQ key
        // ... more key mappings will be added
        default:
            // Unknown key
            break;
    }
}

// Export the stack state as a formatted string for display
EMSCRIPTEN_KEEPALIVE
char* c47_get_display_string() {
    static char display[256];
    snprintf(display, sizeof(display), 
        "T: %.6g\nZ: %.6g\nY: %.6g\nX: %.6g", 
        calc_state.t, calc_state.z, calc_state.y, calc_state.x);
    return display;
}