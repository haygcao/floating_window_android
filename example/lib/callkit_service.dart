// 文件: call_kit_service.dart
// 最终版: 修复了 "Undefined name 'body'" 致命错误

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
          // ============ 致命错误修复点 ============
          // 之前我忘了声明 body 变量，现在已经正确声明。
          // 从 event.body 创建一个 Map，变量名为 body。
          final Map<String, dynamic> body = Map<String, dynamic>.from(event.body);

          // 从 extra 中提取附加数据
          final Map<String, dynamic> extraData = body.containsKey('extra')
              ? Map<String, dynamic>.from(body['extra'])
              : {};

          // 构建一个 UI 需要的、格式正确的数据包
          // 现在所有的 'body' 引用都是合法的，因为上面已经声明了它。
          final Map<String, dynamic> callerDataForUI = {
            'configType': 'callerIdUpdate',
            'id': body['id'],
            'nameCaller': body['nameCaller'],
             'handle': body['number'] ?? 'No Number', // <-- 从 body['number'] 获取号码
            'avatar': body['avatar'],
              'country': extraData.containsKey('country') ? extraData['country'] : 'No Country',
              'area': extraData.containsKey('area') ? extraData['area'] : 'No Area',  
              'carrier': extraData.containsKey('carrier') ? extraData['carrier'] : 'AT&T Mobility',
          };

          // 模拟获取SIM卡信息的第二个数据包
          final simData = {
            'configType': 'simUpdate',
            'simSlot': 'SIM 2 (from Event)',
          };

          // 依次调用
          await showOverlayWindow();
          await shareDataToOverlay(callerDataForUI);

          // 模拟延迟后发送第二个数据包
          await Future.delayed(const Duration(milliseconds: 500));
          await shareDataToOverlay(simData);
          break;
        case Event.actionCallAccept:
        case Event.actionCallDecline:
        case Event.actionCallEnded:
        case Event.actionCallTimeout:
          await FloatingWindowAndroid.closeOverlay();
          print("[CallKitService] Overlay close command sent due to call event: ${event.event}.");
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

      await FloatingWindowAndroid.showOverlay(
        height: 1100,
        width: 980,
        alignment: OverlayAlignment.center,
        flag: OverlayFlag.lockScreen,
        enableDrag: true,
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

    final simUpdate = {
      'configType': 'simUpdate',
      'simSlot': 'SIM 1',
    };

    await showOverlayWindow();
    await shareDataToOverlay(callerIdUpdate);
    await Future.delayed(const Duration(milliseconds: 500));
    await shareDataToOverlay(simUpdate);
  }

  static Future<bool> requestAllPermissions() async {
    print("[CallKitService] Requesting permissions...");
    Map<Permission, PermissionStatus> statuses = await [
      Permission.phone,
      Permission.notification,
    ].request();

    bool overlayPermission = await FloatingWindowAndroid.isPermissionGranted();
    if (!overlayPermission) {
      print("[CallKitService] Overlay permission not granted, requesting...");
      await FloatingWindowAndroid.requestPermission();
      overlayPermission = true;
    }

    bool allGranted = overlayPermission;
    statuses.forEach((permission, status) {
      print('[Permission Check] ${permission.toString()}: ${status.toString()}');
      if (!status.isGranted) {
        allGranted = false;
      }
    });

    if (!allGranted) {
      print("[CallKitService] Some permissions were not granted. Opening app settings...");
      await openAppSettings();
    }

    print("[CallKitService] Permissions check finished. All granted status: $allGranted");
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