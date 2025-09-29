import 'package:flutter/material.dart';
import 'package:floating_window_android/floating_window_android.dart';
import 'package:floating_window_android_example/callkit_service.dart';
import 'package:floating_window_android_example/simple_overlay.dart';

void main() async {
  // 确保 Flutter 绑定已初始化
  WidgetsFlutterBinding.ensureInitialized();
  // 在 App 启动时，调用初始化方法，它会自动处理所有权限和
    await FloatingWindowAndroid.preloadFlutterEngine();
  await CallKitService.initCallKit();
  runApp(const MyApp());
}

// 悬浮窗的独立 Dart 入口点
@pragma("vm:entry-point")
void overlayMain() {
  runApp(const SimpleOverlay());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _statusMessage = "等待操作...";

  @override
  void initState() {
    super.initState();
    // 监听从悬浮窗返回的事件，用于更新UI状态
    FloatingWindowAndroid.overlayListener.listen((event) {
      if (event is Map<String, dynamic> && mounted) {
        setState(() {
          _statusMessage = "悬浮窗返回事件: ${event['action']}";
        });
      }
    });
  }

  void _showFeedback(String message, {bool isSuccess = true}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isSuccess ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('悬浮窗最终测试'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('当前状态: $_statusMessage', textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    final granted = await CallKitService.requestAllPermissions();
                    _showFeedback(granted ? "权限检查/请求完成！" : "部分权限被拒绝，请检查设置。", isSuccess: granted);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                  child: const Text('1. 请求所有权限'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: CallKitService.showIncomingCall,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text('2. 模拟来电 (触发Overlay)'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    print("测试：正在关闭悬浮窗...");
                    await FloatingWindowAndroid.closeOverlay();
                    _showFeedback("已发送关闭悬浮窗指令。");
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('3. 手动关闭悬浮窗'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}