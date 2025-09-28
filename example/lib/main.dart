import 'package:flutter/material.dart';
import 'package:floating_window_android/floating_window_android.dart';
import 'package:floating_window_android_example/callkit_service.dart';
import 'package:floating_window_android_example/pages/simple_overlay.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 确保先初始化CallKit服务
  await CallKitService.initCallKit();
  // 确保应用启动后立即准备好接收来电
  FlutterCallkitIncoming.onEvent.listen((event) {
    print("主应用收到CallKit事件: ${event!.event}");
  });
  runApp(const MyApp());
}

@pragma("vm:entry-point")
void overlayMain() {
  runApp(const SimpleOverlay());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  String _callStatus = '无活动通话';
  bool _isInForeground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenForOverlayEvents();
    _listenForCallKitEvents();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _isInForeground = state == AppLifecycleState.resumed;
    print("应用生命周期状态: $state, 前台状态: $_isInForeground");
  }

  void _listenForOverlayEvents() {
    FloatingWindowAndroid.overlayListener.listen((event) {
      print("收到悬浮窗事件: $event");
      if (event is Map<String, dynamic>) {
        if (event['action'] == 'CALL_ACCEPTED') {
          setState(() {
            _callStatus = '已接听来电: ${event['callId']}';
          });
        } else if (event['action'] == 'CALL_DECLINED') {
          setState(() {
            _callStatus = '已拒绝来电: ${event['callId']}';
          });
        }
      }
    });
  }
  
  void _listenForCallKitEvents() {
    FlutterCallkitIncoming.onEvent.listen((event) {
      print("主界面收到CallKit事件: ${event!.event}");
      if (event.event == Event.actionCallIncoming) {
        setState(() {
          _callStatus = '收到来电: ${event.body['id']}';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('来电悬浮窗测试'),
          backgroundColor: Colors.blue,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                elevation: 4,
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text('通话状态', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(_callStatus, style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  print("模拟来电按钮被点击");
                  // 模拟来电并确保显示悬浮窗
                  try {
                    await CallKitService.showIncomingCall();
                    print("模拟来电调用成功");
                  } catch (e) {
                    print("模拟来电调用失败: $e");
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('模拟来电', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  // 直接显示悬浮窗测试
                  await FloatingWindowAndroid.showOverlay(
                    height: 400,
                    width: 300,
                    alignment: OverlayAlignment.center,
                    flag: OverlayFlag.lockScreen,
                    enableDrag: true,
                  );
                  await FloatingWindowAndroid.shareData({'test': 'direct_overlay', 'id': DateTime.now().toString()});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('直接显示悬浮窗', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}