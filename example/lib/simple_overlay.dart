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
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: GestureDetector(
            onTap: _closeOverlay, // 点击黑色区域会调用 _closeOverlay
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
          onTap: onPressed, // 按钮的 onTap 会被优先触发
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

  void _closeOverlay() async {
    print("悬浮窗背景被点击，正在关闭...");
    try {
      // +++ 关键修正 +++
      // 在悬浮窗内部，必须使用 closeOverlayFromOverlay()
      await FloatingWindowAndroid.closeOverlayFromOverlay();
    } catch (e) {
      print("从悬浮窗关闭时出错: $e");
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
      // +++ 关键修正 +++
      // 在悬浮窗内部，必须使用 closeOverlayFromOverlay()
      await FloatingWindowAndroid.closeOverlayFromOverlay();
    } catch (e) {
      print("结束通话或关闭悬浮窗时出错: $e");
      try {
        // +++ 关键修正 +++
        await FloatingWindowAndroid.closeOverlayFromOverlay();
      } catch (e2) { /* 忽略二次错误 */ }
    }
  }
}