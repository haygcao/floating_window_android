// 文件: lib/simple_overlay.dart
// 最终版本: 无 initialData, 完全分离状态

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:floating_window_android/floating_window_android.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

class SimpleOverlay extends ConsumerStatefulWidget {
  const SimpleOverlay({super.key});

  @override
  ConsumerState<SimpleOverlay> createState() => _SimpleOverlayState();
}

class _SimpleOverlayState extends ConsumerState<SimpleOverlay> {
  StreamSubscription? _subscription;
  
  // 1. [核心] 状态变量现在只有两种：来电主数据 和 SIM卡补充数据
  Map<String, dynamic>? _callerIdUpdate; // 第一个到达的数据包就是它
  Map<String, dynamic>? _simUpdate;

  @override
  void initState() {
    super.initState();
    print("[SimpleOverlay] initState: Starting to listen for overlay data...");
    
    _subscription = FloatingWindowAndroid.overlayListener.listen((data) {
      if (!mounted) return;
      if (data is Map) {
        print("[SimpleOverlay] Received data from stream: $data");
        
        // 2. [核心] 逻辑简化：如果数据包含 'id' 或 'avatar'，就认为是主数据。
        //    如果包含 'simSlot'，就认为是SIM卡数据。
        setState(() {
          if (data.containsKey('id') || data.containsKey('avatar')) {
             _callerIdUpdate = Map<String, dynamic>.from(data);
          }
          else if (data.containsKey('simSlot')) {
            _simUpdate = Map<String, dynamic>.from(data);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    print("[SimpleOverlay] dispose: Canceling subscription.");
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 3. [核心] UI构建的逻辑现在非常简单：
    //    如果连最主要的来电数据都还没到，就显示加载。
    if (_callerIdUpdate == null) {
      print("[SimpleOverlay Build] _callerIdUpdate is null, showing loading indicator.");
      return _buildContainer(
        child: const SizedBox(
          width: 320,
          height: 320,
          child: Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)),
        ),
      );
    }

    // 4. [核心] UI的每个部分都从对应的、唯一的数据源获取信息。
    final String callerName = _callerIdUpdate?['nameCaller'] ?? 'Unknown';
    final String avatarUrl = _callerIdUpdate?['avatar'] ?? '';
    final String handle = _callerIdUpdate?['handle'] ?? 'No Number';
    final String country = _callerIdUpdate?['country'] ?? 'N/A';
    final String area = _callerIdUpdate?['area'] ?? 'N/A';
    final String carrier = _callerIdUpdate?['carrier'] ?? 'N/A';
    final String? simSlot = _simUpdate?['simSlot'];
    
    print("[SimpleOverlay Build] Rebuilding. Name: $callerName, SIM: $simSlot");

    return _buildContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(callerName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.grey.shade800,

            child: avatarUrl.isEmpty
                ? const Icon(Icons.person, size: 35, color: Colors.white)
                : ClipOval(
                    child: Image.network(
                      avatarUrl,
                      width: 70, height: 70, fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) => loadingProgress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.person_off, size: 35, color: Colors.white),
                    ),
                  ),
                  
          ),
          const SizedBox(height: 12),
          Text(handle, style: TextStyle(color: Colors.grey[300], fontSize: 16)),
          const SizedBox(height: 8),
          Text("$area, $country", style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          const SizedBox(height: 4),
          Text("Carrier: $carrier", style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          
          // SIM Slot 部分只有在 _simUpdate 到达后才会构建
          if (simSlot != null) ...[
            const SizedBox(height: 4),
            Text("SIM Slot: $simSlot", style: TextStyle(color: Colors.amber[200], fontSize: 14)),
          ],
          
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(onPressed: _onDecline, style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)), child: const Text('Decline')),
              ElevatedButton(onPressed: _onAccept, style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)), child: const Text('Accept')),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildContainer({required Widget child}) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Card(
            margin: const EdgeInsets.all(8),
            color: Colors.black.withOpacity(0.85),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 12,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  // 事件处理方法
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
    final String? callId = _callerIdUpdate?['id'];
    if (callId != null) {
      FlutterCallkitIncoming.endCall(callId);
    }
    FloatingWindowAndroid.shareData({'action': 'declined'});
    _closeFromOverlay();
  }
}