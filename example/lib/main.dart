import 'package:flutter/material.dart';
import 'package:floating_window_android/floating_window_android.dart';
import 'package:floating_window_android_example/callkit_service.dart';
import 'package:floating_window_android_example/simple_overlay.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 1. 引入 Riverpod
// 核心修复：这个是悬浮窗的入口点

// 悬浮窗的入口点
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    // 2. 将悬浮窗包裹在 ProviderScope 中
    ProviderScope(
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SimpleOverlay(),
      ),
    ),
  );
}







// 核心修复：这个是主 App 的入口点
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
    // 这会在后台准备好一个悬浮窗引擎，以便后续可以“秒开”
  await FloatingWindowAndroid.preloadFlutterEngine();
  CallKitService.initializeListeners();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    ),
  );
}

// 主 App 的 UI 页面
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _statusMessage = "Press a button to start.";

  @override
  void initState() {
    super.initState();
    FloatingWindowAndroid.overlayListener.listen((event) {
      if (mounted && event is Map) {
        setState(() {
          _statusMessage = "Event from overlay: ${event['action']}";
        });
      }
    });
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Floating Window Test')),
      body: Center(
        child: Column(
         
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Status: $_statusMessage', textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final granted = await CallKitService.requestAllPermissions();
                _showFeedback(granted ? "Permissions check complete!" : "Permissions denied!");
              },
              child: const Text('1. Request Permissions'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: CallKitService.showIncomingCallNotification,
              child: const Text('2. Simulate Incoming Call'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: CallKitService.testWithComplexMockData,
              child: const Text('3. Test Overlay Directly'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => FloatingWindowAndroid.closeOverlay(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('4. Manually Close Overlay'),
            ),
          ],
        ),
      ),
    );
  }
}