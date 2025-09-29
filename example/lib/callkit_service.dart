import 'dart:async';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:floating_window_android/floating_window_android.dart';
import 'package:phone_state/phone_state.dart';
import 'package:permission_handler/permission_handler.dart';

/// 一个集成了权限请求、模拟来电和真实电话监听的综合服务类。
class CallKitService {
  // 用于管理真实电话状态监听的 StreamSubscription
  static StreamSubscription<PhoneState>? _phoneStateSubscription;

  /// 核心入口：初始化所有服务，并在开始前自动化请求所有必需的权限。
  static Future<void> initCallKit() async {
    print("--- CallKitService 初始化开始 ---");
    
    // 步骤 1: 自动化请求所有必需的权限
    await requestAllPermissions(); 

    // 步骤 2: 监听 flutter_callkit_incoming 插件的事件 (用于模拟来电)
    FlutterCallkitIncoming.onEvent.listen((event) async {
      if (event == null) return;
      print("收到 CallKit (模拟来电) 事件: ${event.event}");
      
      switch (event.event) {
        case Event.actionCallIncoming:
          print("事件详情: 收到模拟来电，准备显示 Overlay...");
          // CallKit 的 event.body 结构比较复杂，我们直接传递整个 body
          await showOverlay(event.body); 
          break;
        case Event.actionCallAccept:
        case Event.actionCallDecline:
        case Event.actionCallEnded:
        case Event.actionCallTimeout:
          print("事件详情: 模拟来电已结束/拒绝/超时，准备关闭 Overlay...");
          try {
            await FloatingWindowAndroid.closeOverlay();
          } catch (e) {
            print("关闭模拟来电 Overlay 时出错 (可能已关闭): $e");
          }
          break;
        default:
          print("事件详情: 未处理的 CallKit 事件: ${event.event}");
          break;
      }
    });
    print("状态: 已启动对 '模拟来电' 的监听。");

    // 步骤 3: 监听真实的系统电话状态
    _phoneStateSubscription?.cancel(); // 先取消可能存在的旧监听，防止重复
    _phoneStateSubscription = PhoneState.stream.listen((phoneState) async {
      if (phoneState == null) return;
      print("真实电话状态变化: ${phoneState.status}, 号码: ${phoneState.number}");

      if (phoneState.status == PhoneStateStatus.CALL_INCOMING) {
        await handleRealPhoneCall(phoneState.number ?? '未知号码', '系统来电');
      } else if (phoneState.status == PhoneStateStatus.CALL_ENDED || phoneState.status == PhoneStateStatus.NOTHING) {
        print("真实电话已结束，准备关闭 Overlay...");
        try {
          await FloatingWindowAndroid.closeOverlay();
        } catch (e) {
          print("关闭真实来电 Overlay 时出错 (可能已关闭): $e");
        }
      }
    });
    print("状态: 已启动对 '真实系统来电' 的监听。");

    print("--- CallKitService 初始化完成 ---");
  }

  /// 使用 permission_handler 自动化请求所有权限的公共方法
  static Future<bool> requestAllPermissions() async {
    print("权限检查: 开始请求所有权限...");
    Map<Permission, PermissionStatus> statuses = await [
      Permission.phone,
      Permission.notification,
      Permission.systemAlertWindow,
      Permission.scheduleExactAlarm,
    ].request();

    bool allGranted = true;
    statuses.forEach((permission, status) {
      print('权限状态 - ${permission.toString()}: ${status.toString()}');
      if (!status.isGranted) {
        allGranted = false;
        if (permission == Permission.systemAlertWindow || permission == Permission.scheduleExactAlarm) {
            print("引导: ${permission.toString()} 权限需要用户在系统设置中手动开启。");
            openAppSettings(); // 自动引导用户去设置页面
        }
      }
    });
    return allGranted;
  }
  
  /// 显示悬浮窗的核心方法
  static Future<void> showOverlay(Map<String, dynamic> data) async {
    print("Overlay操作: 准备显示悬浮窗，数据: $data");
    try {
      await FloatingWindowAndroid.closeOverlay();
      print("Overlay操作: 旧悬浮窗已关闭（如果存在）。");

      await FloatingWindowAndroid.showOverlay(
        height: 1000,
        width: 950,
       alignment: OverlayAlignment.center,
       flag: OverlayFlag.lockScreen,
       
        enableDrag: true,
      );
      
      await FloatingWindowAndroid.shareData(data);
      print("Overlay操作: 悬浮窗显示并传递数据成功！");
    } catch (e) {
      print("Overlay操作: 显示/操作悬浮窗时发生严重错误: $e");
    }
  }

  /// 模拟一个来电，用于测试
  static Future<void> showIncomingCall() async {
    print("模拟来电: 开始...");
    try {
      final String callId = DateTime.now().millisecondsSinceEpoch.toString();
      final params = CallKitParams(
        id: callId,
        nameCaller: '模拟来电者',
        appName: '悬浮窗测试',
        avatar: 'https://i.pravatar.cc/100',
        handle: '10086',
        type: 0,
        android: const AndroidParams(
          isCustomNotification: true,
          isShowLogo: false,
          ringtonePath: 'system_ringtone_default',
        ),
      );
      
      await FlutterCallkitIncoming.showCallkitIncoming(params);
      print("模拟来电: 通知已发出，等待 onEvent 触发...");
    } catch (e) {
      print("模拟来电: 过程中出错: $e");
    }
  }
  
  /// 处理真实系统来电的入口方法
  static Future<void> handleRealPhoneCall(String phoneNumber, String callerName) async {
    print("真实来电处理: $callerName ($phoneNumber)");
    await showOverlay({
      'id': 'system_call_${DateTime.now().millisecondsSinceEpoch}',
      'nameCaller': callerName, // 保持键名与CallKit一致
      'handle': phoneNumber,
      'isSystemCall': true,
    });
  }

  /// 停止所有监听服务，释放资源
  static void dispose() {
    _phoneStateSubscription?.cancel();
    _phoneStateSubscription = null;
    print("所有电话状态监听已停止并释放资源。");
  }
}