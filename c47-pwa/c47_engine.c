/*
 * Minimal C47 Engine - Lightweight wrapper around C47 core
 * Compiles essential C47 functionality for Broadway server
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <stdint.h>
#include <stdbool.h>

// Simplified types based on C47 source
typedef uint16_t calcRegister_t;
typedef bool bool_t;

// Essential register constants
#define REGISTER_X 0
#define REGISTER_Y 1
#define REGISTER_Z 2
#define REGISTER_T 3
#define MAX_STACK_SIZE 4

// Simplified C47 stack structure
typedef struct {
    double value;
    bool is_valid;
} register_t;

// Global state similar to C47
static register_t stack[MAX_STACK_SIZE];
static double lastX = 0.0;
static bool stack_lift_enabled = true;
static bool entering_number = false;

// Initialize the C47 engine
void c47_init(void) {
    for (int i = 0; i < MAX_STACK_SIZE; i++) {
        stack[i].value = 0.0;
        stack[i].is_valid = true;
    }
    lastX = 0.0;
    stack_lift_enabled = true;
    entering_number = false;
}

// Core C47 stack operations based on real source
void c47_lift_stack(void) {
    if (stack_lift_enabled) {
        // Lift stack: T is lost, everything moves up
        stack[REGISTER_T].value = stack[REGISTER_Z].value;
        stack[REGISTER_Z].value = stack[REGISTER_Y].value; 
        stack[REGISTER_Y].value = stack[REGISTER_X].value;
        // X will be set by caller
    }
}

void c47_drop_stack(void) {
    // Save X to LastX before dropping
    lastX = stack[REGISTER_X].value;
    
    // Drop stack: everything moves down, T duplicates
    stack[REGISTER_X].value = stack[REGISTER_Y].value;
    stack[REGISTER_Y].value = stack[REGISTER_Z].value;
    stack[REGISTER_Z].value = stack[REGISTER_T].value;
    // T register duplicates (authentic HP/C47 behavior)
}

// Enter key - authentic C47 behavior
void c47_enter(void) {
    if (entering_number) {
        entering_number = false;
        stack_lift_enabled = true;
    } else {
        // Duplicate X register with lift
        c47_lift_stack();
        stack[REGISTER_X].value = stack[REGISTER_Y].value;
    }
}

// Arithmetic operations - based on C47 mathematics/*.c
void c47_add(void) {
    lastX = stack[REGISTER_X].value;
    double result = stack[REGISTER_Y].value + stack[REGISTER_X].value;
    c47_drop_stack();
    stack[REGISTER_X].value = result;
    entering_number = false;
    stack_lift_enabled = true;
}

void c47_subtract(void) {
    lastX = stack[REGISTER_X].value;
    double result = stack[REGISTER_Y].value - stack[REGISTER_X].value;
    c47_drop_stack();
    stack[REGISTER_X].value = result;
    entering_number = false;
    stack_lift_enabled = true;
}

void c47_multiply(void) {
    lastX = stack[REGISTER_X].value;
    double result = stack[REGISTER_Y].value * stack[REGISTER_X].value;
    c47_drop_stack();
    stack[REGISTER_X].value = result;
    entering_number = false;
    stack_lift_enabled = true;
}

void c47_divide(void) {
    lastX = stack[REGISTER_X].value;
    double result = (stack[REGISTER_X].value != 0.0) ? 
                   stack[REGISTER_Y].value / stack[REGISTER_X].value : 
                   INFINITY;
    c47_drop_stack();
    stack[REGISTER_X].value = result;
    entering_number = false;
    stack_lift_enabled = true;
}

// Number entry
void c47_enter_digit(int digit) {
    if (!entering_number) {
        c47_lift_stack();
        stack[REGISTER_X].value = 0.0;
        entering_number = true;
        stack_lift_enabled = false;
    }
    
    // Simple digit accumulation
    if (stack[REGISTER_X].value >= 0) {
        stack[REGISTER_X].value = stack[REGISTER_X].value * 10.0 + digit;
    } else {
        stack[REGISTER_X].value = stack[REGISTER_X].value * 10.0 - digit;
    }
}

// Additional C47 functions
void c47_clear_x(void) {
    stack[REGISTER_X].value = 0.0;
}

void c47_change_sign(void) {
    stack[REGISTER_X].value = -stack[REGISTER_X].value;
}

void c47_swap_xy(void) {
    double temp = stack[REGISTER_X].value;
    stack[REGISTER_X].value = stack[REGISTER_Y].value;
    stack[REGISTER_Y].value = temp;
}

void c47_roll_down(void) {
    double temp = stack[REGISTER_X].value;
    stack[REGISTER_X].value = stack[REGISTER_Y].value;
    stack[REGISTER_Y].value = stack[REGISTER_Z].value;
    stack[REGISTER_Z].value = stack[REGISTER_T].value;
    stack[REGISTER_T].value = temp;
}

// Getter functions for Python interface
double c47_get_x(void) { return stack[REGISTER_X].value; }
double c47_get_y(void) { return stack[REGISTER_Y].value; }
double c47_get_z(void) { return stack[REGISTER_Z].value; }
double c47_get_t(void) { return stack[REGISTER_T].value; }
double c47_get_lastx(void) { return lastX; }

// Key processing similar to C47 keyboard.c
void c47_process_key(int key_code) {
    switch (key_code) {
        case 0: case 1: case 2: case 3: case 4:
        case 5: case 6: case 7: case 8: case 9:
            c47_enter_digit(key_code);
            break;
        case 36:  // ENTER
            c47_enter();
            break;
        case 40:  // Plus
            c47_add();
            break;
        case 30:  // Minus
            c47_subtract();
            break;
        case 20:  // Multiply
            c47_multiply();
            break;
        case 10:  // Divide
            c47_divide();
            break;
        case 76:  // CLx
            c47_clear_x();
            break;
        case 90:  // Change sign
            c47_change_sign();
            break;
        case 74:  // x≷y
            c47_swap_xy();
            break;
        case 73:  // R↓
            c47_roll_down();
            break;
    }
}

// Test function
void c47_test(void) {
    c47_init();
    printf("C47 Engine Test\n");
    printf("Initial: X=%.3f Y=%.3f Z=%.3f T=%.3f\n", 
           c47_get_x(), c47_get_y(), c47_get_z(), c47_get_t());
           
    // Test: 2 ENTER 3 +
    c47_enter_digit(2);
    printf("Enter 2: X=%.3f Y=%.3f Z=%.3f T=%.3f\n", 
           c47_get_x(), c47_get_y(), c47_get_z(), c47_get_t());
           
    c47_enter();
    printf("ENTER:   X=%.3f Y=%.3f Z=%.3f T=%.3f\n", 
           c47_get_x(), c47_get_y(), c47_get_z(), c47_get_t());
           
    c47_enter_digit(3);
    printf("Enter 3: X=%.3f Y=%.3f Z=%.3f T=%.3f\n", 
           c47_get_x(), c47_get_y(), c47_get_z(), c47_get_t());
           
    c47_add();
    printf("Add:     X=%.3f Y=%.3f Z=%.3f T=%.3f\n", 
           c47_get_x(), c47_get_y(), c47_get_z(), c47_get_t());
}

#ifdef STANDALONE_TEST
int main() {
    c47_test();
    return 0;
}
#endif