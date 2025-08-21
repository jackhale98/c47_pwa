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
