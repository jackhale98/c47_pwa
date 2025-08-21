package com.calculator.c47

import android.os.Bundle
import android.util.Log
import android.view.View
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.launch

class MainActivity : AppCompatActivity() {
    
    companion object {
        private const val TAG = "C47Calculator"
        private const val USE_NATIVE_ENGINE = true  // Toggle between native and WebView
        private const val BROADWAY_URL = "http://10.0.2.2:8080"  // Android emulator localhost
    }
    
    private lateinit var calculatorEngine: CalculatorEngine
    private lateinit var displayTextView: TextView
    private lateinit var webView: WebView
    private lateinit var nativeLayout: ConstraintLayout
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        if (USE_NATIVE_ENGINE) {
            setupNativeCalculator()
        } else {
            setupWebViewCalculator()
        }
    }
    
    private fun setupNativeCalculator() {
        setContentView(R.layout.activity_main)
        
        // Initialize native calculator engine
        calculatorEngine = CalculatorEngine()
        
        // Get UI references
        displayTextView = findViewById(R.id.display)
        nativeLayout = findViewById(R.id.native_layout)
        
        // Setup button listeners
        setupCalculatorButtons()
        
        // Update display
        updateDisplay()
    }
    
    private fun setupWebViewCalculator() {
        // Create WebView programmatically for GTK Broadway
        webView = WebView(this).apply {
            settings.apply {
                javaScriptEnabled = true
                domStorageEnabled = true
                allowFileAccess = true
                allowContentAccess = true
                loadWithOverviewMode = true
                useWideViewPort = true
                setSupportZoom(false)
            }
            
            webViewClient = object : WebViewClient() {
                override fun onPageFinished(view: WebView?, url: String?) {
                    super.onPageFinished(view, url)
                    Log.i(TAG, "GTK Broadway loaded: $url")
                }
                
                override fun onReceivedError(view: WebView?, errorCode: Int, description: String?, failingUrl: String?) {
                    Log.e(TAG, "WebView error: $description")
                    // Fallback to native calculator on error
                    runOnUiThread {
                        setupNativeCalculator()
                    }
                }
            }
            
            // Load GTK Broadway interface
            loadUrl(BROADWAY_URL)
        }
        
        setContentView(webView)
    }
    
    private fun setupCalculatorButtons() {
        // Number buttons
        findViewById<Button>(R.id.btn_0)?.setOnClickListener { pressKey(CalculatorEngine.KeyCode.KEY_0) }
        findViewById<Button>(R.id.btn_1)?.setOnClickListener { pressKey(CalculatorEngine.KeyCode.KEY_1) }
        findViewById<Button>(R.id.btn_2)?.setOnClickListener { pressKey(CalculatorEngine.KeyCode.KEY_2) }
        findViewById<Button>(R.id.btn_3)?.setOnClickListener { pressKey(CalculatorEngine.KeyCode.KEY_3) }
        findViewById<Button>(R.id.btn_4)?.setOnClickListener { pressKey(CalculatorEngine.KeyCode.KEY_4) }
        findViewById<Button>(R.id.btn_5)?.setOnClickListener { pressKey(CalculatorEngine.KeyCode.KEY_5) }
        findViewById<Button>(R.id.btn_6)?.setOnClickListener { pressKey(CalculatorEngine.KeyCode.KEY_6) }
        findViewById<Button>(R.id.btn_7)?.setOnClickListener { pressKey(CalculatorEngine.KeyCode.KEY_7) }
        findViewById<Button>(R.id.btn_8)?.setOnClickListener { pressKey(CalculatorEngine.KeyCode.KEY_8) }
        findViewById<Button>(R.id.btn_9)?.setOnClickListener { pressKey(CalculatorEngine.KeyCode.KEY_9) }
        findViewById<Button>(R.id.btn_dot)?.setOnClickListener { pressKey(CalculatorEngine.KeyCode.KEY_DOT) }
        
        // Operation buttons
        findViewById<Button>(R.id.btn_plus)?.setOnClickListener { pressKey(CalculatorEngine.KeyCode.KEY_PLUS) }
        findViewById<Button>(R.id.btn_minus)?.setOnClickListener { pressKey(CalculatorEngine.KeyCode.KEY_MINUS) }
        findViewById<Button>(R.id.btn_multiply)?.setOnClickListener { pressKey(CalculatorEngine.KeyCode.KEY_MULTIPLY) }
        findViewById<Button>(R.id.btn_divide)?.setOnClickListener { pressKey(CalculatorEngine.KeyCode.KEY_DIVIDE) }
        findViewById<Button>(R.id.btn_enter)?.setOnClickListener { pressKey(CalculatorEngine.KeyCode.KEY_ENTER) }
        
        // Function buttons
        findViewById<Button>(R.id.btn_sqrt)?.setOnClickListener { pressKey(CalculatorEngine.KeyCode.KEY_SQRT) }
        findViewById<Button>(R.id.btn_sin)?.setOnClickListener { pressKey(CalculatorEngine.KeyCode.KEY_SIN) }
        findViewById<Button>(R.id.btn_cos)?.setOnClickListener { pressKey(CalculatorEngine.KeyCode.KEY_COS) }
        findViewById<Button>(R.id.btn_tan)?.setOnClickListener { pressKey(CalculatorEngine.KeyCode.KEY_TAN) }
        findViewById<Button>(R.id.btn_ln)?.setOnClickListener { pressKey(CalculatorEngine.KeyCode.KEY_LN) }
        findViewById<Button>(R.id.btn_log)?.setOnClickListener { pressKey(CalculatorEngine.KeyCode.KEY_LOG) }
        findViewById<Button>(R.id.btn_exp)?.setOnClickListener { pressKey(CalculatorEngine.KeyCode.KEY_EXP) }
        findViewById<Button>(R.id.btn_power)?.setOnClickListener { pressKey(CalculatorEngine.KeyCode.KEY_POWER) }
        
        // Special buttons
        findViewById<Button>(R.id.btn_clear)?.setOnClickListener { pressKey(CalculatorEngine.KeyCode.KEY_CLEAR) }
        findViewById<Button>(R.id.btn_chs)?.setOnClickListener { pressKey(CalculatorEngine.KeyCode.KEY_CHS) }
        findViewById<Button>(R.id.btn_eex)?.setOnClickListener { pressKey(CalculatorEngine.KeyCode.KEY_EEX) }
        findViewById<Button>(R.id.btn_pi)?.setOnClickListener { pressKey(CalculatorEngine.KeyCode.KEY_PI) }
        findViewById<Button>(R.id.btn_swap)?.setOnClickListener { pressKey(CalculatorEngine.KeyCode.KEY_SWAP) }
        findViewById<Button>(R.id.btn_roll)?.setOnClickListener { pressKey(CalculatorEngine.KeyCode.KEY_ROLL_DOWN) }
        
        // Shift and mode buttons
        findViewById<Button>(R.id.btn_shift)?.setOnClickListener { pressKey(CalculatorEngine.KeyCode.KEY_SHIFT) }
        findViewById<Button>(R.id.btn_alpha)?.setOnClickListener { pressKey(CalculatorEngine.KeyCode.KEY_ALPHA) }
        findViewById<Button>(R.id.btn_mode)?.setOnClickListener { pressKey(CalculatorEngine.KeyCode.KEY_MODE) }
    }
    
    private fun pressKey(keyCode: Int) {
        lifecycleScope.launch {
            try {
                calculatorEngine.pressKey(keyCode)
                updateDisplay()
            } catch (e: Exception) {
                Log.e(TAG, "Error pressing key: $keyCode", e)
            }
        }
    }
    
    private fun updateDisplay() {
        lifecycleScope.launch {
            try {
                val state = calculatorEngine.getState()
                displayTextView.text = state.display
                
                // Update stack display if available
                findViewById<TextView>(R.id.stack_t)?.text = "T: ${formatNumber(state.tRegister)}"
                findViewById<TextView>(R.id.stack_z)?.text = "Z: ${formatNumber(state.zRegister)}"
                findViewById<TextView>(R.id.stack_y)?.text = "Y: ${formatNumber(state.yRegister)}"
                findViewById<TextView>(R.id.stack_x)?.text = "X: ${formatNumber(state.xRegister)}"
                
                // Update status indicators
                findViewById<TextView>(R.id.angle_mode)?.text = when (state.angleMode) {
                    CalculatorEngine.AngleMode.DEGREES -> "DEG"
                    CalculatorEngine.AngleMode.RADIANS -> "RAD"
                    CalculatorEngine.AngleMode.GRADIANS -> "GRAD"
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error updating display", e)
            }
        }
    }
    
    private fun formatNumber(value: Double): String {
        return if (value == value.toLong().toDouble()) {
            value.toLong().toString()
        } else {
            String.format("%.10g", value)
        }
    }
    
    override fun onPause() {
        super.onPause()
        if (USE_NATIVE_ENGINE && ::calculatorEngine.isInitialized) {
            calculatorEngine.onPause()
        }
    }
    
    override fun onResume() {
        super.onResume()
        if (USE_NATIVE_ENGINE && ::calculatorEngine.isInitialized) {
            calculatorEngine.onResume()
            updateDisplay()
        }
    }
    
    override fun onBackPressed() {
        if (!USE_NATIVE_ENGINE && ::webView.isInitialized && webView.canGoBack()) {
            webView.goBack()
        } else {
            super.onBackPressed()
        }
    }
}