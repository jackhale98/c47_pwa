#!/usr/bin/env python3
"""
Local Broadway mockup server for testing C47 PWA
"""

import http.server
import socketserver
import os
from pathlib import Path

PORT = 8080
CURRENT_DIR = Path(__file__).parent

BROADWAY_HTML = """<!DOCTYPE html>
<html>
<head>
    <title>C47 Calculator - Broadway Server</title>
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

class BroadwayHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(CURRENT_DIR), **kwargs)
    
    def do_GET(self):
        print(f"Broadway server: {self.path}")
        
        if self.path == '/':
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(BROADWAY_HTML.encode())
        elif self.path == '/calculator':
            # Serve the calculator mockup
            try:
                mockup_path = CURRENT_DIR / 'broadway-mockup.html'
                with open(mockup_path, 'r') as f:
                    content = f.read()
                self.send_response(200)
                self.send_header('Content-type', 'text/html')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(content.encode())
            except FileNotFoundError:
                self.send_error(404, f"Calculator interface not found at {mockup_path}")
        elif self.path.startswith('/assets/'):
            # Handle asset requests
            super().do_GET()
        else:
            # Serve static files
            super().do_GET()

if __name__ == "__main__":
    print(f"Starting C47 Broadway mockup server on port {PORT}")
    print(f"Serving from directory: {CURRENT_DIR}")
    
    with socketserver.TCPServer(("", PORT), BroadwayHandler) as httpd:
        print(f"C47 Broadway server running at http://localhost:{PORT}")
        print("Ready to receive PWA connections...")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nShutting down Broadway server...")
            httpd.shutdown()