import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:floating_window_android/floating_window_android.dart';
import 'package:floating_window_android/constants.dart';

class CallKitService {
  static Future<void> initCallKit() async {
    // Request notification permission for Android 13+
    await FlutterCallkitIncoming.requestNotificationPermission({
      "title": "通知权限",
      "rationaleMessagePermission": "需要通知权限来显示来电信息",
      "postNotificationMessageRequired": "请在设置中允许通知权限以接收来电"
    });
    
    // Request full intent permission for Android 14+
    await FlutterCallkitIncoming.canUseFullScreenIntent();
    await FlutterCallkitIncoming.requestFullIntentPermission();
    
    // 立即监听来电事件
    FlutterCallkitIncoming.onEvent.listen((event) async {
      print("收到CallKit事件: ${event!.event}");
      if (event != null) {
        switch (event.event) {
          case Event.actionCallIncoming:
            print("收到来电事件，显示悬浮窗");
            // 确保立即显示悬浮窗
            await showOverlay(event.body);
            break;
          case Event.actionCallAccept:
            print("接听来电，关闭悬浮窗");
            await FloatingWindowAndroid.closeOverlay();
            break;
          case Event.actionCallDecline:
            print("拒绝来电，关闭悬浮窗");
            await FloatingWindowAndroid.closeOverlay();
            break;
          case Event.actionCallEnded:
            print("通话结束，关闭悬浮窗");
            await FloatingWindowAndroid.closeOverlay();
            break;
          case Event.actionCallTimeout:
            print("来电超时，关闭悬浮窗");
            await FloatingWindowAndroid.closeOverlay();
            break;
          default:
            print("其他CallKit事件: ${event.event}");
            break;
        }
      }
    });
  }

  static Future<void> showOverlay(Map<String, dynamic> data) async {
    print("准备显示悬浮窗，数据: $data");
    try {
      // 确保悬浮窗显示在锁屏上方
      await FloatingWindowAndroid.showOverlay(
        height: 400,
        width: 300,
        alignment: OverlayAlignment.center,
        flag: OverlayFlag.lockScreen,
        enableDrag: true,
      );
      // 确保数据传递到悬浮窗
      await FloatingWindowAndroid.shareData(data);
      print("悬浮窗显示成功");
    } catch (e) {
      print("显示悬浮窗错误: $e");
    }
  }

  static Future<void> showIncomingCall() async {
    print("模拟来电开始");
    try {
      final String callId = DateTime.now().millisecondsSinceEpoch.toString();
      final params = CallKitParams(
        id: callId,
        nameCaller: '测试来电',
        appName: '悬浮窗测试',
        avatar: 'https://i.pravatar.cc/100',
        handle: '10086',
        type: 0,
        duration: 30000,
        textAccept: '接听',
        textDecline: '拒绝',
        missedCallNotification: const NotificationParams(
          showNotification: true,
          isShowCallback: true,
          subtitle: '未接来电',
          callbackText: '回拨',
        ),
        callingNotification: const NotificationParams(
          showNotification: true,
          isShowCallback: true,
          subtitle: '来电中...',
          callbackText: '挂断',
        ),
        extra: <String, dynamic>{'userId': callId, 'testCall': true},
        headers: <String, dynamic>{'apiKey': 'test123', 'platform': 'flutter'},
        android: const AndroidParams(
          isCustomNotification: true,
          isShowLogo: false,
          ringtonePath: 'system_ringtone_default',
          backgroundColor: '#0955fa',
          backgroundUrl: 'https://i.pravatar.cc/500',
          actionColor: '#4CAF50',
          incomingCallNotificationChannelName: "来电通知",
          missedCallNotificationChannelName: "未接来电",
          isShowFullLockedScreen: true,
        ),
        ios: const IOSParams(
          iconName: 'CallKitLogo',
          handleType: 'generic',
          supportsVideo: true,
          maximumCallGroups: 2,
          maximumCallsPerCallGroup: 1,
          audioSessionMode: 'default',
          audioSessionActive: true,
          audioSessionPreferredSampleRate: 44100.0,
          audioSessionPreferredIOBufferDuration: 0.005,
          supportsDTMF: true,
          supportsHolding: true,
          supportsGrouping: false,
          supportsUngrouping: false,
          ringtonePath: 'system_ringtone_default',
        ),
      );
      
      print("准备显示来电通知");
      await FlutterCallkitIncoming.showCallkitIncoming(params);
      print("来电通知显示成功");
      
      // 直接显示悬浮窗，不等待CallKit事件
      print("直接显示悬浮窗");
      await showOverlay({'id': callId, 'name': '测试来电', 'handle': '10086'});
    } catch (e) {
      print("模拟来电过程中出错: $e");
    }
  }
}