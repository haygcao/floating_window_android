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
  Map<String, dynamic> _callData = {};
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = FloatingWindowAndroid.overlayListener.listen((event) {
      setState(() {
        _callData = event as Map<String, dynamic>;
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.8),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundImage: NetworkImage(_callData['avatar'] ?? ''),
              ),
              const SizedBox(height: 16),
              Text(
                _callData['nameCaller'] ?? 'Unknown Caller',
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
              const SizedBox(height: 8),
              const Text(
                'Incoming Call',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCallButton(
                    'Decline',
                    Colors.red,
                    Icons.call_end,
                    () => _onDecline(),
                  ),
                  _buildCallButton(
                    'Accept',
                    Colors.green,
                    Icons.call,
                    () => _onAccept(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallButton(
    String text,
    Color color,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Column(
      children: [
        FloatingActionButton(
          onPressed: onPressed,
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(text, style: const TextStyle(color: Colors.white)),
      ],
    );
  }

  void _onAccept() {
    FlutterCallkitIncoming.endCall(_callData['id']);
    FloatingWindowAndroid.closeOverlay();
  }

  void _onDecline() {
    FlutterCallkitIncoming.endCall(_callData['id']);
    FloatingWindowAndroid.closeOverlay();
  }
}