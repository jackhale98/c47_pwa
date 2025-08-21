#!/bin/bash

# C47 Mobile Access Setup Script
# This script starts the C47 PWA with mobile device access

echo "🚀 Starting C47 Calculator for Mobile Access"
echo "============================================"

# Get local IP address
LOCAL_IP=$(ip addr | grep -E "inet.*wl|inet.*eth" | grep -v 127.0.0.1 | awk '{print $2}' | cut -d/ -f1 | head -1)
echo "📱 Your local IP address: $LOCAL_IP"

# Kill any existing processes
echo "🔄 Cleaning up existing processes..."
pkill -f broadwayd 2>/dev/null
pkill -f "python3 -m http.server" 2>/dev/null
pkill -f c47 2>/dev/null
sleep 2

# Start Broadway daemon
echo "🖥️  Starting Broadway backend..."
broadwayd --port=8080 --address=0.0.0.0 &
BROADWAY_PID=$!
sleep 2

# Start C47 calculator
echo "🧮 Starting C47 Calculator..."
cd /home/jhale/projects/c47_v2/c47-linux-00.109.02.07b11
DISPLAY=:0 GDK_BACKEND=broadway ./c47 --portrait &
C47_PID=$!
sleep 2

# Start PWA server
echo "🌐 Starting PWA frontend server..."
cd /home/jhale/projects/c47_v2/c47-pwa/public
python3 -m http.server 3000 --bind 0.0.0.0 &
PWA_PID=$!

echo ""
echo "✅ C47 Calculator PWA is running!"
echo "=================================="
echo ""
echo "📱 MOBILE ACCESS:"
echo "1. Make sure your mobile device is on the same WiFi network"
echo "2. Open your mobile browser and go to:"
echo "   🔗 http://$LOCAL_IP:3000"
echo ""
echo "💡 TIPS FOR MOBILE:"
echo "• On iOS: Tap 'Share' → 'Add to Home Screen' to install"
echo "• On Android: Tap menu → 'Install app' or 'Add to Home Screen'"
echo "• The app works offline once installed!"
echo ""
echo "🖥️  DESKTOP ACCESS:"
echo "   http://localhost:3000 or http://$LOCAL_IP:3000"
echo ""
echo "🛑 To stop all services: Press Ctrl+C or run: pkill -f broadwayd; pkill -f c47; pkill -f 'python3 -m http.server'"
echo ""
echo "Process IDs:"
echo "  Broadway: $BROADWAY_PID"
echo "  C47: $C47_PID"
echo "  PWA Server: $PWA_PID"

# Keep script running
wait