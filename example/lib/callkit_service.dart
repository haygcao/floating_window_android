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
      // --- 核心修复：添加详细日志 ---
      print("[CallKitService] >>> Received CallKit Event: ${event.event}");
      print("[CallKitService] >>> Event Body: ${event.body}");
      
      switch (event.event) {
        case Event.actionCallIncoming:
          await showOverlay(event.body);
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
    // Requesting multiple permissions at once
    Map<Permission, PermissionStatus> statuses = await [
      Permission.phone,
      Permission.notification,
    ].request();

    // Separately handle the system alert window permission
    bool overlayPermission = await FloatingWindowAndroid.isPermissionGranted();
    if (!overlayPermission) {
      print("[CallKitService] Overlay permission not granted, requesting...");
      // This will open the system settings page for the user to grant it.
      await FloatingWindowAndroid.requestPermission();
      // We can't know the result immediately, so we just assume the user will grant it.
      overlayPermission = true; // Assume true for logic flow
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
  
  static Future<void> showOverlay(Map<String, dynamic> data) async {
    print("[CallKitService] Preparing to show overlay...");
    try {
     // await FloatingWindowAndroid.closeOverlay();
      print("[CallKitService] Any previous overlay closed.");
      
      // --- 核心修复：恢复您指定的参数 ---
      await FloatingWindowAndroid.showOverlay(
        height: 900,
        width: 980,
        alignment: OverlayAlignment.center,
        flag: OverlayFlag.defaultFlag, // Using default to allow interaction
        enableDrag: true,
      );
      print("[CallKitService] showOverlay command sent to native.");

      // Add a small delay to ensure the native side is fully ready
    //  await Future.delayed(const Duration(milliseconds: 200));

      print("[CallKitService] Preparing to share data: $data");
      await FloatingWindowAndroid.shareData(data);
      print("[CallKitService] Data sharing command sent to native.");
    } catch (e) {
      print("[CallKitService] FATAL ERROR during showOverlay/shareData: $e");
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
  
  static Future<void> testWithComplexMockData() async {
    print("[CallKitService] Testing overlay directly with mock data...");
    final complexData = {
      'id': 'mock_id_${DateTime.now().millisecondsSinceEpoch}',
      'nameCaller': 'Direct Test Caller',
      'handle': '+1 (555) 789-1234',
      'avatar': 'https://i.pravatar.cc/150?u=mockuser',
    };
    await showOverlay(complexData);
  }
}