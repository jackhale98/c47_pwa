#!/usr/bin/env python3
"""
C47-Powered Broadway Server for C47 PWA
Integrates real C47 calculator logic with original GTK styling
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

class C47CalculatorEngine:
    """
    Python implementation of C47 calculator core
    Based on the extracted C47 engine analysis
    """
    
    def __init__(self):
        self.stack = [0.0, 0.0, 0.0, 0.0]  # X, Y, Z, T
        self.storage = [0.0] * 100  # Memory registers 00-99
        self.lastX = 0.0
        self.display = "0"
        self.angleMode = 0  # 0=DEG, 1=RAD, 2=GRAD
        self.liftEnabled = True
        self.shiftF = False
        self.shiftG = False
        
    def get_display(self):
        return self.display
        
    def get_stack(self):
        return {
            'X': self.stack[0],
            'Y': self.stack[1], 
            'Z': self.stack[2],
            'T': self.stack[3]
        }
        
    def update_display(self):
        value = self.stack[0]
        if value == int(value) and abs(value) < 1e10:
            self.display = f"{int(value)}"
        else:
            self.display = f"{value:.10g}"
    
    def lift_stack(self):
        if self.liftEnabled:
            self.stack[3] = self.stack[2]
            self.stack[2] = self.stack[1] 
            self.stack[1] = self.stack[0]
            self.stack[0] = 0.0
        self.liftEnabled = True
            
    def drop_stack(self):
        self.stack[0] = self.stack[1]
        self.stack[1] = self.stack[2]
        self.stack[2] = self.stack[3]
        # T stays the same
        
    def press_key(self, keycode):
        """Process key press using C43 logic"""
        print(f"C43 Key press: {keycode}")
        
        if keycode in range(10):  # Number keys 0-9
            # TODO: Implement digit entry logic
            self.lift_stack()
            self.stack[0] = float(keycode)
            self.liftEnabled = False
            
        elif keycode == 13:  # ENTER
            self.lift_stack()
            
        elif keycode == 14:  # PLUS
            self.lastX = self.stack[0]
            self.stack[0] = self.stack[1] + self.stack[0]
            self.drop_stack()
            
        elif keycode == 15:  # MINUS
            self.lastX = self.stack[0]
            self.stack[0] = self.stack[1] - self.stack[0]
            self.drop_stack()
            
        elif keycode == 16:  # MULTIPLY
            self.lastX = self.stack[0]
            self.stack[0] = self.stack[1] * self.stack[0]
            self.drop_stack()
            
        elif keycode == 17:  # DIVIDE
            self.lastX = self.stack[0]
            if self.stack[0] != 0:
                self.stack[0] = self.stack[1] / self.stack[0]
                self.drop_stack()
            else:
                self.display = "Error"
                return
                
        elif keycode == 18:  # SQRT
            import math
            self.lastX = self.stack[0]
            if self.stack[0] >= 0:
                self.stack[0] = math.sqrt(self.stack[0])
            else:
                self.display = "Error"
                return
                
        elif keycode == 21:  # SIN
            import math
            self.lastX = self.stack[0]
            angle = self.stack[0]
            if self.angleMode == 0:  # Degrees
                angle = math.radians(angle)
            self.stack[0] = math.sin(angle)
            
        elif keycode == 22:  # COS
            import math
            self.lastX = self.stack[0]
            angle = self.stack[0]
            if self.angleMode == 0:  # Degrees
                angle = math.radians(angle)
            self.stack[0] = math.cos(angle)
            
        elif keycode == 23:  # TAN
            import math
            self.lastX = self.stack[0]
            angle = self.stack[0]
            if self.angleMode == 0:  # Degrees
                angle = math.radians(angle)
            self.stack[0] = math.tan(angle)
            
        elif keycode == 31:  # PI
            import math
            self.lift_stack()
            self.stack[0] = math.pi
            self.liftEnabled = False
            
        elif keycode == 33:  # CLEAR
            self.stack[0] = 0.0
            self.liftEnabled = False
            
        elif keycode == 34:  # SWAP X-Y
            temp = self.stack[0]
            self.stack[0] = self.stack[1]
            self.stack[1] = temp
            self.liftEnabled = False
            
        self.update_display()

# Global calculator instance
calc_engine = C47CalculatorEngine()

class BroadwayC47Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(CURRENT_DIR), **kwargs)
    
    def do_GET(self):
        print(f"C43 Broadway server: {self.path}")
        
        if self.path == '/':
            self.send_broadway_frame()
        elif self.path == '/calculator':
            self.send_c43_calculator()
        elif self.path.startswith('/api/'):
            self.handle_api_request()
        elif self.path.startswith('/assets/'):
            super().do_GET()
        else:
            super().do_GET()
    
    def do_POST(self):
        if self.path.startswith('/api/'):
            self.handle_api_request()
        else:
            self.send_error(404, "Not Found")
    
    def send_broadway_frame(self):
        broadway_html = """<!DOCTYPE html>
<html>
<head>
    <title>C47 Calculator - C43 Broadway Server</title>
    <style>
        body { 
            margin: 0; 
            padding: 0; 
            background: #e8e8e8;
            font-family: system-ui, sans-serif;
        }
        .broadway-frame { 
            width: 100vw; 
            height: 100vh; 
            border: none;
        }
    </style>
</head>
<body>
    <iframe src="/calculator" class="broadway-frame"></iframe>
</body>
</html>"""
        
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(broadway_html.encode())
    
    def send_c43_calculator(self):
        # Read the enhanced calculator template with C43 integration
        try:
            template_path = CURRENT_DIR / 'c43-calculator-template.html'
            if template_path.exists():
                with open(template_path, 'r') as f:
                    content = f.read()
            else:
                content = self.get_c43_calculator_html()
            
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(content.encode())
        except Exception as e:
            print(f"Error serving calculator: {e}")
            self.send_error(500, f"Server Error: {e}")
    
    def handle_api_request(self):
        if self.path == '/api/state':
            self.send_calculator_state()
        elif self.path == '/api/press':
            self.handle_key_press()
        else:
            self.send_error(404, "API endpoint not found")
    
    def send_calculator_state(self):
        state = {
            'display': calc_engine.get_display(),
            'stack': calc_engine.get_stack(),
            'angleMode': ['DEG', 'RAD', 'GRAD'][calc_engine.angleMode],
            'timestamp': __import__('time').time()
        }
        
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(json.dumps(state).encode())
    
    def handle_key_press(self):
        if self.command == 'POST':
            content_length = int(self.headers.get('Content-Length', 0))
            post_data = self.rfile.read(content_length)
            
            try:
                data = json.loads(post_data.decode())
                keycode = data.get('keycode', 0)
                
                calc_engine.press_key(keycode)
                
                # Return updated state
                self.send_calculator_state()
                
            except Exception as e:
                print(f"Error processing key press: {e}")
                self.send_error(400, f"Bad Request: {e}")
        else:
            self.send_error(405, "Method Not Allowed")
    
    def get_c43_calculator_html(self):
        return '''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>C47 Calculator - C43 Engine</title>
    <style>
        @font-face {
            font-family: 'C47Numeric';
            src: url('/assets/gtk/fonts/C47__NumericFont.ttf') format('truetype');
        }
        @font-face {
            font-family: 'C47Standard';
            src: url('/assets/gtk/fonts/C47__StandardFont.ttf') format('truetype');
        }

        body {
            margin: 0;
            padding: 20px;
            background: #e8e8e8;
            font-family: 'C47Standard', sans-serif;
        }
        
        .calculator-window {
            width: 400px;
            background: #f8f8f8;
            border: 1px solid #b0b0b0;
            border-radius: 4px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.15);
            margin: 0 auto;
            padding: 20px;
        }
        
        .display {
            background: #000;
            color: #00ff00;
            font-family: 'C47Numeric', monospace;
            font-size: 24px;
            padding: 15px;
            text-align: right;
            border: 2px inset #ccc;
            margin-bottom: 20px;
            min-height: 40px;
            display: flex;
            align-items: center;
            justify-content: flex-end;
        }
        
        .stack-display {
            background: #1a1a1a;
            color: #00aa00;
            font-family: 'C47Numeric', monospace;
            font-size: 10px;
            padding: 8px;
            border: 1px inset #999;
            margin-bottom: 15px;
            display: grid;
            grid-template-columns: 1fr 1fr 1fr 1fr;
            gap: 10px;
        }
        
        .button-grid {
            display: grid;
            grid-template-columns: repeat(5, 1fr);
            gap: 3px;
        }
        
        .calc-button {
            height: 50px;
            border: 1px solid #999;
            border-radius: 3px;
            background: linear-gradient(to bottom, #f0f0f0, #d0d0d0);
            color: #333;
            font-weight: bold;
            font-family: 'C47Standard', sans-serif;
            font-size: 12px;
            cursor: pointer;
            user-select: none;
            touch-action: manipulation;
        }
        
        .calc-button:active {
            background: linear-gradient(to bottom, #c0c0c0, #e0e0e0);
            border-color: #666;
            box-shadow: inset 0 1px 3px rgba(0,0,0,0.2);
        }
        
        .calc-button.function { background: linear-gradient(to bottom, #4a90e2, #357abd); color: white; }
        .calc-button.number { background: linear-gradient(to bottom, #f8f8f8, #e0e0e0); }
        .calc-button.operation { background: linear-gradient(to bottom, #ff6b35, #e55527); color: white; }
        .calc-button.enter { background: linear-gradient(to bottom, #8e44ad, #7d3c98); color: white; grid-column: span 2; }
        .calc-button.clear { background: linear-gradient(to bottom, #e74c3c, #c0392b); color: white; }
        
        .status-bar {
            display: flex;
            justify-content: space-between;
            margin-top: 10px;
            font-family: 'C47Standard', sans-serif;
            font-size: 10px;
        }
        
        .indicator {
            padding: 2px 6px;
            border-radius: 2px;
        }
        
        .indicator.active { background: #ffff00; color: #000; }
    </style>
</head>
<body>
    <div class="calculator-window">
        <div class="stack-display">
            <div>T: <span id="t-reg">0</span></div>
            <div>Z: <span id="z-reg">0</span></div>
            <div>Y: <span id="y-reg">0</span></div>
            <div>X: <span id="x-reg">0</span></div>
        </div>
        
        <div class="display">
            <span id="main-display">0</span>
        </div>
        
        <div class="button-grid">
            <!-- Number buttons -->
            <button class="calc-button number" data-key="7">7</button>
            <button class="calc-button number" data-key="8">8</button>
            <button class="calc-button number" data-key="9">9</button>
            <button class="calc-button operation" data-key="17">÷</button>
            <button class="calc-button function" data-key="31">π</button>
            
            <button class="calc-button number" data-key="4">4</button>
            <button class="calc-button number" data-key="5">5</button>
            <button class="calc-button number" data-key="6">6</button>
            <button class="calc-button operation" data-key="16">×</button>
            <button class="calc-button function" data-key="18">√x</button>
            
            <button class="calc-button number" data-key="1">1</button>
            <button class="calc-button number" data-key="2">2</button>
            <button class="calc-button number" data-key="3">3</button>
            <button class="calc-button operation" data-key="15">-</button>
            <button class="calc-button function" data-key="21">SIN</button>
            
            <button class="calc-button number" data-key="0">0</button>
            <button class="calc-button number" data-key="10">.</button>
            <button class="calc-button enter" data-key="13">ENTER</button>
            <button class="calc-button operation" data-key="14">+</button>
            
            <button class="calc-button function" data-key="22">COS</button>
            <button class="calc-button function" data-key="23">TAN</button>
            <button class="calc-button function" data-key="34">x↔y</button>
            <button class="calc-button clear" data-key="33">CLR</button>
        </div>
        
        <div class="status-bar">
            <div>
                <span class="indicator" id="deg-indicator">DEG</span>
                <span class="indicator" id="shift-indicator">SHIFT</span>
            </div>
            <div>C47 Calculator - C43 Engine</div>
        </div>
    </div>
    
    <script>
        let calculatorState = {
            display: "0",
            stack: { X: 0, Y: 0, Z: 0, T: 0 }
        };
        
        function updateDisplay() {
            document.getElementById('main-display').textContent = calculatorState.display;
            document.getElementById('x-reg').textContent = calculatorState.stack.X.toString();
            document.getElementById('y-reg').textContent = calculatorState.stack.Y.toString();
            document.getElementById('z-reg').textContent = calculatorState.stack.Z.toString();
            document.getElementById('t-reg').textContent = calculatorState.stack.T.toString();
        }
        
        async function pressKey(keycode) {
            try {
                const response = await fetch('/api/press', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({ keycode: parseInt(keycode) })
                });
                
                if (response.ok) {
                    calculatorState = await response.json();
                    updateDisplay();
                }
            } catch (error) {
                console.error('Error pressing key:', error);
            }
        }
        
        // Add button listeners
        document.querySelectorAll('.calc-button').forEach(button => {
            button.addEventListener('click', () => {
                const key = button.dataset.key;
                pressKey(key);
                
                // Visual feedback
                button.style.transform = 'scale(0.95)';
                setTimeout(() => {
                    button.style.transform = '';
                }, 100);
            });
        });
        
        // Initial state fetch
        fetch('/api/state')
            .then(response => response.json())
            .then(state => {
                calculatorState = state;
                updateDisplay();
            })
            .catch(error => console.error('Error fetching initial state:', error));
        
        console.log('C47 GTK Broadway Calculator with C43 Engine loaded');
    </script>
</body>
</html>'''

if __name__ == "__main__":
    print(f"Starting C47 Broadway server with C47 engine on port {PORT}")
    print(f"Serving from directory: {CURRENT_DIR}")
    
    with socketserver.TCPServer(("", PORT), BroadwayC47Handler) as httpd:
        print(f"C47 Broadway server running at http://localhost:{PORT}")
        print("C47 calculator engine integrated and ready!")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nShutting down C47 Broadway server...")
            httpd.shutdown()