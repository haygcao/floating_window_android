## 1.1.0

### Added

- **Flutter Engine Preloading**: Added `preloadFlutterEngine()`, `isFlutterEnginePreloaded()`, and `cleanupPreloadedEngine()` methods to significantly reduce floating window startup time
- Performance optimization with preloaded engines reduces first overlay display time from ~2-3 seconds to ~1 second
- Memory management APIs for better control over preloaded engine lifecycle

### Fixed

- **System Gesture Navigation**: Fixed issue where system swipe-back gesture was not working properly when floating window was active
- Improved touch event handling to prevent interference with system navigation gestures

### Changed

- **Updated Example App**: Completely redesigned example application with GitHub events monitoring functionality
- Enhanced example demonstrates real-world usage patterns including data sharing, periodic updates, and user interaction
- Improved example UI with modern Material Design components and better user experience
- Added comprehensive demonstration of all plugin features including preloaded engines

### Improved

- Better error handling and logging throughout the plugin
- Enhanced documentation with performance optimization guidelines
- Added detailed implementation examples for preloaded engines

## 1.0.0

- Initial release of floating_window_android
- Added support for displaying independent Flutter UI in a floating window
- Implemented bidirectional communication and data sharing between floating window and main app
- Added customization options for floating window size, position, and alignment
- Implemented support for dragging with edge snapping effects
- Added multiple interaction modes (click-through, default mode, focus pointer mode)
- Implemented customizable notification style and visibility
- Added dynamic adjustment of floating window properties at runtime
- Added API for permission requests and checks
- Implemented position control with multiple gravity options

## 0.0.1

- Initial development version
