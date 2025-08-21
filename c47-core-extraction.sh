#!/bin/bash
# C47 Core Engine Extraction Script
# Systematically identify and extract core calculator functions for mobile integration

echo "🔧 C47 Core Engine Analysis and Extraction"
echo "==========================================="

C43_DIR="/home/jhale/projects/c47_v2/c43"
CORE_DIR="/home/jhale/projects/c47_v2/c47-core"
ANDROID_CPP_DIR="/home/jhale/projects/c47_v2/c47-android/app/src/main/cpp"

mkdir -p "$CORE_DIR"/{headers,source,mathematics,stack,memory,display}
mkdir -p "$ANDROID_CPP_DIR/c47-core"

echo "Step 1: Analyzing C47 source structure..."

# Identify core non-GTK files
echo "=== Core Calculator Files ==="
find "$C43_DIR/src/c47" -name "*.h" -o -name "*.c" | grep -v gtk | head -20

echo -e "\n=== Mathematics Functions ==="
find "$C43_DIR/src/c47/mathematics" -name "*.h" | head -10

echo -e "\n=== Stack Operations ==="
find "$C43_DIR/src/c47" -name "*stack*" -o -name "*register*" | head -5

echo -e "\n=== Memory Operations ==="
find "$C43_DIR/src/c47" -name "*memory*" -o -name "*recall*" -o -name "*store*" | head -5

echo -e "\n=== Display Functions ==="
find "$C43_DIR/src/c47" -name "*display*" -o -name "*screen*" | head -5

# Step 2: Copy essential header files
echo -e "\nStep 2: Copying essential header files..."

# Main calculator headers
cp "$C43_DIR/src/c47/c47.h" "$CORE_DIR/headers/" 2>/dev/null && echo "✅ c47.h"
cp "$C43_DIR/src/c47/defines.h" "$CORE_DIR/headers/" 2>/dev/null && echo "✅ defines.h"
cp "$C43_DIR/src/c47/typeDefinitions.h" "$CORE_DIR/headers/" 2>/dev/null && echo "✅ typeDefinitions.h"

# Stack and register headers
cp "$C43_DIR/src/c47/stack.h" "$CORE_DIR/headers/" 2>/dev/null && echo "✅ stack.h"
cp "$C43_DIR/src/c47/registers.h" "$CORE_DIR/headers/" 2>/dev/null && echo "✅ registers.h"

# Memory headers
cp "$C43_DIR/src/c47/memory.h" "$CORE_DIR/headers/" 2>/dev/null && echo "✅ memory.h"
cp "$C43_DIR/src/c47/store.h" "$CORE_DIR/headers/" 2>/dev/null && echo "✅ store.h"
cp "$C43_DIR/src/c47/recall.h" "$CORE_DIR/headers/" 2>/dev/null && echo "✅ recall.h"

# Display headers
cp "$C43_DIR/src/c47/display.h" "$CORE_DIR/headers/" 2>/dev/null && echo "✅ display.h"

# Step 3: Copy core source files
echo -e "\nStep 3: Copying core source files..."

# Main calculator source
cp "$C43_DIR/src/c47/c47.c" "$CORE_DIR/source/" 2>/dev/null && echo "✅ c47.c"
cp "$C43_DIR/src/c47/calcMode.c" "$CORE_DIR/source/" 2>/dev/null && echo "✅ calcMode.c"

# Stack operations
cp "$C43_DIR/src/c47/stack.c" "$CORE_DIR/source/" 2>/dev/null && echo "✅ stack.c"
cp "$C43_DIR/src/c47/registers.c" "$CORE_DIR/source/" 2>/dev/null && echo "✅ registers.c"

# Memory operations  
cp "$C43_DIR/src/c47/memory.c" "$CORE_DIR/source/" 2>/dev/null && echo "✅ memory.c"
cp "$C43_DIR/src/c47/store.c" "$CORE_DIR/source/" 2>/dev/null && echo "✅ store.c"
cp "$C43_DIR/src/c47/recall.c" "$CORE_DIR/source/" 2>/dev/null && echo "✅ recall.c"

# Display functions
cp "$C43_DIR/src/c47/display.c" "$CORE_DIR/source/" 2>/dev/null && echo "✅ display.c"

# Step 4: Copy essential mathematics functions
echo -e "\nStep 4: Copying mathematics functions..."

# Core math functions
for math_func in addition subtraction multiplication division sqrt exp ln log sin cos tan; do
    if [ -f "$C43_DIR/src/c47/mathematics/${math_func}.c" ]; then
        cp "$C43_DIR/src/c47/mathematics/${math_func}.c" "$CORE_DIR/mathematics/"
        cp "$C43_DIR/src/c47/mathematics/${math_func}.h" "$CORE_DIR/mathematics/" 2>/dev/null
        echo "✅ ${math_func}"
    fi
done

# Step 5: Generate mobile API bridge
echo -e "\nStep 5: Creating mobile API analysis..."

cat > "$CORE_DIR/c47-mobile-api-analysis.md" << 'EOF'
# C47 Mobile API Analysis

## Core Functions Identified

### Stack Operations
- Stack manipulation (push, pop, roll, swap)
- Register access (X, Y, Z, T)
- Stack arithmetic operations

### Mathematics Engine  
- Basic arithmetic (+, -, *, /)
- Transcendental functions (sin, cos, tan, ln, log, exp)
- Power functions (sqrt, x^2, y^x)
- Complex number support

### Memory System
- Storage registers (STO/RCL)
- Program memory
- State persistence

### Display System
- Number formatting
- Display buffer management
- Status indicators

## Integration Strategy

1. **Android JNI**: Expose core functions via JNI bridge
2. **Broadway PWA**: Build GTK version with Broadway backend  
3. **API Consistency**: Maintain consistent API across platforms
EOF

# Step 6: Copy to Android project
echo -e "\nStep 6: Copying to Android project..."

# Copy extracted files to Android native directory
cp -r "$CORE_DIR"/* "$ANDROID_CPP_DIR/c47-core/"
echo "✅ Files copied to Android project"

echo -e "\n🎯 Core extraction completed!"
echo "Files extracted to: $CORE_DIR"
echo "Android integration ready at: $ANDROID_CPP_DIR/c47-core"

# Step 7: Generate build script for Broadway
echo -e "\nStep 7: Creating Broadway build script..."

cat > "$CORE_DIR/build-broadway.sh" << 'EOF'
#!/bin/bash
# Build C47 for GTK Broadway
cd /home/jhale/projects/c47_v2/c43

# Set up Broadway environment
export GDK_BACKEND=broadway
export MESON_BUILD_DIR=build.broadway

# Try basic gcc build if meson fails
if ! command -v meson &> /dev/null; then
    echo "Building with direct GCC..."
    gcc -o c47-broadway \
        -DLINUX -DOS64BIT -DPC_BUILD \
        -I/usr/include/gtk-3.0 \
        -I/usr/include/glib-2.0 \
        -I/usr/lib/x86_64-linux-gnu/glib-2.0/include \
        -I/usr/include/pango-1.0 \
        -I/usr/include/harfbuzz \
        -I/usr/include/cairo \
        -I/usr/include/gdk-pixbuf-2.0 \
        -I/usr/include/atk-1.0 \
        src/c47-gtk/*.c \
        src/c47/*.c \
        -lgtk-3 -lgdk-3 -lglib-2.0 -lgmp -lm
else
    # Use meson if available
    meson setup $MESON_BUILD_DIR --buildtype=custom -DDECNUMBER_FASTMUL=true
    meson compile -C $MESON_BUILD_DIR
fi
EOF

chmod +x "$CORE_DIR/build-broadway.sh"

echo "✅ Broadway build script created"
echo "Run with: $CORE_DIR/build-broadway.sh"