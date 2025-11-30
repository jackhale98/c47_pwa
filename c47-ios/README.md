# C47 Calculator for iOS

A native iOS port of the C47 scientific RPN calculator.

## Overview

C47 Calculator is a feature-rich RPN (Reverse Polish Notation) calculator based on the open-source C47 calculator project. This iOS app provides a native Swift/SwiftUI implementation with full access to the C47 calculation engine.

## Features

- **RPN Stack Operations**: Full 4-level stack (X, Y, Z, T) with lift, drop, swap, and roll
- **Scientific Functions**: Trigonometric, logarithmic, exponential, and power functions
- **Angle Modes**: Degrees, radians, and gradians
- **Memory Registers**: 100 storage registers (0-99)
- **State Persistence**: Automatic save/restore of calculator state
- **Native iOS UI**: SwiftUI interface optimized for iPhone
- **Haptic Feedback**: Tactile response on button presses
- **Portrait & Landscape**: Adaptive layouts for all orientations

## Architecture

```
┌─────────────────────────────────────────────┐
│            SwiftUI Views                    │
│  CalculatorView, DisplayView, KeypadView    │
└─────────────────────────────────────────────┘
                      │
┌─────────────────────┴───────────────────────┐
│         CalculatorViewModel (MVVM)          │
│    ObservableObject with Published state    │
└─────────────────────────────────────────────┘
                      │
┌─────────────────────┴───────────────────────┐
│            C47Engine.swift                  │
│    Thread-safe Swift wrapper for C bridge   │
└─────────────────────────────────────────────┘
                      │
┌─────────────────────┴───────────────────────┐
│          c47-ios-bridge.c/h                 │
│     C bridge layer for iOS platform         │
└─────────────────────────────────────────────┘
                      │
┌─────────────────────┴───────────────────────┐
│           C47 Core Engine (C)               │
│   35+ source files with RPN stack/math      │
└─────────────────────────────────────────────┘
```

## Requirements

- iOS 15.0+
- Xcode 14.0+
- Swift 5.9+

## Building

### Using Xcode

1. Open `c47-ios` folder in Xcode
2. Create a new iOS App project
3. Add the existing files from the `C47` folder
4. Configure the bridging header:
   - Build Settings → Swift Compiler - General → Objective-C Bridging Header
   - Set to: `$(SRCROOT)/C47/Bridge/C47-Bridging-Header.h`
5. Add C source files to the target
6. Build and run

### Using Swift Package Manager

```bash
cd c47-ios
swift build
swift test
```

## Project Structure

```
c47-ios/
├── C47/
│   ├── App/
│   │   └── C47App.swift           # App entry point
│   ├── Bridge/
│   │   ├── C47-Bridging-Header.h  # Swift-C bridge
│   │   ├── c47-ios-bridge.c/h     # iOS C bridge layer
│   │   └── C47Engine.swift        # Swift engine wrapper
│   ├── Core/
│   │   ├── headers/               # C47 header files
│   │   ├── source/                # C47 core implementation
│   │   └── mathematics/           # Math functions
│   ├── Models/
│   │   ├── KeyCode.swift          # Key code definitions
│   │   ├── AngleMode.swift        # Angle mode enum
│   │   └── CalculatorState.swift  # State model
│   ├── ViewModels/
│   │   └── CalculatorViewModel.swift
│   ├── Views/
│   │   ├── CalculatorView.swift   # Main view
│   │   ├── DisplayView.swift      # Display component
│   │   ├── KeypadView.swift       # Button grid
│   │   └── StackView.swift        # Stack display
│   ├── Resources/
│   │   ├── Fonts/                 # C47 custom fonts
│   │   ├── Assets.xcassets        # App icons & colors
│   │   └── Info.plist             # App configuration
│   └── Tests/
│       ├── C47EngineTests/        # Engine unit tests
│       └── ViewModelTests/        # ViewModel tests
├── Package.swift                  # Swift Package Manager config
└── README.md                      # This file
```

## Key Components

### C47Engine

The `C47Engine` class provides a thread-safe Swift interface to the C calculator engine:

```swift
let engine = C47Engine.shared

// Press keys
engine.pressKey(.digit5)
engine.pressKey(.enter)
engine.pressKey(.digit3)
engine.pressKey(.plus)

// Get state
let state = engine.getState()
print(state.display)  // "8"

// Angle mode
engine.setAngleMode(.radians)
```

### CalculatorViewModel

The `CalculatorViewModel` follows the MVVM pattern with published properties:

```swift
@StateObject private var viewModel = CalculatorViewModel()

// Use in SwiftUI
Text(viewModel.display)
Text(viewModel.stackY)
Text(viewModel.angleMode.label)
```

### KeyCode

All calculator keys are defined in the `KeyCode` enum:

```swift
enum KeyCode: Int32 {
    case digit0 = 0
    case digit1 = 1
    // ... digits 2-9
    case enter = 13
    case plus = 20
    case sin = 40
    case ln = 50
    // ... etc
}
```

## Testing

Run unit tests:

```bash
swift test
```

Or in Xcode: Product → Test (⌘U)

Test coverage includes:
- Basic arithmetic operations
- Stack operations (enter, swap, roll, drop)
- Scientific functions (trig, log, exp)
- Angle mode conversions
- Error handling
- State persistence

## License

This project is licensed under GPL-3.0 - see the original C47 project for details.

## Credits

- [C47 Calculator Project](https://47calc.com/)
- [C47 Unofficial Documentation](https://c47.miraheze.org/wiki/Main_Page)
- [RPN Calculators GitLab](https://gitlab.com/rpncalculators/c43)
- The WP43 and C47 Authors

## Contributing

Contributions are welcome! Please ensure any changes:
1. Follow the existing code style
2. Include appropriate unit tests
3. Update documentation as needed
4. Maintain GPL-3.0 license compatibility
