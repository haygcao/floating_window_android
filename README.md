# Floating Window Android

A Flutter plugin for Android floating windows, providing an easy-to-use and feature-rich floating window solution.

[![Pub](https://img.shields.io/pub/v/floating_window_android.svg)](https://pub.dev/packages/floating_window_android)
[![Platform](https://img.shields.io/badge/Platform-Android-green.svg)](https://pub.dev/packages/floating_window_android)

## Screenshots

<p align="center">
  <img src="screenshots/Screenshot1.png" width="300" alt="Main App Interface"/>
  <img src="screenshots/Screenshot2.png" width="300" alt="Floating Window in Action"/>
</p>

_Left: Main app interface with GitHub events selection. Right: Floating window displaying selected events with draggable functionality._

## Features

- 💪 Display independent Flutter UI in a floating window, running separately from the main app.
- 🔄 Support bidirectional communication and data sharing between floating window and main app.
- 🎯 Customize floating window size, position, and alignment.
- 👆 Support dragging with edge snapping effects.
- 🚥 Multiple interaction modes (click-through, default mode, focus pointer mode).
- 🛎️ Fully customizable notification style and visibility.
- 🔄 Dynamically adjust floating window properties at runtime.
- ⚡ **Automatic engine caching for instant startup**. The engine is prepared when your app starts, ensuring the overlay appears instantly.

## Installation

Add the dependency to your `pubspec.yaml` file:

```yaml
dependencies:
  floating_window_android: ^1.1.2 # Or the latest version
```

## Required Permissions

This plugin requires the `SYSTEM_ALERT_WINDOW` permission to display floating windows. On Android 6.0 (API 23) and above, users need to manually grant this permission. The plugin provides APIs for permission requests and checks.

Ensure you add the following permissions to your `AndroidManifest.xml` file:

```xml
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
```

## Basic Usage

### Initialization and Permission Check

It's crucial to check and request the overlay permission before showing the window.

```dart
// Check if floating window permission is granted
bool granted = await FloatingWindowAndroid.isPermissionGranted();
if (!granted) {
  // Request permission if not granted
  await FloatingWindowAndroid.requestPermission();
}
```

### Display Floating Window

The plugin automatically handles engine preparation. You can show the overlay at any time.

```dart
// Show floating window
await FloatingWindowAndroid.showOverlay(
  width: WindowSize.matchParent, // Or a custom width in pixels
  height: 300, // Or a custom height in pixels
  alignment: OverlayAlignment.top, // Floating window alignment
  flag: OverlayFlag.defaultFlag, // Floating window interaction mode
  enableDrag: true, // Enable dragging
  positionGravity: PositionGravity.auto, // Snapping effect after dragging
  overlayTitle: "My App is Running", // Notification title
  overlayContent: "Tap to open the app", // Notification content
);
```

### Close Floating Window

```dart
// Close floating window from the main app
await FloatingWindowAndroid.closeOverlay();

// Close floating window from within the overlay widget itself
await FloatingWindowAndroid.closeOverlayFromOverlay();
```

### Adjust Floating Window at Runtime

```dart
// Change floating window size
await FloatingWindowAndroid.resizeOverlay(400, 600);

// Move floating window to a new position
await FloatingWindowAndroid.moveOverlay(OverlayPosition(100, 200));

// Update floating window interaction mode (e.g., make it click-through)
await FloatingWindowAndroid.updateFlag(OverlayFlag.clickThrough);
```

### Data Sharing

The plugin uses a reliable messaging channel to ensure data is not lost.

```dart
// Send data from main app to the floating window
await FloatingWindowAndroid.shareData({
  'key': 'value',
  'count': 10,
});

// In your overlay widget, listen for data from the main app
FloatingWindowAndroid.overlayListener.listen((data) {
  // Process received data
  print('Received data in overlay: $data');
});
```

### Open Main App from Floating Window

```dart
// Bring the main app to the foreground from the overlay
await FloatingWindowAndroid.openMainApp();
```

## Engine Management (Advanced)

The plugin automatically manages the Flutter engine for the overlay window. It's created and cached when your app starts, ensuring instant overlay startup. In most cases, you don't need to manage the engine manually.

However, if your app allows users to disable the overlay feature (e.g., switching to a notification-only mode), you can manually dispose of the engine to free up memory.

### Disposing the Engine

Call `dispose()` when the overlay feature is no longer needed.

```dart
// Example: User disables the overlay feature in settings
void onOverlayFeatureDisabled() {
  FloatingWindowAndroid.dispose();
  print('Overlay engine disposed to save memory.');
}
```
**Warning**: After calling `dispose()`, the next call to `showOverlay()` will fail or be slow unless you re-initialize the engine.

### Re-initializing the Engine

If the user re-enables the overlay feature after it has been disposed, you must call `initialize()` to prepare the engine again.

```dart
// Example: User re-enables the overlay feature
void onOverlayFeatureEnabled() {
  FloatingWindowAndroid.initialize();
  print('Overlay engine is being re-initialized.');
}
```

## Floating Window Entry Point

The floating window requires a separate Dart entry point. Define it in your `lib/main.dart` file or another file.

```dart
import 'package:flutter/material.dart';

// Your overlay widget
class MyOverlayWidget extends StatelessWidget {
  const MyOverlayWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("I am an overlay!"));
  }
}

// The entry point for the overlay
@pragma("vm:entry-point")
void overlayMain() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyOverlayWidget(),
    ),
  );
}

// The main app entry point
void main() {
  // It's recommended to initialize bindings here
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    const MaterialApp(
      home: YourMainApp(),
    ),
  );
}
```

## Interaction Modes

Configure the interaction mode via the `flag` parameter in `showOverlay()`:

- `OverlayFlag.clickThrough`: The floating window will not receive any touch events. Clicks pass through to the content behind it.
- `OverlayFlag.defaultFlag`: The floating window can be interacted with, but it won't receive keyboard focus. System gestures (like back) work as expected.
- `OverlayFlag.focusPointer`: The floating window can receive keyboard focus, ideal for overlays with text input fields.

## Position Control

Control the snapping behavior after dragging using `positionGravity`:

- `PositionGravity.none`: The window stays exactly where the drag gesture ends.
- `PositionGravity.left`: The window snaps to the left edge of the screen.
- `PositionGravity.right`: The window snaps to the right edge of the screen.
- `PositionGravity.auto`: The window snaps to the nearest vertical edge (left or right).

## Notes

- This plugin only supports the **Android** platform.
- Android 8.0 (API 26) and above require a foreground service, which displays a persistent notification. This is a system requirement.
- Certain Android manufacturers may have additional restrictions on background processes or overlay windows.
- Always handle permission requests gracefully to provide a good user experience.
- The cached engine consumes additional memory (~20-30MB). Use the `dispose()` method if your app has a state where the overlay is guaranteed not to be used.

## API Reference

See the code documentation for a complete API reference.

## License

```
MIT License
```