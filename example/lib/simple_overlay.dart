// 文件: simple_overlay.dart

import 'package:flutter_riverpod/legacy.dart';

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:floating_window_android/floating_window_android.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

// StateNotifier 和 Provider 的定义保持不变
class CallDataNotifier extends StateNotifier<Map<String, dynamic>?> {
  CallDataNotifier() : super(null);
  void updateData(Map<String, dynamic> newData) {
    state = newData;
  }
}

final callDataProvider = StateNotifierProvider.autoDispose<CallDataNotifier, Map<String, dynamic>?>((ref) {
  return CallDataNotifier();
});


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
    _overlaySubscription = FloatingWindowAndroid.overlayListener.listen((data) {
      if (data is Map && mounted) {
        ref.read(callDataProvider.notifier).updateData(Map<String, dynamic>.from(data));
      }
    });
  }

  @override
  void dispose() {
    _overlaySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final callData = ref.watch(callDataProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Card(
            margin: const EdgeInsets.all(8),
            color: Colors.black.withOpacity(0.85), // slightly more opaque
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // more rounded
            elevation: 12,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: callData == null
                  ? const SizedBox(
                      width: 120, // larger indicator area
                      height: 120,
                      child: Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)),
                    )
                  : buildCallContent(callData),
            ),
          ),
        ),
      ),
    );
  }

  // [核心修改] 修改 buildCallContent 来展示所有新信息
  Widget buildCallContent(Map<String, dynamic> callData) {
    // --- 提取所有数据字段 ---
    final String callerName = callData['nameCaller'] ?? 'Unknown Caller';
    final String avatarUrl = callData['avatar'] ?? '';
    final String handle = callData['handle'] ?? 'No Number';
    final String country = callData['country'] ?? 'N/A';
    final String area = callData['area'] ?? 'N/A';
    final String carrier = callData['carrier'] ?? 'N/A';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. 来电人姓名 (大号字体)
        Text(
          callerName,
          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        // 2. 头像
        CircleAvatar(
          radius: 35, // larger avatar
          backgroundColor: Colors.grey.shade800,
          child: avatarUrl.isEmpty
              ? const Icon(Icons.person, size: 35, color: Colors.white)
              : ClipOval(
                  child: Image.network(
                    avatarUrl,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white));
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.person_off, size: 35, color: Colors.white);
                    },
                  ),
                ),
        ),
        const SizedBox(height: 12),
        // 3. 手机号码 (中号字体)
        Text(
          handle,
          style: TextStyle(color: Colors.grey[300], fontSize: 16),
        ),
        const SizedBox(height: 8),
        // 4. 地区和国家 (小号字体)
        Text(
          "$area, $country",
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
        ),
        const SizedBox(height: 4),
        // 5. 运营商 (小号字体)
        Text(
          "Carrier: $carrier",
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
        ),
        const SizedBox(height: 20),
        // 6. 按钮
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(onPressed: _onDecline, style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)), child: const Text('Decline')),
            ElevatedButton(onPressed: _onAccept, style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)), child: const Text('Accept')),
          ],
        )
      ],
    );
  }

  Future<void> _closeFromOverlay() async {
    await FloatingWindowAndroid.closeOverlayFromOverlay();
  }

  void _onAccept() {
    FloatingWindowAndroid.shareData({'action': 'accepted'});
    _closeFromOverlay();
  }

  void _onDecline() {
    final callData = ref.read(callDataProvider);
    final String? callId = callData?['id'];
    if (callId != null) {
      FlutterCallkitIncoming.endCall(callId);
    }
    FloatingWindowAndroid.shareData({'action': 'declined'});
    _closeFromOverlay();
  }
}