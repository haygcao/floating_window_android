import 'dart:async';

import 'package:floating_window_android/floating_window_android.dart';
import 'package:flutter/material.dart';

class SimpleOverlay extends StatefulWidget {
  const SimpleOverlay({super.key});

  @override
  State<SimpleOverlay> createState() => _SimpleOverlayState();
}

class _SimpleOverlayState extends State<SimpleOverlay> {
  StreamSubscription? _overlaySubscription;

  Map<String, dynamic>? _callerIdUpdate;
  Map<String, dynamic>? _simUpdate;

  @override
  void initState() {
    super.initState();
    print("[SimpleOverlay] initState: Starting to listen for overlay data...");
    _overlaySubscription = FloatingWindowAndroid.overlayListener.listen((data) {
      if (!mounted) return;
      print("[SimpleOverlay] Raw data received: $data");

      if (data is Map) {
        _dispatchData(Map<String, dynamic>.from(data));
      }
    });
  }

  void _dispatchData(Map<String, dynamic> data) {
    final configType = data['configType'];
    setState(() {
      if (configType == 'callerIdUpdate') {
        _callerIdUpdate = data;
        print("[SimpleOverlay setState] _callerIdUpdate updated.");
      } else if (configType == 'simUpdate') {
        _simUpdate = data;
        print("[SimpleOverlay setState] _simUpdate updated.");
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
    print(
      "[SimpleOverlay Build] Rebuilding... callerId is ${_callerIdUpdate != null}, sim is ${_simUpdate != null}",
    );

    return Material(
      color: Colors.transparent,
      child: Center(
        child:
            _callerIdUpdate == null
                ? const Card(
                  color: Colors.black,
                  child: Padding(
                    padding: EdgeInsets.all(48.0),
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                )
                : buildCallContent(_callerIdUpdate!, _simUpdate),
      ),
    );
  }

  Widget buildCallContent(
    Map<String, dynamic> callerData,
    Map<String, dynamic>? simData,
  ) {
    final String callerName = callerData['nameCaller'] ?? 'Unknown Caller';
    final String avatarUrl = callerData['avatar'] ?? '';
    final String handle = callerData['handle'] ?? 'No Number';
    final String country = callerData['country'] ?? 'N/A';
    final String area = callerData['area'] ?? 'N/A';
    final String carrier = callerData['carrier'] ?? 'N/A';
    final String? simSlot = simData?['simSlot'] as String?;

    return Card(
      margin: const EdgeInsets.all(8),
      color: Colors.black.withOpacity(0.85),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 12,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              callerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            CircleAvatar(
              radius: 35,
              backgroundColor: Colors.grey.shade800,
              backgroundImage:
                  avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
              child:
                  avatarUrl.isEmpty
                      ? const Icon(Icons.person, size: 35, color: Colors.white)
                      : null,
            ),
            const SizedBox(height: 12),
            Text(
              handle,
              style: TextStyle(color: Colors.grey[300], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              "$area, $country",
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              "Carrier: $carrier",
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            if (simSlot != null) ...[
              const SizedBox(height: 4),
              Text(
                "SIM Slot: $simSlot",
                style: TextStyle(color: Colors.amber[200], fontSize: 14),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _onDecline,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Decline'),
                ),
                ElevatedButton(
                  onPressed: _onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Accept'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onAccept() {
    FloatingWindowAndroid.closeOverlay();
  }

  void _onDecline() {
    FloatingWindowAndroid.closeOverlayFromOverlay();
  }
}
