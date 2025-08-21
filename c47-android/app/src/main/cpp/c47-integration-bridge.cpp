#include <jni.h>
#include <string>
#include <android/log.h>
#include <vector>
#include <mutex>

#define LOG_TAG "C47Native"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)

// Include C47 core headers (adapted for mobile)
extern "C" {
    // Simplified C47 types for mobile integration
    typedef bool bool_t;
    typedef uint16_t calcRegister_t;
    
    // C47 register definitions
    #define REGISTER_X 0
    #define REGISTER_Y 1
    #define REGISTER_Z 2
    #define REGISTER_T 3
    
    // C47 core function declarations (simplified for mobile)
    // These would be implemented by linking against extracted C47 core
    void c47_init_calculator();
    void c47_reset_calculator(); 
    void c47_key_press(uint16_t keyId);
    void c47_function_call(uint16_t functionId);
    
    // Stack operations from C43
    void c47_lift_stack();
    void c47_drop_stack();
    void c47_clear_x();
    void c47_clear_stack();
    void c47_swap_xy();
    void c47_roll_down();
    void c47_roll_up();
    
    // Register access from C43
    double c47_get_register_real(calcRegister_t reg);
    void c47_set_register_real(calcRegister_t reg, double value);
    const char* c47_get_display_string();
    
    // Memory operations from C43
    void c47_store(uint16_t register_num, double value);
    double c47_recall(uint16_t register_num);
    void c47_save_state(const char* filename);
    void c47_load_state(const char* filename);
    
    // Mathematics functions from C43
    void c47_add();
    void c47_subtract();
    void c47_multiply(); 
    void c47_divide();
    void c47_sqrt();
    void c47_square();
    void c47_reciprocal();
    void c47_exp();
    void c47_ln();
    void c47_log10();
    void c47_sin();
    void c47_cos();
    void c47_tan();
    void c47_power();
    
    // Constants from C43
    void c47_pi();
    void c47_e();
}

// Thread safety
static std::mutex c47_mutex;
static bool c47_initialized = false;

// Initialize C43 calculator core
void ensure_c47_initialized() {
    if (!c47_initialized) {
        c47_init_calculator();
        c47_initialized = true;
        LOGI("C43 calculator core initialized");
    }
}

// JNI function implementations
extern "C" {

JNIEXPORT void JNICALL
Java_com_calculator_c47_CalculatorEngine_nativeInit(JNIEnv* env, jobject /* this */) {
    std::lock_guard<std::mutex> lock(c47_mutex);
    ensure_c47_initialized();
}

JNIEXPORT void JNICALL
Java_com_calculator_c47_CalculatorEngine_nativeReset(JNIEnv* env, jobject /* this */) {
    std::lock_guard<std::mutex> lock(c47_mutex);
    ensure_c47_initialized();
    c47_reset_calculator();
    LOGD("Calculator reset");
}

JNIEXPORT void JNICALL
Java_com_calculator_c47_CalculatorEngine_nativeKeyPress(JNIEnv* env, jobject /* this */, jint keyCode) {
    std::lock_guard<std::mutex> lock(c47_mutex);
    ensure_c47_initialized();
    
    LOGD("Key press: %d", keyCode);
    
    // Map Android key codes to C43 function calls
    switch (keyCode) {
        case 0: case 1: case 2: case 3: case 4:
        case 5: case 6: case 7: case 8: case 9:
            // Number keys - handled by C43 key system
            c47_key_press(keyCode + 10); // C43 number key IDs
            break;
            
        case 10: // Decimal point
            c47_key_press(1010); // C43 decimal point key
            break;
            
        case 13: // ENTER
            c47_lift_stack();
            break;
            
        case 14: // PLUS
            c47_add();
            break;
            
        case 15: // MINUS  
            c47_subtract();
            break;
            
        case 16: // MULTIPLY
            c47_multiply();
            break;
            
        case 17: // DIVIDE
            c47_divide();
            break;
            
        case 18: // SQRT
            c47_sqrt();
            break;
            
        case 19: // X^2
            c47_square();
            break;
            
        case 20: // 1/x
            c47_reciprocal();
            break;
            
        case 21: // SIN
            c47_sin();
            break;
            
        case 22: // COS
            c47_cos();
            break;
            
        case 23: // TAN
            c47_tan();
            break;
            
        case 27: // LN
            c47_ln();
            break;
            
        case 28: // LOG
            c47_log10();
            break;
            
        case 29: // EXP
            c47_exp();
            break;
            
        case 30: // POWER
            c47_power();
            break;
            
        case 31: // PI
            c47_pi();
            break;
            
        case 32: // E
            c47_e();
            break;
            
        case 33: // CLEAR
            c47_clear_x();
            break;
            
        case 34: // SWAP X-Y
            c47_swap_xy();
            break;
            
        case 35: // ROLL DOWN
            c47_roll_down();
            break;
            
        case 36: // ROLL UP
            c47_roll_up();
            break;
            
        default:
            LOGD("Unhandled key: %d", keyCode);
            break;
    }
}

JNIEXPORT jstring JNICALL
Java_com_calculator_c47_CalculatorEngine_nativeGetDisplay(JNIEnv* env, jobject /* this */) {
    std::lock_guard<std::mutex> lock(c47_mutex);
    ensure_c47_initialized();
    
    const char* display = c47_get_display_string();
    return env->NewStringUTF(display ? display : "0");
}

JNIEXPORT jdouble JNICALL
Java_com_calculator_c47_CalculatorEngine_nativeGetXRegister(JNIEnv* env, jobject /* this */) {
    std::lock_guard<std::mutex> lock(c47_mutex);
    ensure_c47_initialized();
    return c47_get_register_real(REGISTER_X);
}

JNIEXPORT jdouble JNICALL
Java_com_calculator_c47_CalculatorEngine_nativeGetYRegister(JNIEnv* env, jobject /* this */) {
    std::lock_guard<std::mutex> lock(c47_mutex);
    ensure_c47_initialized();
    return c47_get_register_real(REGISTER_Y);
}

JNIEXPORT jdouble JNICALL
Java_com_calculator_c47_CalculatorEngine_nativeGetZRegister(JNIEnv* env, jobject /* this */) {
    std::lock_guard<std::mutex> lock(c47_mutex);
    ensure_c47_initialized();
    return c47_get_register_real(REGISTER_Z);
}

JNIEXPORT jdouble JNICALL
Java_com_calculator_c47_CalculatorEngine_nativeGetTRegister(JNIEnv* env, jobject /* this */) {
    std::lock_guard<std::mutex> lock(c47_mutex);
    ensure_c47_initialized();
    return c47_get_register_real(REGISTER_T);
}

JNIEXPORT jdoubleArray JNICALL
Java_com_calculator_c47_CalculatorEngine_nativeGetStack(JNIEnv* env, jobject /* this */) {
    std::lock_guard<std::mutex> lock(c47_mutex);
    ensure_c47_initialized();
    
    std::vector<double> stack_values;
    stack_values.push_back(c47_get_register_real(REGISTER_X));
    stack_values.push_back(c47_get_register_real(REGISTER_Y));
    stack_values.push_back(c47_get_register_real(REGISTER_Z));
    stack_values.push_back(c47_get_register_real(REGISTER_T));
    
    jdoubleArray result = env->NewDoubleArray(stack_values.size());
    env->SetDoubleArrayRegion(result, 0, stack_values.size(), stack_values.data());
    
    return result;
}

JNIEXPORT void JNICALL
Java_com_calculator_c47_CalculatorEngine_nativeEnterNumber(JNIEnv* env, jobject /* this */, jstring number) {
    std::lock_guard<std::mutex> lock(c47_mutex);
    ensure_c47_initialized();
    
    const char* num_str = env->GetStringUTFChars(number, nullptr);
    LOGD("Entering number: %s", num_str);
    
    // Parse and enter digits using C43 key system
    for (int i = 0; num_str[i] != '\0'; i++) {
        char digit = num_str[i];
        if (digit >= '0' && digit <= '9') {
            c47_key_press(10 + (digit - '0')); // C43 digit keys
        } else if (digit == '.') {
            c47_key_press(1010); // C43 decimal point
        } else if (digit == '-') {
            // Handle negative sign
            continue;
        }
    }
    
    env->ReleaseStringUTFChars(number, num_str);
}

JNIEXPORT void JNICALL
Java_com_calculator_c47_CalculatorEngine_nativeExecuteFunction(JNIEnv* env, jobject /* this */, jstring function) {
    std::lock_guard<std::mutex> lock(c47_mutex);
    ensure_c47_initialized();
    
    const char* func_str = env->GetStringUTFChars(function, nullptr);
    LOGD("Executing function: %s", func_str);
    
    // Map function names to C43 calls
    if (strcmp(func_str, "sqrt") == 0) {
        c47_sqrt();
    } else if (strcmp(func_str, "sin") == 0) {
        c47_sin();
    } else if (strcmp(func_str, "cos") == 0) {
        c47_cos();
    } else if (strcmp(func_str, "tan") == 0) {
        c47_tan();
    } else if (strcmp(func_str, "ln") == 0) {
        c47_ln();
    } else if (strcmp(func_str, "log") == 0) {
        c47_log10();
    } else if (strcmp(func_str, "exp") == 0) {
        c47_exp();
    } else if (strcmp(func_str, "pi") == 0) {
        c47_pi();
    } else if (strcmp(func_str, "e") == 0) {
        c47_e();
    } else {
        LOGD("Unknown function: %s", func_str);
    }
    
    env->ReleaseStringUTFChars(function, func_str);
}

JNIEXPORT void JNICALL
Java_com_calculator_c47_CalculatorEngine_nativePushStack(JNIEnv* env, jobject /* this */, jdouble value) {
    std::lock_guard<std::mutex> lock(c47_mutex);
    ensure_c47_initialized();
    
    LOGD("Pushing to stack: %f", value);
    c47_lift_stack();
    c47_set_register_real(REGISTER_X, value);
}

JNIEXPORT jdouble JNICALL
Java_com_calculator_c47_CalculatorEngine_nativePopStack(JNIEnv* env, jobject /* this */) {
    std::lock_guard<std::mutex> lock(c47_mutex);
    ensure_c47_initialized();
    
    double value = c47_get_register_real(REGISTER_X);
    c47_drop_stack();
    LOGD("Popped from stack: %f", value);
    return value;
}

JNIEXPORT void JNICALL
Java_com_calculator_c47_CalculatorEngine_nativeSaveState(JNIEnv* env, jobject /* this */, jstring filename) {
    std::lock_guard<std::mutex> lock(c47_mutex);
    ensure_c47_initialized();
    
    const char* file_str = env->GetStringUTFChars(filename, nullptr);
    LOGI("Saving state to: %s", file_str);
    c47_save_state(file_str);
    env->ReleaseStringUTFChars(filename, file_str);
}

JNIEXPORT void JNICALL
Java_com_calculator_c47_CalculatorEngine_nativeLoadState(JNIEnv* env, jobject /* this */, jstring filename) {
    std::lock_guard<std::mutex> lock(c47_mutex);
    ensure_c47_initialized();
    
    const char* file_str = env->GetStringUTFChars(filename, nullptr);
    LOGI("Loading state from: %s", file_str);
    c47_load_state(file_str);
    env->ReleaseStringUTFChars(filename, file_str);
}

// Lifecycle management
JNIEXPORT void JNICALL
Java_com_calculator_c47_CalculatorEngine_nativeOnPause(JNIEnv* env, jobject /* this */) {
    std::lock_guard<std::mutex> lock(c47_mutex);
    LOGI("Calculator paused - saving state");
    if (c47_initialized) {
        c47_save_state("/data/data/com.calculator.c47/files/autosave.c47");
    }
}

JNIEXPORT void JNICALL
Java_com_calculator_c47_CalculatorEngine_nativeOnResume(JNIEnv* env, jobject /* this */) {
    std::lock_guard<std::mutex> lock(c47_mutex);
    LOGI("Calculator resumed - restoring state");
    ensure_c47_initialized();
    c47_load_state("/data/data/com.calculator.c47/files/autosave.c47");
}

// JNI_OnLoad
JNIEXPORT jint JNICALL
JNI_OnLoad(JavaVM* vm, void* reserved) {
    LOGI("C47 Native library with C43 core loaded");
    JNIEnv* env;
    if (vm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6) != JNI_OK) {
        return JNI_ERR;
    }
    
    // Initialize C43 calculator core
    ensure_c47_initialized();
    
    return JNI_VERSION_1_6;
}

} // extern "C"