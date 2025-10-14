// 文件: simple_overlay.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:floating_window_android/floating_window_android.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_riverpod/legacy.dart';

// 1. StateNotifier，用于管理状态
class CallDataNotifier extends StateNotifier<Map<String, dynamic>?> {
  CallDataNotifier() : super(null);

  void updateData(Map<String, dynamic> newData) {
    state = newData;
    // Print #1: 确认状态管理器本身的状态已被更新
    print("[CallDataNotifier] State updated to: $state");
  }
}

// 2. StateNotifierProvider，用于向UI提供状态管理器
final callDataProvider = StateNotifierProvider.autoDispose<CallDataNotifier, Map<String, dynamic>?>((ref) {
  return CallDataNotifier();
});

// 3. ConsumerStatefulWidget，因为我们需要 initState 来设置监听
class SimpleOverlay extends ConsumerStatefulWidget {
  const SimpleOverlay({super.key});

  @override
  ConsumerState<SimpleOverlay> createState() => _SimpleOverlayState();
}

class _SimpleOverlayState extends ConsumerState<SimpleOverlay> {
  StreamSubscription? _overlaySubscription;

  @override
  void initState() {
    super.initState();
    // Print #2: 确认监听器在 widget 初始化时被设置
    print("[SimpleOverlay] initState: Listening to overlayListener...");

    // 严格保留您要求的 listen 模式
    _overlaySubscription = FloatingWindowAndroid.overlayListener.listen((data) {
      if (data is Map && mounted) {
        // Print #3: 确认原始数据已通过 Stream 到达 Dart 层
        print("[SimpleOverlay] Received data via listener: $data");
        // 调用 Notifier 的方法来更新状态
        ref.read(callDataProvider.notifier).updateData(Map<String, dynamic>.from(data));
      } else {
        print("[SimpleOverlay] Received non-map data via listener: $data");
      }
    });
  }

  @override
  void dispose() {
    print("[SimpleOverlay] dispose: Canceling subscription.");
    _overlaySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 使用 ref.watch 来监听状态变化
    final callData = ref.watch(callDataProvider);
    // Print #4: 确认 build 方法被触发，并显示当前用于构建UI的数据
    print("[SimpleOverlay Build] Rebuilding with callData: $callData");

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Card(
            margin: const EdgeInsets.all(8),
            color: Colors.black.withOpacity(0.8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              // 根据 Provider 的状态来构建 UI
              child: callData == null
                  ? const SizedBox(
                      width: 100,
                      height: 100,
                      child: Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)),
                    )
                  : buildCallContent(callData),
            ),
          ),
        ),
      ),
    );
  }

  // 渲染网络图片的健壮版本
  Widget buildCallContent(Map<String, dynamic> callData) {
    final String callerName = callData['nameCaller'] ?? 'Unknown Caller';
    final String avatarUrl = callData['avatar'] ?? '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("Caller: $callerName", style: const TextStyle(color: Colors.white, fontSize: 18)),
        const SizedBox(height: 10),
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.grey.shade800,
          child: avatarUrl.isEmpty
              ? const Icon(Icons.person, size: 30, color: Colors.white)
              : ClipOval(
                  child: Image.network(
                    avatarUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white));
                    },
                    errorBuilder: (context, error, stackTrace) {
                      // Print #5: 确认图片加载是否出错
                      print("[SimpleOverlay] Image loading error: $error");
                      return const Icon(Icons.person_off, size: 30, color: Colors.white);
                    },
                  ),
                ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(onPressed: _onDecline, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Decline')),
            ElevatedButton(onPressed: _onAccept, style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text('Accept')),
          ],
        )
      ],
    );
  }

  Future<void> _closeFromOverlay() async {
    await FloatingWindowAndroid.closeOverlayFromOverlay();
  }

  void _onAccept() {
    print("[SimpleOverlay] Call Accepted");
    FloatingWindowAndroid.shareData({'action': 'accepted'});
    _closeFromOverlay();
  }

  void _onDecline() {
    print("[SimpleOverlay] Call Declined");
    final callData = ref.read(callDataProvider);
    final String? callId = callData?['id'];
    if (callId != null) {
      FlutterCallkitIncoming.endCall(callId);
    }
    FloatingWindowAndroid.shareData({'action': 'declined'});
    _closeFromOverlay();
  }
}