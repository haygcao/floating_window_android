import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'constants.dart';
import 'floating_window_android_platform_interface.dart';

/// 使用MethodChannel与原生平台通信的具体实现。
class MethodChannelFloatingWindowAndroid extends FloatingWindowAndroidPlatform {
  /// 用于与原生插件通信的主MethodChannel。
  @visibleForTesting
  final methodChannel = const MethodChannel('floating_window_android');

  /// 用于可靠数据传输的BasicMessageChannel。
  final BasicMessageChannel<dynamic> _messageChannel =
      const BasicMessageChannel(Constants.messengerChannel, JSONMessageCodec());

  /// 用于向Dart代码广播从原生接收到的数据的StreamController。
  StreamController<dynamic>? _streamController;

  MethodChannelFloatingWindowAndroid() {
    _streamController = StreamController<dynamic>.broadcast();
    _messageChannel.setMessageHandler((message) async {
      _streamController?.add(message);
      return message;
    });
  }

  // --- 以下所有已有的方法实现均无改动 ---
  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      Constants.getPlatformVersion,
    );
    return version;
  }

  @override
  Future<bool> isPermissionGranted() async {
    final result = await methodChannel.invokeMethod<bool>(
      Constants.isPermissionGranted,
    );
    return result ?? false;
  }

  @override
  Future<bool> requestPermission() async {
    final result = await methodChannel.invokeMethod<bool>(
      Constants.requestPermission,
    );
    return result ?? false;
  }

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

  @override
  Future<bool> closeOverlay() async {
    final result = await methodChannel.invokeMethod<bool>(
      Constants.closeOverlay,
    );
    return result ?? false;
  }

  @override
  Future<bool> isShowing() async {
    final result = await methodChannel.invokeMethod<bool>(Constants.isShowing);
    return result ?? false;
  }

  @override
  Future<bool> updateFlag(String flag) async {
    final result = await methodChannel.invokeMethod<bool>(
      Constants.updateFlag,
      {Constants.flag: flag},
    );
    return result ?? false;
  }

  @override
  Future<bool> resizeOverlay(int width, int height) async {
    final result = await methodChannel.invokeMethod<bool>(
      Constants.resizeOverlay,
      {Constants.width: width, Constants.height: height},
    );
    return result ?? false;
  }

  @override
  Future<bool> moveOverlay(Map<String, dynamic> position) async {
    final result = await methodChannel.invokeMethod<bool>(
      Constants.moveOverlay,
      position,
    );
    return result ?? false;
  }

  @override
  Future<Map<String, dynamic>> getOverlayPosition() async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      Constants.getOverlayPosition,
    );
    return result ?? {'x': 0, 'y': 0};
  }

  @override
  Future<bool> shareData(dynamic data) async {
    // This now sends the data to the main app's plugin, which then forwards it
    // through the BasicMessageChannel to the overlay.
    await methodChannel
        .invokeMethod(Constants.shareData, {Constants.data: data});
    return true;
  }

  @override
  Stream<dynamic> get overlayListener {
    // Return the stream from the controller which is fed by the BasicMessageChannel
    _streamController ??= StreamController<dynamic>.broadcast();
    return _streamController!.stream;
  }

  @override
  Future<bool> isMainAppRunning() async {
    final result = await methodChannel.invokeMethod<bool>(
      Constants.isMainAppRunning,
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

  // --- ADDED: 新增和废弃API的具体实现 ---

  @override
  Future<bool> initialize() async {
    // 调用原生方法，确保引擎被创建。
    final result =
        await methodChannel.invokeMethod<bool>(Constants.initializeEngine);
    return result ?? false;
  }

  @override
  Future<bool> dispose() async {
    // 调用原生方法，销毁引擎以释放内存。
    final result =
        await methodChannel.invokeMethod<bool>(Constants.disposeEngine);
    return result ?? false;
  }

  @override
  Future<bool> preloadFlutterEngine(String dartEntryPoint) async {
    // 调用对应的原生方法。在新架构中，原生端对此调用不做任何操作，直接返回成功。
    final result = await methodChannel.invokeMethod<bool>(
        Constants.preloadFlutterEngine, {'dartEntryPoint': dartEntryPoint});
    return result ?? true; // 默认为true，因为引擎是自动加载的
  }

  @override
  Future<bool> isFlutterEnginePreloaded() async {
    // 调用原生方法，检查自动缓存的引擎是否存在。
    final result = await methodChannel
        .invokeMethod<bool>(Constants.isFlutterEnginePreloaded);
    return result ?? false;
  }

  @override
  Future<bool> cleanupPreloadedEngine() async {
    // 将旧的cleanup调用路由到新的dispose逻辑。
    final result = await methodChannel
        .invokeMethod<bool>(Constants.cleanupPreloadedEngine);
    return result ?? false;
  }
}
