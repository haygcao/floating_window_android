// File: call_kit_service.dart
// Final version: Fixed the fatal error "Undefined name 'body'"

import 'dart:async';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:floating_window_android/floating_window_android.dart';
import 'package:permission_handler/permission_handler.dart';

class CallKitService {
  static void initializeListeners() {
    print("[CallKitService] Initializing CallKit event listener...");
    FlutterCallkitIncoming.onEvent.listen((event) async {
      if (event == null) return;
      print("[CallKitService] >>> Received CallKit Event: ${event.event}");
      print("[CallKitService] >>> Event Body: ${event.body}");

      switch (event.event) {
        case Event.actionCallIncoming:
          // ============ Fatal Error Fix Point ============
          // Previously, I forgot to declare the body variable, now it is correctly declared.
          // Create a Map from event.body, with the variable name body.
          final Map<String, dynamic> body = Map<String, dynamic>.from(
            event.body,
          );

          // Extract additional data from extra
          final Map<String, dynamic> extraData =
              body.containsKey('extra')
                  ? Map<String, dynamic>.from(body['extra'])
                  : {};

          // Construct a properly formatted data package for the UI
          // All 'body' references are now valid because it has been declared above.
          final Map<String, dynamic> callerDataForUI = {
            'configType': 'callerIdUpdate',
            'id': body['id'],
            'nameCaller': body['nameCaller'],
            'handle':
                body['number'] ??
                'No Number', // <-- Get number from body['number']
            'avatar': body['avatar'],
            'country':
                extraData.containsKey('country')
                    ? extraData['country']
                    : 'No Country',
            'area':
                extraData.containsKey('area') ? extraData['area'] : 'No Area',
            'carrier':
                extraData.containsKey('carrier')
                    ? extraData['carrier']
                    : 'AT&T Mobility',
          };

          // Simulate a second data package for SIM card information
          final simData = {
            'configType': 'simUpdate',
            'simSlot': 'SIM 2 (from Event)',
          };

          // Call sequentially
          await showOverlayWindow();
          await shareDataToOverlay(callerDataForUI);

          // Simulate a delay before sending the second data package
          await Future.delayed(const Duration(milliseconds: 500));
          await shareDataToOverlay(simData);
          break;
        case Event.actionCallAccept:
        case Event.actionCallDecline:
        case Event.actionCallEnded:
        case Event.actionCallTimeout:
          await FloatingWindowAndroid.closeOverlay();
          print(
            "[CallKitService] Overlay close command sent due to call event: ${event.event}.",
          );
          break;
        default:
          break;
      }
    });
  }

  static Future<void> showOverlayWindow() async {
    print("[CallKitService] Showing an empty overlay window...");
    try {
      if (await FloatingWindowAndroid.isShowing()) {
        await FloatingWindowAndroid.closeOverlay();
      }
    // 1. 定义你期望的逻辑像素尺寸
      // 将你之前的硬编码值视为逻300素
      const double logicalWidth = 200;
      const double logicalHeight = 900;

      // 2. 从插件可靠地获取设备的像素比
      // 这个调用无论在前台还是后台都有效
      final double pixelRatio = await FloatingWindowAndroid.getDevicePixelRatio();
      print("[CallKitService] Device pixel ratio fetched: $pixelRatio");

      // 3. 计算出原生层需要的物理像素尺寸
      final int physicalWidth = (logicalWidth * pixelRatio).toInt();
      final int physicalHeight = (logicalHeight * pixelRatio).toInt();
      print("[CallKitService] Calculated physical size: ${physicalWidth}x$physicalHeight");

      await FloatingWindowAndroid.showOverlay(
        height: physicalHeight, // <-- 使用物理高度
        width: physicalWidth,   // <-- 使用物理宽度
       
        alignment: OverlayAlignment.center,
        flag: OverlayFlag.lockScreen,
        enableDrag: true,
        positionGravity: PositionGravity.none,

        notificationVisibility: NotificationVisibility.visibilityPublic,
      );
      print("[CallKitService] showOverlay command sent to native.");
    } catch (e) {
      print("[CallKitService] FATAL ERROR during showOverlayWindow: $e");
    }
  }

  static Future<void> shareDataToOverlay(Map<String, dynamic> data) async {
    print("[CallKitService] Sharing data to overlay: $data");
    try {
      await FloatingWindowAndroid.shareData(data);
      print("[CallKitService] shareData command sent to native.");
    } catch (e) {
      print("[CallKitService] FATAL ERROR during shareDataToOverlay: $e");
    }
  }

  static Future<void> testWithComplexMockData() async {
    print("[CallKitService] Testing multi-part data sharing...");

    final callerIdUpdate = {
      'configType': 'callerIdUpdate',
      'id': 'mock_id_${DateTime.now().millisecondsSinceEpoch}',
      'nameCaller': 'Jennifer Aniston',
      'handle': '123-456-7890',
      'avatar': 'https://i.pravatar.cc/150?u=jennifer',
      'country': 'USA',
      'area': 'Los Angeles',
      'carrier': 'AT&T Mobility',
    };

    final simUpdate = {'configType': 'simUpdate', 'simSlot': 'SIM 1'};

    await showOverlayWindow();
    await shareDataToOverlay(callerIdUpdate);
    await Future.delayed(const Duration(milliseconds: 500));
    await shareDataToOverlay(simUpdate);
  }

  static Future<bool> requestAllPermissions() async {
    print("[CallKitService] Requesting permissions...");
    Map<Permission, PermissionStatus> statuses =
        await [Permission.phone, Permission.notification].request();

    bool overlayPermission = await FloatingWindowAndroid.isPermissionGranted();
    if (!overlayPermission) {
      print("[CallKitService] Overlay permission not granted, requesting...");
      await FloatingWindowAndroid.requestPermission();
      overlayPermission = true;
    }

    bool allGranted = overlayPermission;
    statuses.forEach((permission, status) {
      print(
        '[Permission Check] ${permission.toString()}: ${status.toString()}',
      );
      if (!status.isGranted) {
        allGranted = false;
      }
    });

    if (!allGranted) {
      print(
        "[CallKitService] Some permissions were not granted. Opening app settings...",
      );
      await openAppSettings();
    }

    print(
      "[CallKitService] Permissions check finished. All granted status: $allGranted",
    );
    return allGranted;
  }

  static Future<void> showIncomingCallNotification() async {
    print("[CallKitService] Simulating an incoming call notification...");

    final Map<String, dynamic> extraDataForCall = {
      'country': 'USA (from Event)',
      'area': 'LA',
      'carrier': 'Mobile',
    };

    final params = CallKitParams(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nameCaller: 'Simulated Caller',
      appName: 'FloatingWindowExample',
      avatar: 'https://i.pravatar.cc/100',
      handle: '123-456-7890',
      type: 0,
      extra: extraDataForCall,
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#091C40',
        actionColor: '#4CAF50',
      ),
    );
    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }
}
