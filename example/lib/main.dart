import 'package:flutter/material.dart';
import 'package:floating_window_android/floating_window_android.dart';
import 'package:floating_window_android_example/callkit_service.dart';
import 'package:floating_window_android_example/simple_overlay.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  // When the App starts, call the initialization method, it will automatically handle all permissions and
    await FloatingWindowAndroid.preloadFlutterEngine();
  await CallKitService.initCallKit();
  runApp(const MyApp());
}

// Independent Dart entry point for the overlay
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
  String _statusMessage = "Waiting for operation...";

  @override
  void initState() {
    super.initState();
    // Listen for events returned from the overlay to update UI state
    FloatingWindowAndroid.overlayListener.listen((event) {
      if (event is Map<String, dynamic> && mounted) {
        setState(() {
          _statusMessage = "Overlay event returned: ${event['action']}";
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
          title: const Text('Overlay Final Test', style: TextStyle(color: Color.fromARGB(255, 2, 2, 2))),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Current Status: $_statusMessage', textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    final granted = await CallKitService.requestAllPermissions();
                    _showFeedback(granted ? "Permission check/request completed!" : "Some permissions denied, please check settings.", isSuccess: granted);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                  child: const Text('1. Request All Permissions', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: CallKitService.showIncomingCall,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text('2. Simulate Incoming Call (Trigger Overlay)', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    print("Test: Closing overlay...");
                    await FloatingWindowAndroid.closeOverlay();
                    _showFeedback("Close overlay command sent.");
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('3. Manually Close Overlay', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}