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

  // --- ADDED: 新增的、推荐使用的引擎管理API ---

  /// 确保悬浮窗引擎已准备就绪。
  ///
  /// 在新的架构中，引擎会在App启动时自动初始化，所以通常你不需要调用此方法。
  /// 唯一的例外是：当你之前调用了 [dispose] 来销毁引擎后，又希望再次使用悬浮窗功能时
  /// (例如，用户从“仅通知”模式切换回“悬浮窗”模式)，你需要手动调用此方法来重新创建引擎。
  static Future<bool> initialize() {
    return FloatingWindowAndroidPlatform.instance.initialize();
  }

  /// 销毁悬浮窗引擎以释放内存。
  ///
  /// 当你确定在接下来的一段时间内不再需要悬浮窗功能时（例如，用户在设置中
  /// 切换到了“仅通知”模式），调用此方法。这将完全释放引擎占用的几十兆内存。
  ///
  /// **重要提示:** 销毁引擎后，下一次调用 [showOverlay] 将会失败或无法“秒开”，
  /// 除非你首先调用 [initialize] 来重新准备引擎。
  static Future<bool> dispose() {
    return FloatingWindowAndroidPlatform.instance.dispose();
  }

  // --- ADDED: 对旧的、不推荐使用的API进行注解 ---

  /// **已废弃**: 此方法在新架构中已无实际作用，请不要使用。
  ///
  /// 引擎现在会在App启动时自动预加载。此方法仅为保持旧版本兼容性而保留，
  /// 在未来的版本中可能会被移除。
  ///
  /// 如果你需要重新创建被 [dispose] 的引擎，请改用 [initialize] 方法。
  @Deprecated(
      'The engine is now managed automatically. Use initialize() if you need to recreate the engine after a dispose() call. This method will be removed in a future version.')
  static Future<bool> preloadFlutterEngine({
    String dartEntryPoint = "overlayMain",
  }) {
    return FloatingWindowAndroidPlatform.instance
        .preloadFlutterEngine(dartEntryPoint);
  }

  /// **已废弃**: 此方法的行为已改变，不推荐使用。
  ///
  /// 现在它仅检查自动缓存的引擎当前是否存在于内存中。如果你调用了 [dispose]，
  /// 此方法将返回`false`。
  /// 此方法仅为保持旧版本兼容性而保留，在未来的版本中可能会被移除。
  @Deprecated(
      'The engine is now managed automatically. Its behavior has changed. This method will be removed in a future version.')
  static Future<bool> isFlutterEnginePreloaded() {
    return FloatingWindowAndroidPlatform.instance.isFlutterEnginePreloaded();
  }

  /// **已废弃**: 请改用新的 [dispose] 方法。
  ///
  /// 此方法现在内部会直接调用 [dispose] 来执行清理操作。
  /// 它的存在仅为保持旧版本兼容性，在未来的版本中可能会被移除。
  @Deprecated(
      'Use dispose() instead. This method will be removed in a future version.')
  static Future<bool> cleanupPreloadedEngine() {
    return FloatingWindowAndroidPlatform.instance.cleanupPreloadedEngine();
  }
}
