# C47 WebAssembly Build
# Compiles the authentic C47 core engine to WebAssembly

# Emscripten setup
export EMSDK_ROOT = /home/jhale/projects/c47_v2/emsdk
export PATH := $(EMSDK_ROOT):$(EMSDK_ROOT)/upstream/emscripten:$(PATH)

CC = emcc
CFLAGS = -O3 -Wall -Wno-unused-parameter -Wno-unused-variable
CFLAGS += -s WASM=1 -s EXPORTED_RUNTIME_METHODS='["ccall", "cwrap"]'
CFLAGS += -s EXPORTED_FUNCTIONS='["_malloc", "_free"]'
CFLAGS += -s ALLOW_MEMORY_GROWTH=1
CFLAGS += -s STACK_SIZE=1MB
CFLAGS += -s INITIAL_MEMORY=16MB

# Include directories
CFLAGS += -I../c43/src/c47
CFLAGS += -I../c43/dep/decNumberICU

# Define build target as WebAssembly
CFLAGS += -DPC_BUILD -DWASM_BUILD

# Core C47 source files (no GTK dependencies)
CORE_SOURCES = \
    ../c43/src/c47/stack.c \
    ../c43/src/c47/registers.c \
    ../c43/src/c47/memory.c \
    ../c43/src/c47/mathematics/addition.c \
    ../c43/src/c47/mathematics/subtraction.c \
    ../c43/src/c47/mathematics/multiplication.c \
    ../c43/src/c47/mathematics/division.c \
    ../c43/src/c47/mathematics/sin.c \
    ../c43/src/c47/mathematics/cos.c \
    ../c43/src/c47/mathematics/tan.c \
    ../c43/src/c47/mathematics/ln.c \
    ../c43/src/c47/mathematics/exp.c \
    ../c43/src/c47/mathematics/squareRoot.c \
    ../c43/src/c47/realType.c \
    ../c43/src/c47/assign.c \
    ../c43/src/c47/keyboard.c \
    ../c43/dep/decNumberICU/decNumber.c \
    ../c43/dep/decNumberICU/decContext.c

# WebAssembly interface
WASM_INTERFACE = c47_wasm_interface.c

OUTPUT = c47-core.js

all: $(OUTPUT)

$(OUTPUT): $(WASM_INTERFACE)
	@echo "Building C47 WebAssembly core..."
	@export PATH="$(EMSDK_ROOT):$(EMSDK_ROOT)/upstream/emscripten:$$PATH" && \
	$(CC) $(CFLAGS) -o $(OUTPUT) $(WASM_INTERFACE) -lm

clean:
	rm -f c47-core.js c47-core.wasm

.PHONY: all clean