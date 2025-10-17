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
  static const String openMainApp = "openMainApp";
  static const String closeOverlayFromOverlay = "close";
  static const String overlayControlChannel =
      "floating_window_android/overlay_control";
  static const String isMainAppRunning = "isMainAppRunning";
  static const String isShowing = "isShowing";

  // Message Channel for reliable communication
  static const String messengerChannel = "floating_window_android/messenger";

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

   // --- ADDED: Synchronized with native code, new and retained engine management constants ---

  /// New: Channel method name for manual engine initialization.
  static const String initializeEngine = "initializeEngine";

  /// New: Channel method name for manual engine disposal.
  static const String disposeEngine = "disposeEngine";

  /// Retained: Method name for compatibility with old API.
  static const String preloadFlutterEngine = "preloadFlutterEngine";

  /// Retained: Method name for compatibility with old API.
  static const String isFlutterEnginePreloaded = "isFlutterEnginePreloaded";
  
  /// Retained: Method name for compatibility with old API.
  static const String cleanupPreloadedEngine = "cleanupPreloadedEngine";
}