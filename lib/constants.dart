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

   // --- ADDED: 与原生代码同步，新增和保留引擎管理相关的常量 ---

  /// 新增: 用于手动初始化引擎的通道方法名。
  static const String initializeEngine = "initializeEngine";

  /// 新增: 用于手动销毁引擎的通道方法名。
  static const String disposeEngine = "disposeEngine";

  /// 保留: 兼容旧API的方法名。
  static const String preloadFlutterEngine = "preloadFlutterEngine";

  /// 保留: 兼容旧API的方法名。
  static const String isFlutterEnginePreloaded = "isFlutterEnginePreloaded";
  
  /// 保留: 兼容旧API的方法名。
  static const String cleanupPreloadedEngine = "cleanupPreloadedEngine";
}