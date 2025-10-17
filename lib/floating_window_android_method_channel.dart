import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'constants.dart';

import 'floating_window_android_platform_interface.dart';

class MethodChannelFloatingWindowAndroid extends FloatingWindowAndroidPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('floating_window_android');

  // Use BasicMessageChannel for reliable data transfer
  final BasicMessageChannel<dynamic> _messageChannel =
      BasicMessageChannel(Constants.messengerChannel, JSONMessageCodec());

  // Stream controller to broadcast received messages
  StreamController<dynamic>? _streamController;

  MethodChannelFloatingWindowAndroid() {
    _streamController = StreamController<dynamic>.broadcast();
    _messageChannel.setMessageHandler((message) async {
      _streamController?.add(message);
      return message;
    });
  }

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
  
  // These are now no-ops as engine management is handled natively
  // But we keep the API for compatibility
  @override
  Future<bool> preloadFlutterEngine(String dartEntryPoint) async {
    return true; // Assume success, handled by native plugin attachment
  }

  @override
  Future<bool> isFlutterEnginePreloaded() async {
    return true; // Assume true if plugin is attached
  }

  @override
  Future<bool> cleanupPreloadedEngine() async {
    return true; // Handled by native service destruction
  }
}