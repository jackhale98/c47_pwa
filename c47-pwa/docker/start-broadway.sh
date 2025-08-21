#!/bin/bash
# start-broadway.sh - Start GTK Broadway server with C47 simulator

echo "Starting C47 GTK Broadway server..."

# Start virtual display
echo "Starting Xvfb virtual display..."
Xvfb :99 -screen 0 1024x768x24 -ac +extension GLX +render -noreset &
XVFB_PID=$!
sleep 2

# Check if Xvfb started successfully
if ! kill -0 $XVFB_PID 2>/dev/null; then
    echo "ERROR: Xvfb failed to start"
    exit 1
fi

# Export display
export DISPLAY=:99
echo "Virtual display started on :99"

# Start D-Bus session (required for some GTK features)
eval $(dbus-launch --sh-syntax)
export DBUS_SESSION_BUS_ADDRESS

# Start Broadway daemon
echo "Starting GTK Broadway daemon on port 8080..."
broadwayd :5 --port 8080 &
BROADWAY_PID=$!
sleep 2

# Check if Broadway started successfully
if ! kill -0 $BROADWAY_PID 2>/dev/null; then
    echo "ERROR: Broadway daemon failed to start"
    kill $XVFB_PID
    exit 1
fi

# Set Broadway display
export GDK_BACKEND=broadway
export BROADWAY_DISPLAY=:5

echo "Broadway server ready on http://localhost:8080"

# Launch C47 simulator
echo "Launching C47 calculator simulator..."
cd /app

# Check if simulator exists
if [ ! -f "./c47-simulator" ]; then
    echo "ERROR: c47-simulator not found!"
    echo "Available files:"
    ls -la
    
    # Fallback: try to find any executable
    EXECUTABLE=$(find . -maxdepth 1 -type f -executable | grep -E "(c43|c47|calc)" | head -1)
    if [ -n "$EXECUTABLE" ]; then
        echo "Found alternative executable: $EXECUTABLE"
        exec "$EXECUTABLE"
    else
        echo "No calculator executable found. Keeping Broadway server running..."
        # Keep the container alive for debugging
        tail -f /dev/null
    fi
else
    # Run the C47 simulator
    exec ./c47-simulator
fi

# Keep container running if simulator exits
wait $BROADWAY_PID