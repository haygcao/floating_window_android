import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'floating_window_android_method_channel.dart';

abstract class FloatingWindowAndroidPlatform extends PlatformInterface {
  /// Constructs a FloatingWindowAndroidPlatform.
  FloatingWindowAndroidPlatform() : super(token: _token);

  static final Object _token = Object();

  static FloatingWindowAndroidPlatform _instance =
      MethodChannelFloatingWindowAndroid();

  /// The default instance of [FloatingWindowAndroidPlatform] to use.
  ///
  /// Defaults to [MethodChannelFloatingWindowAndroid].
  static FloatingWindowAndroidPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FloatingWindowAndroidPlatform] when
  /// they register themselves.
  static set instance(FloatingWindowAndroidPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  // --- 以下所有已有的方法定义均无改动 ---
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Check if floating window permission is granted
  Future<bool> isPermissionGranted() {
    throw UnimplementedError('isPermissionGranted() has not been implemented.');
  }

  /// Request floating window permission
  Future<bool> requestPermission() {
    throw UnimplementedError('requestPermission() has not been implemented.');
  }

  /// Show floating window
  Future<bool> showOverlay({
    int? height,
    int? width,
    String? alignment,
    String? notificationVisibility,
    String? flag,
    String? overlayTitle,
    String? overlayContent,
    bool? enableDrag,
    String? positionGravity,
    Map<String, dynamic>? startPosition,
  }) {
    throw UnimplementedError('showOverlay() has not been implemented.');
  }

  /// Close floating window
  Future<bool> closeOverlay() {
    throw UnimplementedError('closeOverlay() has not been implemented.');
  }

  /// Check if floating window is currently showing
  Future<bool> isShowing() {
    throw UnimplementedError('isShowing() has not been implemented.');
  }

  /// Update floating window flag
  Future<bool> updateFlag(String flag) {
    throw UnimplementedError('updateFlag() has not been implemented.');
  }

  /// Resize floating window
  Future<bool> resizeOverlay(int width, int height) {
    throw UnimplementedError('resizeOverlay() has not been implemented.');
  }

  /// Move floating window position
  Future<bool> moveOverlay(Map<String, dynamic> position) {
    throw UnimplementedError('moveOverlay() has not been implemented.');
  }

  /// Get current floating window position
  Future<Map<String, dynamic>> getOverlayPosition() {
    throw UnimplementedError('getOverlayPosition() has not been implemented.');
  }

  /// Share data between floating window and main app
  Future<bool> shareData(dynamic data) {
    throw UnimplementedError('shareData() has not been implemented.');
  }

  /// Get floating window event listener
  Stream<dynamic> get overlayListener {
    throw UnimplementedError('overlayListener has not been implemented.');
  }

  /// Check if main app is running in foreground
  Future<bool> isMainAppRunning() {
    throw UnimplementedError('isMainAppRunning() has not been implemented.');
  }

  /// Open main app from floating window
  Future<bool> openMainApp([Map<String, dynamic>? params]) {
    throw UnimplementedError('openMainApp() has not been implemented.');
  }

  // --- ADDED: 新增和保留的引擎管理方法的抽象定义 ---

  /// 确保引擎已初始化的抽象方法。
  Future<bool> initialize() {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  /// 销毁引擎的抽象方法。
  Future<bool> dispose() {
    throw UnimplementedError('dispose() has not been implemented.');
  }

  /// 兼容旧API的抽象方法。
  Future<bool> preloadFlutterEngine(String dartEntryPoint) {
    throw UnimplementedError(
        'preloadFlutterEngine() has not been implemented.');
  }

  /// 兼容旧API的抽象方法。
  Future<bool> isFlutterEnginePreloaded() {
    throw UnimplementedError(
        'isFlutterEnginePreloaded() has not been implemented.');
  }

  /// 兼容旧API的抽象方法。
  Future<bool> cleanupPreloadedEngine() {
    throw UnimplementedError(
        'cleanupPreloadedEngine() has not been implemented.');
  }
}
