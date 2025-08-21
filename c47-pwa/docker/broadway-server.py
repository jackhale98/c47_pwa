#!/usr/bin/env python3
"""
Simple Broadway mockup server for testing C47 PWA
This serves as a placeholder until the real C43 GTK Broadway build is ready
"""

import http.server
import socketserver
import os
import sys
from pathlib import Path

PORT = 8080
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
        super().__init__(*args, directory="/app", **kwargs)
    
    def do_GET(self):
        if self.path == '/':
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            self.wfile.write(BROADWAY_HTML.encode())
        elif self.path == '/calculator':
            # Serve the calculator mockup
            try:
                with open('/app/broadway-mockup.html', 'r') as f:
                    content = f.read()
                self.send_response(200)
                self.send_header('Content-type', 'text/html')
                self.end_headers()
                self.wfile.write(content.encode())
            except FileNotFoundError:
                self.send_error(404, "Calculator interface not found")
        else:
            # Serve static files
            super().do_GET()

if __name__ == "__main__":
    os.chdir("/app")
    with socketserver.TCPServer(("", PORT), BroadwayHandler) as httpd:
        print(f"C47 Broadway mockup server running on port {PORT}")
        print("Ready to receive PWA connections...")
        httpd.serve_forever()