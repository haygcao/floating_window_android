/// Method name constants
class Constants {
  static const String getPlatformVersion = "getPlatformVersion";
  static const String isPermissionGranted = "isPermissionGranted";
  static const String requestPermission = "requestPermission";
  static const String showOverlay = "showOverlay";
  static const String closeOverlay = "closeOverlay";
  static const String updateFlag = "updateFlag";
  static const String resizeOverlay = "resizeOverlay";
  static const String moveOverlay = "moveOverlay";
  static const String getOverlayPosition = "getOverlayPosition";
  static const String shareData = "shareData";
  static const String openMainApp = "openMainApp"; // Added method name
  static const String closeOverlayFromOverlay =
      "close"; // Added: Close from within the floating window
  static const String overlayControlChannel =
      "floating_window_android/overlay_control"; // Added
  static const String isMainAppRunning =
      "isMainAppRunning"; // Check if the main app is running in foreground
  static const String navigateToPage =
      "navigateToPage"; // Navigate to specified page
  static const String isShowing = "isShowing";

  // Event channels
  static const String overlayEventChannel =
      "floating_window_android/overlay_listener";

  static const String navigationEventChannel =
      "com.maojiu.floating_window_android_example/navigation";

  // Parameter constants
  static const String height = "height";
  static const String width = "width";
  static const String alignment = "alignment";
  static const String notificationVisibility = "notificationVisibility";
  static const String flag = "flag";
  static const String overlayTitle = "overlayTitle";
  static const String overlayContent = "overlayContent";
  static const String enableDrag = "enableDrag";
  static const String positionGravity = "positionGravity";
  static const String startPosition = "startPosition";
  static const String x = "x";
  static const String y = "y";
  static const String data = "data";

  // Flutter engine preloading methods for faster overlay startup
  static const String preloadFlutterEngine = "preloadFlutterEngine";
  static const String isFlutterEnginePreloaded = "isFlutterEnginePreloaded";
  static const String cleanupPreloadedEngine = "cleanupPreloadedEngine";
}
