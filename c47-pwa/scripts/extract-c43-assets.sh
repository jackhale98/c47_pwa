#!/bin/bash
# extract-c43-assets.sh - Extract and prepare C43/C47 assets from GitLab

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
C43_DIR="${PROJECT_ROOT}/../c43"
ASSETS_DIR="${PROJECT_ROOT}/public/assets/gtk"

echo "🔧 C43/C47 Asset Extraction Script"
echo "==================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Function to check command status
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1${NC}"
    else
        echo -e "${RED}❌ $1 failed${NC}"
        exit 1
    fi
}

# Step 1: Clone or update C43 repository
echo -e "\n${YELLOW}Step 1: Fetching C43 source code${NC}"
if [ ! -d "$C43_DIR" ]; then
    echo "Cloning C43 repository from GitLab..."
    git clone https://gitlab.com/rpncalculators/c43.git "$C43_DIR"
    check_status "Repository clone"
else
    echo "Updating existing C43 repository..."
    cd "$C43_DIR"
    git pull
    check_status "Repository update"
fi

# Step 2: Analyze C43 structure
echo -e "\n${YELLOW}Step 2: Analyzing C43 structure${NC}"
cd "$C43_DIR"

echo "Finding build system..."
if [ -f "Makefile" ]; then
    echo "Found Makefile"
    BUILD_SYSTEM="make"
elif [ -f "CMakeLists.txt" ]; then
    echo "Found CMake"
    BUILD_SYSTEM="cmake"
elif [ -f "meson.build" ]; then
    echo "Found Meson"
    BUILD_SYSTEM="meson"
else
    echo "Build system not immediately recognized, searching..."
    find . -maxdepth 2 -name "Makefile*" -o -name "*.pro" -o -name "configure*" | head -5
fi

# Step 3: Extract UI assets
echo -e "\n${YELLOW}Step 3: Extracting UI assets${NC}"
mkdir -p "$ASSETS_DIR"/{ui,icons,themes,fonts,images}

# Find and copy UI files (Glade, UI definitions)
echo "Extracting UI definitions..."
find "$C43_DIR" -name "*.glade" -o -name "*.ui" -o -name "*.xml" 2>/dev/null | while read -r file; do
    if [[ "$file" == *ui* ]] || [[ "$file" == *glade* ]]; then
        cp "$file" "$ASSETS_DIR/ui/" 2>/dev/null && echo "  Copied: $(basename "$file")"
    fi
done

# Find and copy icons
echo "Extracting icons..."
find "$C43_DIR" \( -name "*.png" -o -name "*.svg" -o -name "*.ico" \) 2>/dev/null | while read -r file; do
    if [[ "$file" == *icon* ]] || [[ "$file" == *logo* ]] || [[ "$file" == *calc* ]]; then
        cp "$file" "$ASSETS_DIR/icons/" 2>/dev/null && echo "  Copied: $(basename "$file")"
    fi
done

# Find and copy themes/styles
echo "Extracting themes..."
find "$C43_DIR" -name "*.css" -o -name "*.rc" -o -name "*.theme" 2>/dev/null | while read -r file; do
    cp "$file" "$ASSETS_DIR/themes/" 2>/dev/null && echo "  Copied: $(basename "$file")"
done

# Find and copy fonts
echo "Extracting fonts..."
find "$C43_DIR" -name "*.ttf" -o -name "*.otf" -o -name "*.woff*" 2>/dev/null | while read -r file; do
    cp "$file" "$ASSETS_DIR/fonts/" 2>/dev/null && echo "  Copied: $(basename "$file")"
done

# Step 4: Extract source code structure
echo -e "\n${YELLOW}Step 4: Analyzing source structure${NC}"
echo "Main source files:"
find "$C43_DIR" -maxdepth 2 \( -name "*.c" -o -name "*.cpp" -o -name "*.h" \) | head -20

# Identify main executable
echo -e "\nSearching for main executable..."
find "$C43_DIR" -name "main.c" -o -name "main.cpp" -o -name "*calc*.c" | head -5

# Step 5: Extract GTK dependencies
echo -e "\n${YELLOW}Step 5: Checking GTK dependencies${NC}"
if [ -f "$C43_DIR/configure.ac" ] || [ -f "$C43_DIR/configure.in" ]; then
    echo "Checking configure script for GTK version..."
    grep -i "gtk" "$C43_DIR/configure.ac" 2>/dev/null | head -5
fi

if [ -f "$C43_DIR/CMakeLists.txt" ]; then
    echo "Checking CMake for GTK version..."
    grep -i "gtk" "$C43_DIR/CMakeLists.txt" 2>/dev/null | head -5
fi

# Step 6: Build C43 with Broadway backend
echo -e "\n${YELLOW}Step 6: Building C43 with Broadway backend${NC}"
cd "$C43_DIR"

# Set up Broadway environment
export GDK_BACKEND=broadway
export GTK_BROADWAY=1

# Try to build
if [ "$BUILD_SYSTEM" = "make" ]; then
    echo "Building with Make..."
    make clean 2>/dev/null || true
    make
    check_status "Make build"
    
    # Find the built executable
    EXECUTABLE=$(find . -maxdepth 2 -type f -executable -name "*c43*" -o -name "*c47*" -o -name "*calc*" | head -1)
    if [ -n "$EXECUTABLE" ]; then
        echo "Found executable: $EXECUTABLE"
        cp "$EXECUTABLE" "${PROJECT_ROOT}/docker/c47-simulator"
        check_status "Copy executable"
    fi
elif [ "$BUILD_SYSTEM" = "cmake" ]; then
    echo "Building with CMake..."
    mkdir -p build && cd build
    cmake .. -DGTK_BROADWAY=ON
    make
    check_status "CMake build"
fi

# Step 7: Create asset manifest
echo -e "\n${YELLOW}Step 7: Creating asset manifest${NC}"
cat > "$ASSETS_DIR/manifest.json" << EOF
{
  "version": "1.0.0",
  "extracted_from": "gitlab.com/rpncalculators/c43",
  "extraction_date": "$(date -Iseconds)",
  "assets": {
    "ui_files": $(find "$ASSETS_DIR/ui" -type f 2>/dev/null | wc -l),
    "icons": $(find "$ASSETS_DIR/icons" -type f 2>/dev/null | wc -l),
    "themes": $(find "$ASSETS_DIR/themes" -type f 2>/dev/null | wc -l),
    "fonts": $(find "$ASSETS_DIR/fonts" -type f 2>/dev/null | wc -l)
  }
}
EOF

# Step 8: Generate icon sizes for PWA
echo -e "\n${YELLOW}Step 8: Generating PWA icon sizes${NC}"
if command -v convert &> /dev/null; then
    MAIN_ICON=$(find "$ASSETS_DIR/icons" -name "*.png" | head -1)
    if [ -n "$MAIN_ICON" ]; then
        for size in 48 96 192 512; do
            convert "$MAIN_ICON" -resize ${size}x${size} "$ASSETS_DIR/icons/calculator-${size}.png"
            echo "Generated ${size}x${size} icon"
        done
    fi
else
    echo "ImageMagick not found, skipping icon generation"
fi

# Step 9: Summary
echo -e "\n${GREEN}==================================="
echo "Asset extraction complete!"
echo "===================================${NC}"
echo "Assets extracted to: $ASSETS_DIR"
echo "Build system: $BUILD_SYSTEM"
ls -la "$ASSETS_DIR"

echo -e "\n${YELLOW}Next steps:${NC}"
echo "1. Review extracted assets in $ASSETS_DIR"
echo "2. Run docker/build-broadway.sh to create Broadway container"
echo "3. Test with: docker run -p 8080:8080 c47-broadway"