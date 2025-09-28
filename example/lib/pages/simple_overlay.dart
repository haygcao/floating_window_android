import 'dart:async';
import 'package:flutter/material.dart';
import 'package:floating_window_android/floating_window_android.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

class SimpleOverlay extends StatefulWidget {
  const SimpleOverlay({Key? key}) : super(key: key);

  @override
  State<SimpleOverlay> createState() => _SimpleOverlayState();
}

class _SimpleOverlayState extends State<SimpleOverlay> {
  Map<String, dynamic>? _callData;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    FloatingWindowAndroid.overlayListener.listen((event) {
      if (event is Map<String, dynamic>) {
        setState(() {
          _callData = event;
        });
      }
    });

    // Close the overlay after 30 seconds if no action is taken
    _timer = Timer(const Duration(seconds: 30), () {
      _onDecline();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _onAccept() async {
    if (_callData != null) {
      // Notify the main app that the call was accepted
      await FloatingWindowAndroid.shareData({'action': 'CALL_ACCEPTED', 'callId': _callData!['id']});
      await FloatingWindowAndroid.closeOverlay();
      _timer?.cancel();
    }
  }

  Future<void> _onDecline() async {
    if (_callData != null) {
      await FlutterCallkitIncoming.endCall(_callData!['id']);
      // Notify the main app that the call was declined
      await FloatingWindowAndroid.shareData({'action': 'CALL_DECLINED', 'callId': _callData!['id']});
      await FloatingWindowAndroid.closeOverlay();
      _timer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.8),
        body: _callData == null
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(_callData!['avatar'] ?? ''),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _callData!['nameCaller'] ?? 'Unknown Caller',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Incoming Call',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FloatingActionButton(
                        onPressed: _onDecline,
                        backgroundColor: Colors.red,
                        child: const Icon(Icons.call_end),
                      ),
                      FloatingActionButton(
                        onPressed: _onAccept,
                        backgroundColor: Colors.green,
                        child: const Icon(Icons.call),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}