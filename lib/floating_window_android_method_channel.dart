import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'constants.dart';

import 'floating_window_android_platform_interface.dart';

/// An implementation of [FloatingWindowAndroidPlatform] that uses method channels.
class MethodChannelFloatingWindowAndroid extends FloatingWindowAndroidPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('floating_window_android');

  /// Event channel for listening to floating window events
  @visibleForTesting
  final eventChannel = const EventChannel(Constants.overlayEventChannel);

  /// Get platform version
  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      Constants.getPlatformVersion,
    );
    return version;
  }

  /// Check floating window permission
  @override
  Future<bool> isPermissionGranted() async {
    final result = await methodChannel.invokeMethod<bool>(
      Constants.isPermissionGranted,
    );
    return result ?? false;
  }

  /// Request floating window permission
  @override
  Future<bool> requestPermission() async {
    final result = await methodChannel.invokeMethod<bool>(
      Constants.requestPermission,
    );
    return result ?? false;
  }

  /// Show floating window
  @override
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
  }) async {
    final Map<String, dynamic> arguments = {
      if (height != null) Constants.height: height,
      if (width != null) Constants.width: width,
      if (alignment != null) Constants.alignment: alignment,
      if (notificationVisibility != null)
        Constants.notificationVisibility: notificationVisibility,
      if (flag != null) Constants.flag: flag,
      if (overlayTitle != null) Constants.overlayTitle: overlayTitle,
      if (overlayContent != null) Constants.overlayContent: overlayContent,
      if (enableDrag != null) Constants.enableDrag: enableDrag,
      if (positionGravity != null) Constants.positionGravity: positionGravity,
      if (startPosition != null) Constants.startPosition: startPosition,
    };
    final result = await methodChannel.invokeMethod<bool>(
      Constants.showOverlay,
      arguments,
    );
    return result ?? false;
  }

  /// Close floating window
  @override
  Future<bool> closeOverlay() async {
    final result = await methodChannel.invokeMethod<bool>(
      Constants.closeOverlay,
    );
    return result ?? false;
  }

  /// Check if floating window is currently showing
  @override
  Future<bool> isShowing() async {
    final result = await methodChannel.invokeMethod<bool>(Constants.isShowing);
    return result ?? false;
  }

  /// Update floating window flag
  @override
  Future<bool> updateFlag(String flag) async {
    final result = await methodChannel.invokeMethod<bool>(
      Constants.updateFlag,
      {Constants.flag: flag},
    );
    return result ?? false;
  }

  /// Resize floating window
  @override
  Future<bool> resizeOverlay(int width, int height) async {
    final result = await methodChannel.invokeMethod<bool>(
      Constants.resizeOverlay,
      {Constants.width: width, Constants.height: height},
    );
    return result ?? false;
  }

  /// Move floating window position
  @override
  Future<bool> moveOverlay(Map<String, dynamic> position) async {
    final result = await methodChannel.invokeMethod<bool>(
      Constants.moveOverlay,
      position,
    );
    return result ?? false;
  }

  /// Get current floating window position
  @override
  Future<Map<String, dynamic>> getOverlayPosition() async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      Constants.getOverlayPosition,
    );
    return result ?? {'x': 0, 'y': 0};
  }

  /// Share data between floating window and main app
  @override
  Future<bool> shareData(dynamic data) async {
    final result = await methodChannel.invokeMethod<bool>(Constants.shareData, {
      Constants.data: data,
    });
    return result ?? false;
  }

  /// Get floating window event listener
  @override
  Stream<dynamic> get overlayListener {
    return eventChannel.receiveBroadcastStream();
  }

  /// Check if main app is running in foreground
  @override
  Future<bool> isMainAppRunning() async {
    final result = await methodChannel.invokeMethod<bool>(
      Constants.isMainAppRunning,
    );
    return result ?? false;
  }

  /// Preload Flutter engine for faster overlay startup
  @override
  Future<bool> preloadFlutterEngine(String dartEntryPoint) async {
    final result = await methodChannel.invokeMethod<bool>(
      Constants.preloadFlutterEngine,
      {'dartEntryPoint': dartEntryPoint},
    );
    return result ?? false;
  }

  /// Check if Flutter engine is preloaded
  @override
  Future<bool> isFlutterEnginePreloaded() async {
    final result = await methodChannel.invokeMethod<bool>(
      Constants.isFlutterEnginePreloaded,
    );
    return result ?? false;
  }

  /// Clean up preloaded Flutter engine
  @override
  Future<bool> cleanupPreloadedEngine() async {
    final result = await methodChannel.invokeMethod<bool>(
      Constants.cleanupPreloadedEngine,
    );
    return result ?? false;
  }

  @override
  Future<bool> openMainApp([Map<String, dynamic>? params]) async {
    final result = await methodChannel.invokeMethod<bool>(
      Constants.openMainApp,
      params,
    );
    return result ?? false;
  }
}
