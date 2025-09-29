import 'dart:async';
import 'package:flutter/material.dart';
import 'package:floating_window_android/floating_window_android.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

class SimpleOverlay extends StatefulWidget {
  const SimpleOverlay({super.key});

  @override
  State<SimpleOverlay> createState() => _SimpleOverlayState();
}

class _SimpleOverlayState extends State<SimpleOverlay> {
  Map<String, dynamic> _callData = {};
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = FloatingWindowAndroid.overlayListener.listen((event) {
      if (event is Map<String, dynamic> && mounted) {
        setState(() {
          _callData = event;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String callerName = _callData['nameCaller'] ?? '未知来电';
    final String handle = _callData['handle'] ?? '...';
    final String avatarUrl = _callData['avatar'] ?? '';

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: 
      // +++ 核心修正：在最外层包裹一个 GestureDetector 来捕捉背景点击 +++
      GestureDetector(
        onTap: _closeOverlay, // 点击背景时，调用关闭方法
        child: Scaffold(
          backgroundColor: Colors.transparent, // 背景设为透明，让 GestureDetector 生效
          body: Center(
            child: Container(
              // 创建一个可见的背景板，防止点击穿透到按钮
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16.0), // 可选：美化UI
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // 让 Column 包裹内容
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl.isEmpty ? const Icon(Icons.person, size: 40, color: Colors.white) : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    callerName,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    handle,
                    style: const TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildCallButton(
                        '拒绝',
                        Colors.red,
                        Icons.call_end,
                        _onDecline,
                      ),
                      _buildCallButton(
                        '接听',
                        Colors.green,
                        Icons.call,
                        _onAccept,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCallButton(String text, Color color, IconData icon, VoidCallback onPressed) {
    return Column(
      children: [
        GestureDetector(
          onTap: onPressed, // 按钮点击事件
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 8),
        Text(text, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
  
  // +++ 新增：一个专门用于关闭悬浮窗的方法 +++
  void _closeOverlay() async {
    print("悬浮窗背景被点击，关闭...");
    try {
      await FloatingWindowAndroid.closeOverlay();
    } catch (e) {
      print("从背景点击关闭悬浮窗时出错: $e");
    }
  }

  void _onAccept() async {
    print("悬浮窗: 接听按钮被点击");
    await FloatingWindowAndroid.shareData({'action': 'CALL_ACCEPTED'});
    _endCallAndCloseOverlay();
  }

  void _onDecline() async {
    print("悬浮窗: 拒绝按钮被点击");
    await FloatingWindowAndroid.shareData({'action': 'CALL_DECLINED'});
    _endCallAndCloseOverlay();
  }

  Future<void> _endCallAndCloseOverlay() async {
    try {
      final String? callId = _callData['id'];
      if (callId != null) {
        await FlutterCallkitIncoming.endCall(callId);
      }
      await FloatingWindowAndroid.closeOverlay();
    } catch (e) {
      print("结束通话或关闭悬浮窗时出错: $e");
      try {
        await FloatingWindowAndroid.closeOverlay();
      } catch (e2) { /* 忽略二次错误 */ }
    }
  }
}