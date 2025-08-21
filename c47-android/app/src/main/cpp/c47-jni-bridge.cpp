#include <jni.h>
#include <string>
#include <android/log.h>
#include <vector>
#include <mutex>

#define LOG_TAG "C47Native"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)

// Forward declarations for C47 core functions
extern "C" {
    // These functions will be implemented based on the actual C43/C47 source
    void c47_init();
    void c47_reset();
    void c47_key_press(int key_code);
    const char* c47_get_display();
    double c47_get_x_register();
    double c47_get_y_register();
    double c47_get_z_register();
    double c47_get_t_register();
    int c47_get_stack_size();
    void c47_push_stack(double value);
    double c47_pop_stack();
    void c47_enter_number(const char* number);
    void c47_execute_function(const char* function);
    int c47_get_flags();
    void c47_set_angle_mode(int mode); // 0=DEG, 1=RAD, 2=GRAD
    void c47_save_state(const char* filename);
    void c47_load_state(const char* filename);
}

// Mutex for thread safety
static std::mutex calculator_mutex;

// JNI function naming convention: Java_<package>_<class>_<method>
extern "C" {

JNIEXPORT void JNICALL
Java_com_calculator_c47_CalculatorEngine_nativeInit(JNIEnv* env, jobject /* this */) {
    std::lock_guard<std::mutex> lock(calculator_mutex);
    LOGI("Initializing C47 calculator engine");
    c47_init();
}

JNIEXPORT void JNICALL
Java_com_calculator_c47_CalculatorEngine_nativeReset(JNIEnv* env, jobject /* this */) {
    std::lock_guard<std::mutex> lock(calculator_mutex);
    LOGD("Resetting calculator");
    c47_reset();
}

JNIEXPORT void JNICALL
Java_com_calculator_c47_CalculatorEngine_nativeKeyPress(JNIEnv* env, jobject /* this */, jint keyCode) {
    std::lock_guard<std::mutex> lock(calculator_mutex);
    LOGD("Key press: %d", keyCode);
    c47_key_press(keyCode);
}

JNIEXPORT jstring JNICALL
Java_com_calculator_c47_CalculatorEngine_nativeGetDisplay(JNIEnv* env, jobject /* this */) {
    std::lock_guard<std::mutex> lock(calculator_mutex);
    const char* display = c47_get_display();
    return env->NewStringUTF(display ? display : "0");
}

JNIEXPORT jdouble JNICALL
Java_com_calculator_c47_CalculatorEngine_nativeGetXRegister(JNIEnv* env, jobject /* this */) {
    std::lock_guard<std::mutex> lock(calculator_mutex);
    return c47_get_x_register();
}

JNIEXPORT jdouble JNICALL
Java_com_calculator_c47_CalculatorEngine_nativeGetYRegister(JNIEnv* env, jobject /* this */) {
    std::lock_guard<std::mutex> lock(calculator_mutex);
    return c47_get_y_register();
}

JNIEXPORT jdouble JNICALL
Java_com_calculator_c47_CalculatorEngine_nativeGetZRegister(JNIEnv* env, jobject /* this */) {
    std::lock_guard<std::mutex> lock(calculator_mutex);
    return c47_get_z_register();
}

JNIEXPORT jdouble JNICALL
Java_com_calculator_c47_CalculatorEngine_nativeGetTRegister(JNIEnv* env, jobject /* this */) {
    std::lock_guard<std::mutex> lock(calculator_mutex);
    return c47_get_t_register();
}

JNIEXPORT jdoubleArray JNICALL
Java_com_calculator_c47_CalculatorEngine_nativeGetStack(JNIEnv* env, jobject /* this */) {
    std::lock_guard<std::mutex> lock(calculator_mutex);
    
    std::vector<double> stack_values;
    stack_values.push_back(c47_get_x_register());
    stack_values.push_back(c47_get_y_register());
    stack_values.push_back(c47_get_z_register());
    stack_values.push_back(c47_get_t_register());
    
    jdoubleArray result = env->NewDoubleArray(stack_values.size());
    env->SetDoubleArrayRegion(result, 0, stack_values.size(), stack_values.data());
    
    return result;
}

JNIEXPORT void JNICALL
Java_com_calculator_c47_CalculatorEngine_nativeEnterNumber(JNIEnv* env, jobject /* this */, jstring number) {
    std::lock_guard<std::mutex> lock(calculator_mutex);
    
    const char* num_str = env->GetStringUTFChars(number, nullptr);
    LOGD("Entering number: %s", num_str);
    c47_enter_number(num_str);
    env->ReleaseStringUTFChars(number, num_str);
}

JNIEXPORT void JNICALL
Java_com_calculator_c47_CalculatorEngine_nativeExecuteFunction(JNIEnv* env, jobject /* this */, jstring function) {
    std::lock_guard<std::mutex> lock(calculator_mutex);
    
    const char* func_str = env->GetStringUTFChars(function, nullptr);
    LOGD("Executing function: %s", func_str);
    c47_execute_function(func_str);
    env->ReleaseStringUTFChars(function, func_str);
}

JNIEXPORT void JNICALL
Java_com_calculator_c47_CalculatorEngine_nativePushStack(JNIEnv* env, jobject /* this */, jdouble value) {
    std::lock_guard<std::mutex> lock(calculator_mutex);
    LOGD("Pushing to stack: %f", value);
    c47_push_stack(value);
}

JNIEXPORT jdouble JNICALL
Java_com_calculator_c47_CalculatorEngine_nativePopStack(JNIEnv* env, jobject /* this */) {
    std::lock_guard<std::mutex> lock(calculator_mutex);
    double value = c47_pop_stack();
    LOGD("Popped from stack: %f", value);
    return value;
}

JNIEXPORT jint JNICALL
Java_com_calculator_c47_CalculatorEngine_nativeGetFlags(JNIEnv* env, jobject /* this */) {
    std::lock_guard<std::mutex> lock(calculator_mutex);
    return c47_get_flags();
}

JNIEXPORT void JNICALL
Java_com_calculator_c47_CalculatorEngine_nativeSetAngleMode(JNIEnv* env, jobject /* this */, jint mode) {
    std::lock_guard<std::mutex> lock(calculator_mutex);
    LOGD("Setting angle mode: %d", mode);
    c47_set_angle_mode(mode);
}

JNIEXPORT void JNICALL
Java_com_calculator_c47_CalculatorEngine_nativeSaveState(JNIEnv* env, jobject /* this */, jstring filename) {
    std::lock_guard<std::mutex> lock(calculator_mutex);
    
    const char* file_str = env->GetStringUTFChars(filename, nullptr);
    LOGI("Saving state to: %s", file_str);
    c47_save_state(file_str);
    env->ReleaseStringUTFChars(filename, file_str);
}

JNIEXPORT void JNICALL
Java_com_calculator_c47_CalculatorEngine_nativeLoadState(JNIEnv* env, jobject /* this */, jstring filename) {
    std::lock_guard<std::mutex> lock(calculator_mutex);
    
    const char* file_str = env->GetStringUTFChars(filename, nullptr);
    LOGI("Loading state from: %s", file_str);
    c47_load_state(file_str);
    env->ReleaseStringUTFChars(filename, file_str);
}

// Lifecycle management
JNIEXPORT void JNICALL
Java_com_calculator_c47_CalculatorEngine_nativeOnPause(JNIEnv* env, jobject /* this */) {
    std::lock_guard<std::mutex> lock(calculator_mutex);
    LOGI("Calculator paused - saving state");
    c47_save_state("/data/data/com.calculator.c47/files/autosave.dat");
}

JNIEXPORT void JNICALL
Java_com_calculator_c47_CalculatorEngine_nativeOnResume(JNIEnv* env, jobject /* this */) {
    std::lock_guard<std::mutex> lock(calculator_mutex);
    LOGI("Calculator resumed - restoring state");
    c47_load_state("/data/data/com.calculator.c47/files/autosave.dat");
}

// JNI_OnLoad: Called when the native library is loaded
JNIEXPORT jint JNICALL
JNI_OnLoad(JavaVM* vm, void* reserved) {
    LOGI("C47 Native library loaded");
    JNIEnv* env;
    if (vm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6) != JNI_OK) {
        return JNI_ERR;
    }
    
    // Initialize the calculator engine
    c47_init();
    
    return JNI_VERSION_1_6;
}

} // extern "C"