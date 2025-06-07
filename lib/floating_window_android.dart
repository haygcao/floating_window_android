import 'package:flutter/services.dart';
import 'floating_window_android_platform_interface.dart';
import 'floating_window_android_method_channel.dart';
import 'constants.dart';

/// Overlay flag types
enum OverlayFlag {
  /// Click through - The floating window never receives touch events, suitable for creating click-through floating windows
  clickThrough,

  /// Default flag - The floating window doesn't get keyboard input focus, user can't send key events or other button events
  defaultFlag,

  /// Focus pointer - Allows pointer events outside the floating window to be sent to the windows behind, suitable for input boxes that need to display a keyboard
  focusPointer,
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

  /// Update floating window flag
  static Future<bool> updateFlag(OverlayFlag flag) {
    return FloatingWindowAndroidPlatform.instance.updateFlag(
      flag.toString().split('.').last,
    );
  }

  /// Resize floating window
  static Future<bool> resizeOverlay(int width, int height) {
    return FloatingWindowAndroidPlatform.instance.resizeOverlay(width, height);
  }

  /// Move floating window position
  static Future<bool> moveOverlay(OverlayPosition position) {
    return FloatingWindowAndroidPlatform.instance.moveOverlay(
      position.toJson(),
    );
  }

  /// Get current floating window position
  static Future<OverlayPosition> getOverlayPosition() async {
    final Map<String, dynamic> position =
        await FloatingWindowAndroidPlatform.instance.getOverlayPosition();
    return OverlayPosition(
      position['x'] as int? ?? 0,
      position['y'] as int? ?? 0,
    );
  }

  /// Share data between floating window and main app
  static Future<bool> shareData(dynamic data) {
    return FloatingWindowAndroidPlatform.instance.shareData(data);
  }

  /// Get floating window event listener
  static Stream<dynamic> get overlayListener {
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
    const MethodChannel channel = MethodChannel(
      Constants.overlayControlChannel,
    );
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

  /// Checks if the overlay window is currently being shown.
  static Future<bool> isShowing() {
    return FloatingWindowAndroidPlatform.instance.isShowing();
  }

  /// Preload Flutter engine for faster overlay startup
  /// Call this method during app initialization to warm up the engine
  /// [dartEntryPoint] - The Dart entry point for the overlay (default: "overlayMain")
  static Future<bool> preloadFlutterEngine({
    String dartEntryPoint = "overlayMain",
  }) {
    return FloatingWindowAndroidPlatform.instance.preloadFlutterEngine(
      dartEntryPoint,
    );
  }

  /// Check if Flutter engine is preloaded and ready for fast overlay startup
  static Future<bool> isFlutterEnginePreloaded() {
    return FloatingWindowAndroidPlatform.instance.isFlutterEnginePreloaded();
  }

  /// Clean up preloaded Flutter engine to free memory
  /// Call this when the app is being destroyed or no longer needs overlay functionality
  static Future<bool> cleanupPreloadedEngine() {
    return FloatingWindowAndroidPlatform.instance.cleanupPreloadedEngine();
  }
}
