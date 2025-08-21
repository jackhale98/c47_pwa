package com.calculator.c47

import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * JNI wrapper for the C47 calculator engine
 * This class provides a Kotlin interface to the native C/C++ calculator implementation
 */
class CalculatorEngine {
    
    companion object {
        private const val TAG = "CalculatorEngine"
        
        init {
            try {
                System.loadLibrary("c47-native")
                Log.i(TAG, "Native library loaded successfully")
            } catch (e: UnsatisfiedLinkError) {
                Log.e(TAG, "Failed to load native library", e)
            }
        }
    }
    
    // Native method declarations
    private external fun nativeInit()
    private external fun nativeReset()
    private external fun nativeKeyPress(keyCode: Int)
    private external fun nativeGetDisplay(): String
    private external fun nativeGetXRegister(): Double
    private external fun nativeGetYRegister(): Double
    private external fun nativeGetZRegister(): Double
    private external fun nativeGetTRegister(): Double
    private external fun nativeGetStack(): DoubleArray
    private external fun nativeEnterNumber(number: String)
    private external fun nativeExecuteFunction(function: String)
    private external fun nativePushStack(value: Double)
    private external fun nativePopStack(): Double
    private external fun nativeGetFlags(): Int
    private external fun nativeSetAngleMode(mode: Int)
    private external fun nativeSaveState(filename: String)
    private external fun nativeLoadState(filename: String)
    private external fun nativeOnPause()
    private external fun nativeOnResume()
    
    // Calculator state
    data class CalculatorState(
        val display: String,
        val xRegister: Double,
        val yRegister: Double,
        val zRegister: Double,
        val tRegister: Double,
        val flags: Int,
        val angleMode: AngleMode
    )
    
    enum class AngleMode(val value: Int) {
        DEGREES(0),
        RADIANS(1),
        GRADIANS(2)
    }
    
    // Key codes matching the C47 calculator
    object KeyCode {
        const val KEY_0 = 0
        const val KEY_1 = 1
        const val KEY_2 = 2
        const val KEY_3 = 3
        const val KEY_4 = 4
        const val KEY_5 = 5
        const val KEY_6 = 6
        const val KEY_7 = 7
        const val KEY_8 = 8
        const val KEY_9 = 9
        const val KEY_DOT = 10
        const val KEY_CHS = 11  // Change sign
        const val KEY_EEX = 12  // Enter exponent
        const val KEY_ENTER = 13
        const val KEY_PLUS = 14
        const val KEY_MINUS = 15
        const val KEY_MULTIPLY = 16
        const val KEY_DIVIDE = 17
        const val KEY_SQRT = 18
        const val KEY_X_SQUARED = 19
        const val KEY_RECIPROCAL = 20
        const val KEY_SIN = 21
        const val KEY_COS = 22
        const val KEY_TAN = 23
        const val KEY_ASIN = 24
        const val KEY_ACOS = 25
        const val KEY_ATAN = 26
        const val KEY_LN = 27
        const val KEY_LOG = 28
        const val KEY_EXP = 29
        const val KEY_POWER = 30
        const val KEY_PI = 31
        const val KEY_E = 32
        const val KEY_CLEAR = 33
        const val KEY_SWAP = 34  // Swap X and Y
        const val KEY_ROLL_DOWN = 35
        const val KEY_ROLL_UP = 36
        const val KEY_STO = 37  // Store
        const val KEY_RCL = 38  // Recall
        const val KEY_SIGMA_PLUS = 39  // Statistics
        const val KEY_SIGMA_MINUS = 40
        const val KEY_SHIFT = 41
        const val KEY_ALPHA = 42
        const val KEY_MODE = 43
    }
    
    init {
        nativeInit()
    }
    
    /**
     * Reset the calculator to initial state
     */
    suspend fun reset() = withContext(Dispatchers.IO) {
        nativeReset()
    }
    
    /**
     * Process a key press
     */
    suspend fun pressKey(keyCode: Int) = withContext(Dispatchers.IO) {
        Log.d(TAG, "Pressing key: $keyCode")
        nativeKeyPress(keyCode)
    }
    
    /**
     * Get the current display text
     */
    suspend fun getDisplay(): String = withContext(Dispatchers.IO) {
        nativeGetDisplay()
    }
    
    /**
     * Get the complete calculator state
     */
    suspend fun getState(): CalculatorState = withContext(Dispatchers.IO) {
        CalculatorState(
            display = nativeGetDisplay(),
            xRegister = nativeGetXRegister(),
            yRegister = nativeGetYRegister(),
            zRegister = nativeGetZRegister(),
            tRegister = nativeGetTRegister(),
            flags = nativeGetFlags(),
            angleMode = when (nativeGetFlags() and 0x03) {
                1 -> AngleMode.RADIANS
                2 -> AngleMode.GRADIANS
                else -> AngleMode.DEGREES
            }
        )
    }
    
    /**
     * Get the RPN stack as an array
     */
    suspend fun getStack(): DoubleArray = withContext(Dispatchers.IO) {
        nativeGetStack()
    }
    
    /**
     * Enter a number string
     */
    suspend fun enterNumber(number: String) = withContext(Dispatchers.IO) {
        Log.d(TAG, "Entering number: $number")
        nativeEnterNumber(number)
    }
    
    /**
     * Execute a function by name
     */
    suspend fun executeFunction(function: String) = withContext(Dispatchers.IO) {
        Log.d(TAG, "Executing function: $function")
        nativeExecuteFunction(function)
    }
    
    /**
     * Push a value onto the stack
     */
    suspend fun pushStack(value: Double) = withContext(Dispatchers.IO) {
        nativePushStack(value)
    }
    
    /**
     * Pop a value from the stack
     */
    suspend fun popStack(): Double = withContext(Dispatchers.IO) {
        nativePopStack()
    }
    
    /**
     * Set the angle mode
     */
    suspend fun setAngleMode(mode: AngleMode) = withContext(Dispatchers.IO) {
        Log.d(TAG, "Setting angle mode: $mode")
        nativeSetAngleMode(mode.value)
    }
    
    /**
     * Save calculator state to file
     */
    suspend fun saveState(filename: String) = withContext(Dispatchers.IO) {
        Log.i(TAG, "Saving state to: $filename")
        nativeSaveState(filename)
    }
    
    /**
     * Load calculator state from file
     */
    suspend fun loadState(filename: String) = withContext(Dispatchers.IO) {
        Log.i(TAG, "Loading state from: $filename")
        nativeLoadState(filename)
    }
    
    /**
     * Called when the app is paused
     */
    fun onPause() {
        nativeOnPause()
    }
    
    /**
     * Called when the app is resumed
     */
    fun onResume() {
        nativeOnResume()
    }
}