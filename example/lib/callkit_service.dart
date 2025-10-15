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
          // 完美的解耦架构：先展示空窗口，再发送数据
          await showOverlay();
          await shareData(event.body);
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
  
  // showOverlay 只负责展示UI容器
  static Future<void> showOverlay() async {
    print("[CallKitService] Showing a raw overlay window...");
    try {
      await FloatingWindowAndroid.closeOverlay();
      await FloatingWindowAndroid.showOverlay(
        height: 900, 
        width: 980,
        alignment: OverlayAlignment.center,
        flag: OverlayFlag.defaultFlag,
        enableDrag: true,
      );
      print("[CallKitService] showOverlay command sent to native.");
    } catch (e) {
      print("[CallKitService] FATAL ERROR during showOverlay: $e");
    }
  }

  // shareData 是唯一的数据发送通道
  static Future<void> shareData(Map<String, dynamic> data) async {
    print("[CallKitService] Sharing data to overlay: $data");
    try {
      await FloatingWindowAndroid.shareData(data);
      print("[CallKitService] shareData command sent to native.");
    } catch (e) {
      print("[CallKitService] FATAL ERROR during shareData: $e");
    }
  }

  static Future<void> showIncomingCallNotification() async {
    print("[CallKitService] Simulating an incoming call notification...");
    final params = CallKitParams(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nameCaller: 'Simulated Caller',
      appName: 'FloatingWindowExample',
      avatar: 'https://i.pravatar.cc/100',
      handle: '123-456-7890',
      type: 0,
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
  
  // 最终的、包含多部分数据发送的测试方法
  static Future<void> testWithComplexMockData() async {
    print("[CallKitService] Testing multi-part data sharing with decoupled architecture...");

    // 步骤 1: 只展示一个空的悬浮窗（UI上会显示加载指示器）
    await showOverlay();

    // 步骤 2: 模拟延迟后，发送第一部分数据（基础信息）

   
   
   
   
   
   

    // 步骤 3: 模拟网络请求，延迟1秒后，发送第二部分数据（来电人详情）
    
    final callerIdUpdate = {
      "handle": '123-456-7890',
      'nameCaller': 'Jennifer Aniston',
      'avatar': 'https://i.pravatar.cc/150?u=jennifer',
      'country': 'USA',
      'area': 'Los Angeles',
      'carrier': 'AT&T Mobility',
    };
    await shareData(callerIdUpdate);

    // 步骤 4: 模拟获取SIM卡信息，又过了1秒，发送第三部分数据
  
    final simUpdate = {
      'simSlot': 'SIM 2',
    };
    await shareData(simUpdate);
  }
}