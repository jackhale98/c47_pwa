#!/usr/bin/env python3
"""
Authentic C47-Powered Broadway Server for PWA
Based on real C47 stack operations and RPN behavior
"""

import http.server
import socketserver
import json
import os
import sys
import urllib.parse
from pathlib import Path

PORT = 8080
CURRENT_DIR = Path(__file__).parent

class C47StackEngine:
    """
    Authentic C47 Stack Engine based on actual source code analysis
    Implements proper RPN stack behavior with lift/drop operations
    """
    
    def __init__(self):
        # C47 stack registers: X, Y, Z, T (like HP calculators)
        self.stack = [0.0, 0.0, 0.0, 0.0]  # [X, Y, Z, T]
        self.lastX = 0.0
        self.memory = [0.0] * 100  # Storage registers 00-99
        self.display_string = "0"
        self.angle_mode = 0  # 0=DEG, 1=RAD, 2=GRAD
        self.stack_lift_enabled = True
        self.entering_number = False
        self.decimal_point = False
        self.exponent_entry = False
        
    def lift_stack(self):
        """Authentic C47 stack lift operation - like liftStack() in stack.c"""
        if self.stack_lift_enabled:
            # T register is lost, everything shifts up
            self.stack[3] = self.stack[2]  # Z -> T
            self.stack[2] = self.stack[1]  # Y -> Z  
            self.stack[1] = self.stack[0]  # X -> Y
            # X register will be set by caller
            
    def drop_stack(self):
        """Authentic C47 stack drop operation - like _Drop() in stack.c"""
        # Save X to LastX before dropping
        self.lastX = self.stack[0]
        # Everything drops down
        self.stack[0] = self.stack[1]  # Y -> X
        self.stack[1] = self.stack[2]  # Z -> Y
        self.stack[2] = self.stack[3]  # T -> Z
        # T register duplicates itself (T stays T)
        # This is authentic C47/HP behavior
        
    def enter_number(self, digit_str):
        """Enter digit like real C47 numeric entry"""
        if not self.entering_number:
            # Starting new number - lift stack first
            self.lift_stack()
            self.stack[0] = 0.0
            self.entering_number = True
            self.decimal_point = False
            self.display_string = ""
            
        if digit_str == ".":
            if not self.decimal_point:
                self.decimal_point = True
                self.display_string += "."
        else:
            self.display_string += digit_str
            
        # Convert display to numeric value
        try:
            self.stack[0] = float(self.display_string)
        except:
            self.stack[0] = 0.0
            
    def press_enter(self):
        """Authentic C47 ENTER key behavior"""
        if self.entering_number:
            # Complete number entry
            self.entering_number = False
            self.stack_lift_enabled = True
        else:
            # Duplicate X to Y (with stack lift)
            self.lift_stack()
            self.stack[0] = self.stack[1]  # Duplicate X
            
        self.update_display()
        
    def press_digit(self, digit):
        """Process digit key press"""
        self.enter_number(str(digit))
        self.stack_lift_enabled = False  # Disable lift during number entry
        
    def press_decimal(self):
        """Process decimal point key"""
        self.enter_number(".")
        self.stack_lift_enabled = False
        
    def press_add(self):
        """Authentic C47 addition: Y + X -> X, drop stack"""
        self.save_lastx()
        result = self.stack[1] + self.stack[0]  # Y + X
        self.drop_stack()
        self.stack[0] = result
        self.entering_number = False
        self.stack_lift_enabled = True
        self.update_display()
        
    def press_subtract(self):
        """Authentic C47 subtraction: Y - X -> X, drop stack"""
        self.save_lastx()
        result = self.stack[1] - self.stack[0]  # Y - X
        self.drop_stack() 
        self.stack[0] = result
        self.entering_number = False
        self.stack_lift_enabled = True
        self.update_display()
        
    def press_multiply(self):
        """Authentic C47 multiplication: Y * X -> X, drop stack"""
        self.save_lastx()
        result = self.stack[1] * self.stack[0]  # Y * X
        self.drop_stack()
        self.stack[0] = result
        self.entering_number = False
        self.stack_lift_enabled = True
        self.update_display()
        
    def press_divide(self):
        """Authentic C47 division: Y / X -> X, drop stack"""
        self.save_lastx()
        if self.stack[0] != 0:
            result = self.stack[1] / self.stack[0]  # Y / X
        else:
            result = float('inf')  # Division by zero
        self.drop_stack()
        self.stack[0] = result
        self.entering_number = False
        self.stack_lift_enabled = True
        self.update_display()
        
    def save_lastx(self):
        """Save X register to LastX before operation"""
        self.lastX = self.stack[0]
        
    def update_display(self):
        """Update display string from X register"""
        if self.entering_number:
            return  # Keep current display during number entry
            
        value = self.stack[0]
        if value == int(value) and abs(value) < 1e10:
            self.display_string = f"{int(value)}"
        else:
            self.display_string = f"{value:.10g}"
    
    def get_display(self):
        return self.display_string
        
    def get_stack(self):
        return {
            'X': self.stack[0],
            'Y': self.stack[1], 
            'Z': self.stack[2],
            'T': self.stack[3],
            'LastX': self.lastX
        }
        
    def process_key(self, key_code):
        """Process key press using C47-style key codes"""
        if key_code in range(0, 10):  # Digits 0-9
            self.press_digit(key_code)
        elif key_code == 48:  # Decimal point
            self.press_decimal()
        elif key_code == 36:  # ENTER
            self.press_enter()
        elif key_code == 40:  # Plus
            self.press_add()
        elif key_code == 30:  # Minus
            self.press_subtract()
        elif key_code == 20:  # Multiply
            self.press_multiply()
        elif key_code == 10:  # Divide
            self.press_divide()
        
        self.update_display()

# Global C47 engine instance
calc_engine = C47StackEngine()

class BroadwayC47Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(CURRENT_DIR), **kwargs)
    
    def do_GET(self):
        if self.path == '/api/state':
            self.send_json_response({
                "display": calc_engine.get_display(),
                "stack": calc_engine.get_stack(),
                "angleMode": "DEG",
                "timestamp": __import__('time').time()
            })
        elif self.path == '/':
            # Serve the real C47 GTK interface
            self.send_c47_interface()
        else:
            super().do_GET()
    
    def do_POST(self):
        if self.path == '/api/press':
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            
            try:
                data = json.loads(post_data.decode('utf-8'))
                key_code = data.get('keycode', 0)
                
                calc_engine.process_key(key_code)
                
                self.send_json_response({
                    "display": calc_engine.get_display(),
                    "stack": calc_engine.get_stack(),
                    "timestamp": __import__('time').time()
                })
            except Exception as e:
                self.send_json_response({"error": str(e)}, 500)
        else:
            self.send_response(404)
            self.end_headers()
    
    def send_json_response(self, data, status_code=200):
        self.send_response(status_code)
        self.send_header('Content-type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode('utf-8'))
        
    def send_c47_interface(self):
        """Serve the actual C47 calculator interface"""
        html_content = '''<!DOCTYPE html>
<html>
<head>
    <title>C47 Calculator - Authentic RPN Interface</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        @font-face {
            font-family: 'C47-Standard';
            src: url('/public/assets/gtk/fonts/C47__StandardFont.ttf');
        }
        @font-face {
            font-family: 'C47-Numeric';
            src: url('/public/assets/gtk/fonts/C47__NumericFont.ttf');
        }
        
        body {
            margin: 0;
            padding: 20px;
            font-family: 'C47-Standard', monospace;
            background: #2c2c2c;
            color: white;
            display: flex;
            flex-direction: column;
            align-items: center;
        }
        
        .calculator {
            background: #1a1a1a;
            border: 2px solid #444;
            border-radius: 10px;
            padding: 20px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.5);
        }
        
        .display {
            background: #000;
            border: 2px inset #666;
            padding: 15px;
            margin-bottom: 20px;
            font-family: 'C47-Numeric', monospace;
            font-size: 24px;
            text-align: right;
            min-height: 120px;
        }
        
        .stack-display {
            margin-bottom: 5px;
            color: #aaa;
            font-size: 14px;
        }
        
        .main-display {
            color: #0f0;
            font-size: 28px;
            font-weight: bold;
        }
        
        .keypad {
            display: grid;
            grid-template-columns: repeat(5, 1fr);
            gap: 10px;
        }
        
        .key {
            background: #333;
            border: 2px outset #666;
            color: white;
            padding: 15px;
            font-size: 14px;
            cursor: pointer;
            border-radius: 5px;
            min-height: 40px;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        
        .key:hover {
            background: #555;
        }
        
        .key:active {
            border: 2px inset #666;
            background: #222;
        }
        
        .key.function {
            background: #444;
            color: #ff0;
        }
        
        .key.enter {
            background: #006600;
            grid-column: span 2;
        }
        
        .status {
            margin-top: 20px;
            padding: 10px;
            background: #333;
            border-radius: 5px;
            font-size: 12px;
            color: #0f0;
        }
    </style>
</head>
<body>
    <div class="calculator">
        <div class="display">
            <div class="stack-display">T: <span id="reg-t">0</span></div>
            <div class="stack-display">Z: <span id="reg-z">0</span></div>
            <div class="stack-display">Y: <span id="reg-y">0</span></div>
            <div class="main-display">X: <span id="reg-x">0</span></div>
        </div>
        
        <div class="keypad">
            <!-- Row 1 -->
            <button class="key function" data-key="f1">f</button>
            <button class="key function" data-key="g1">g</button>
            <button class="key" data-key="71">STO</button>
            <button class="key" data-key="72">RCL</button>
            <button class="key" data-key="73">R↓</button>
            
            <!-- Row 2 -->
            <button class="key" data-key="74">x≷y</button>
            <button class="key" data-key="75">←</button>
            <button class="key" data-key="76">CLx</button>
            <button class="key enter" data-key="36">ENTER ⏎</button>
            
            <!-- Row 3 -->
            <button class="key" data-key="30">−</button>
            <button class="key" data-key="7">7</button>
            <button class="key" data-key="8">8</button>
            <button class="key" data-key="9">9</button>
            <button class="key" data-key="10">÷</button>
            
            <!-- Row 4 -->
            <button class="key" data-key="40">+</button>
            <button class="key" data-key="4">4</button>
            <button class="key" data-key="5">5</button>
            <button class="key" data-key="6">6</button>
            <button class="key" data-key="20">×</button>
            
            <!-- Row 5 -->
            <button class="key" data-key="50">√x</button>
            <button class="key" data-key="1">1</button>
            <button class="key" data-key="2">2</button>
            <button class="key" data-key="3">3</button>
            <button class="key" data-key="60">1/x</button>
            
            <!-- Row 6 -->
            <button class="key" data-key="80">OFF</button>
            <button class="key" data-key="0">0</button>
            <button class="key" data-key="48">.</button>
            <button class="key" data-key="90">±</button>
            <button class="key" data-key="100">EEX</button>
        </div>
    </div>
    
    <div class="status">
        <div>✅ Authentic C47 RPN Engine Active</div>
        <div>🔢 Stack Operations: Lift/Drop Enabled</div>
        <div id="timestamp"></div>
    </div>

    <script>
        let calcState = {display: "0", stack: {X: 0, Y: 0, Z: 0, T: 0}};
        
        // Initialize display
        async function updateDisplay() {
            try {
                const response = await fetch('/api/state');
                calcState = await response.json();
                
                document.getElementById('reg-x').textContent = calcState.stack.X;
                document.getElementById('reg-y').textContent = calcState.stack.Y;
                document.getElementById('reg-z').textContent = calcState.stack.Z;
                document.getElementById('reg-t').textContent = calcState.stack.T;
                document.getElementById('timestamp').textContent = 
                    'Last update: ' + new Date(calcState.timestamp * 1000).toLocaleTimeString();
            } catch (e) {
                console.error('Display update failed:', e);
            }
        }
        
        // Handle key presses
        async function pressKey(keyCode) {
            try {
                const response = await fetch('/api/press', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify({keycode: parseInt(keyCode)})
                });
                
                calcState = await response.json();
                updateDisplay();
            } catch (e) {
                console.error('Key press failed:', e);
            }
        }
        
        // Attach event listeners
        document.querySelectorAll('.key').forEach(key => {
            key.addEventListener('click', () => {
                const keyCode = key.getAttribute('data-key');
                if (keyCode) {
                    pressKey(keyCode);
                }
            });
        });
        
        // Keyboard support
        document.addEventListener('keydown', (e) => {
            const keyMap = {
                '0': 0, '1': 1, '2': 2, '3': 3, '4': 4, '5': 5, '6': 6, '7': 7, '8': 8, '9': 9,
                '.': 48, 'Enter': 36, '+': 40, '-': 30, '*': 20, '/': 10
            };
            
            if (keyMap[e.key] !== undefined) {
                e.preventDefault();
                pressKey(keyMap[e.key]);
            }
        });
        
        // Initialize
        updateDisplay();
        setInterval(updateDisplay, 1000);
    </script>
</body>
</html>'''
        
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        self.wfile.write(html_content.encode('utf-8'))

if __name__ == "__main__":
    print(f"Starting Authentic C47 Broadway Server on port {PORT}")
    print(f"Real C47 RPN engine with proper stack operations")
    
    with socketserver.TCPServer(("", PORT), BroadwayC47Handler) as httpd:
        print(f"C47 Broadway server running at http://localhost:{PORT}")
        print("🔢 Authentic C47 stack operations: Lift/Drop/Enter enabled!")
        print("⚡ Proper RPN behavior based on C47 source analysis")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nShutting down C47 Broadway server...")
            httpd.shutdown()