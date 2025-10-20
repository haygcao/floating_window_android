import 'package:floating_window_android/floating_window_android_method_channel.dart';
import 'package:flutter/services.dart';
import 'floating_window_android_platform_interface.dart';
import 'constants.dart';

/// Overlay flag types
enum OverlayFlag {
  /// Click through - The floating window never receives touch events, suitable for creating click-through floating windows
  clickThrough,

  /// Default flag - The floating window doesn't get keyboard input focus, user can't send key events or other button events
  defaultFlag,

  /// Focus pointer - Allows pointer events outside the floating window to be sent to the windows behind, suitable for input boxes that need to display a keyboard
  focusPointer,

  /// Lock screen - The floating window will be displayed on the lock screen
  lockScreen,
}

/// Position gravity type - Controls the position behavior of the floating window after dragging
enum PositionGravity {
  /// None - Allows the floating window to be positioned anywhere on the screen
  none,

  /// Right - Allows the floating window to stick to the right side of the screen
  right,

  /// Left - Allows the floating window to stick to the left side of the screen
  left,

  /// Auto - Automatically sticks to the left or right side based on the floating window position
  auto,
}

/// Window size constants
class WindowSize {
  /// Full cover
  static const int fullCover = -1;

  /// Match parent
  static const int matchParent = -1;

  /// Wrap content
  static const int wrapContent = -2;
}

/// Overlay alignment positions
class OverlayAlignment {
  /// Top
  static const String top = "top";

  /// Bottom
  static const String bottom = "bottom";

  /// Left
  static const String left = "left";

  /// Right
  static const String right = "right";

  /// Center
  static const String center = "center";

  /// Top left
  static const String topLeft = "topLeft";

  /// Top right
  static const String topRight = "topRight";

  /// Bottom left
  static const String bottomLeft = "bottomLeft";

  /// Bottom right
  static const String bottomRight = "bottomRight";
}

/// Notification visibility
class NotificationVisibility {
  /// Shows only the existence of the notification on the lock screen, hiding the detailed content.
  static const String visibilitySecret = "VISIBILITY_SECRET";

  /// Fully displays this notification on the lock screen, including all content.
  static const String visibilityPublic = "VISIBILITY_PUBLIC";

  /// Completely hides this notification on the lock screen, not showing any content.
  static const String visibilityPrivate = "VISIBILITY_PRIVATE";
}

/// Overlay position
class OverlayPosition {
  final int x;
  final int y;

  OverlayPosition(this.x, this.y);

  Map<String, dynamic> toJson() => {'x': x, 'y': y};
}

/// Floating Window Android Plugin
class FloatingWindowAndroid {
  /// Get platform version
  Future<String?> getPlatformVersion() {
    return FloatingWindowAndroidPlatform.instance.getPlatformVersion();
  }

  /// Check if floating window permission is granted
  static Future<bool> isPermissionGranted() {
    return FloatingWindowAndroidPlatform.instance.isPermissionGranted();
  }

  /// Request floating window permission
  static Future<bool> requestPermission() {
    return FloatingWindowAndroidPlatform.instance.requestPermission();
  }

  /// Show floating window
  static Future<bool> showOverlay({
    int height = WindowSize.fullCover,
    int width = WindowSize.matchParent,
    String alignment = OverlayAlignment.center,
    String notificationVisibility = NotificationVisibility.visibilitySecret,
    OverlayFlag flag = OverlayFlag.defaultFlag,
    String overlayTitle = "Floating Window Activated",
    String? overlayContent,
    bool enableDrag = false,
    PositionGravity positionGravity = PositionGravity.none,
    OverlayPosition? startPosition,
  }) {
    return FloatingWindowAndroidPlatform.instance.showOverlay(
      height: height,
      width: width,
      alignment: alignment,
      notificationVisibility: notificationVisibility,
      flag: flag.toString().split('.').last,
      overlayTitle: overlayTitle,
      overlayContent: overlayContent,
      enableDrag: enableDrag,
      positionGravity: positionGravity.toString().split('.').last,
      startPosition: startPosition?.toJson(),
    );
  }

  /// Close floating window
  static Future<bool> closeOverlay() {
    return FloatingWindowAndroidPlatform.instance.closeOverlay();
  }

  static Future<bool> isShowing() {
    return FloatingWindowAndroidPlatform.instance.isShowing();
  }

  static Future<bool> updateFlag(OverlayFlag flag) {
    return FloatingWindowAndroidPlatform.instance
        .updateFlag(flag.toString().split('.').last);
  }

  /// Resize floating window
  static Future<bool> resizeOverlay(int width, int height) {
    return FloatingWindowAndroidPlatform.instance.resizeOverlay(width, height);
  }

  /// Move floating window position
  static Future<bool> moveOverlay(OverlayPosition position) {
    return FloatingWindowAndroidPlatform.instance
        .moveOverlay(position.toJson());
  }

  /// Get current floating window position
  static Future<OverlayPosition> getOverlayPosition() async {
    final Map<String, dynamic> position =
        await FloatingWindowAndroidPlatform.instance.getOverlayPosition();
    return OverlayPosition(
        position['x'] as int? ?? 0, position['y'] as int? ?? 0);
  }

  /// Share data between floating window and main app
  static Future<bool> shareData(dynamic data) {
    return FloatingWindowAndroidPlatform.instance.shareData(data);
  }

  /// Get floating window event listener
  static Stream<dynamic> get overlayListener {
    // The underlying implementation was changed to BasicMessageChannel for reliability,
    // but this public API remains the same for the user.
    if (FloatingWindowAndroidPlatform.instance
        is MethodChannelFloatingWindowAndroid) {
      return (FloatingWindowAndroidPlatform.instance
              as MethodChannelFloatingWindowAndroid)
          .overlayListener;
    }
    throw PlatformException(
      code: 'UNAVAILABLE',
      message:
          'Current platform does not support floating window event listener',
    );
  }

  /// Open main app from floating window
  static Future<bool> openMainApp([Map<String, dynamic>? params]) {
    return FloatingWindowAndroidPlatform.instance.openMainApp(params);
  }

  /// Close floating window from within the floating window
  static Future<void> closeOverlayFromOverlay() async {
// Use specific channel to communicate with native service
    const MethodChannel channel =
        MethodChannel(Constants.overlayControlChannel);
    try {
      await channel.invokeMethod(Constants.closeOverlayFromOverlay);
    } on PlatformException catch (e) {
      throw PlatformException(
        code: 'UNAVAILABLE',
        message: 'Failed to close from floating window: ${e.message}',
      );
    }
  }

  /// Check if main app is running in foreground
  static Future<bool> isMainAppRunning() {
    return FloatingWindowAndroidPlatform.instance.isMainAppRunning();
  }

  // --- ADDED: New, recommended engine management API ---

  /// Ensures the floating window engine is ready.
  ///
  /// In the new architecture, the engine is automatically initialized when the app starts,
  /// so you typically don't need to call this method.
  /// The only exception is if you previously called [dispose] to destroy the engine
  /// and now wish to use the floating window functionality again
  /// (e.g., the user switches from "notification only" mode back to "floating window" mode).
  /// In such cases, you need to manually call this method to recreate the engine.
  static Future<bool> initialize() {
    return FloatingWindowAndroidPlatform.instance.initialize();
  }

  /// Destroys the floating window engine to free up memory.
  ///
  /// Call this method when you are certain that you will not need the floating window
  /// functionality for a while (e.g., the user switches to "notification only" mode
  /// in settings). This will completely release the tens of megabytes of memory
  /// occupied by the engine.
  ///
  /// **Important Note:** After destroying the engine, the next call to [showOverlay]
  /// will fail or not achieve "instant-on" functionality, unless you first call
  /// [initialize] to prepare the engine again.
  static Future<bool> dispose() {
    return FloatingWindowAndroidPlatform.instance.dispose();
  }

  // --- ADDED: Annotations for old, deprecated APIs ---

  /// **Deprecated**: This method has no practical effect in the new architecture and should not be used.
  ///
  /// The engine is now automatically preloaded when the app starts. This method is retained
  /// only for backward compatibility and may be removed in future versions.
  ///
  /// If you need to recreate an engine that was [dispose]d, please use the [initialize] method instead.
  @Deprecated(
      'The engine is now managed automatically. Use initialize() if you need to recreate the engine after a dispose() call. This method will be removed in a future version.')
  static Future<bool> preloadFlutterEngine({
    String dartEntryPoint = "overlayMain",
  }) {
    return FloatingWindowAndroidPlatform.instance
        .preloadFlutterEngine(dartEntryPoint);
  }

  /// **Deprecated**: The behavior of this method has changed and it is not recommended for use.
  ///
  /// It now only checks if the automatically cached engine currently exists in memory.
  /// If you called [dispose], this method will return `false`.
  /// This method is retained only for backward compatibility and may be removed in future versions.
  @Deprecated(
      'The engine is now managed automatically. Its behavior has changed. This method will be removed in a future version.')
  static Future<bool> isFlutterEnginePreloaded() {
    return FloatingWindowAndroidPlatform.instance.isFlutterEnginePreloaded();
  }

  /// **Deprecated**: Please use the new [dispose] method instead.
  ///
  /// This method now internally calls [dispose] directly to perform cleanup operations.
  /// Its existence is solely for backward compatibility and it may be removed in future versions.
  @Deprecated(
      'Use dispose() instead. This method will be removed in a future version.')
  static Future<bool> cleanupPreloadedEngine() {
    return FloatingWindowAndroidPlatform.instance.cleanupPreloadedEngine();
  }

 // --- ADDED: New API for getting device pixel ratio ---
  static Future<double> getDevicePixelRatio() {
    return FloatingWindowAndroidPlatform.instance.getDevicePixelRatio();
  }


}
