import 'dart:async';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:floating_window_android/floating_window_android.dart';
import 'package:phone_state/phone_state.dart';
import 'package:permission_handler/permission_handler.dart';

/// A comprehensive service class integrating permission requests, simulated incoming calls, 
/// and real phone monitoring, now with an added method for stress testing the overlay plugin.
class CallKitService {
  // StreamSubscription for managing real phone state listening
  static StreamSubscription<PhoneState>? _phoneStateSubscription;

  /// Core entry point: Initializes all services and automatically requests all necessary permissions before starting.
  static Future<void> initCallKit() async {
    print("--- CallKitService Initialization Started ---");
    
    // Step 1: Automatically request all necessary permissions
    await requestAllPermissions(); 

    // Step 2: Listen for flutter_callkit_incoming plugin events (for simulated incoming calls)
    FlutterCallkitIncoming.onEvent.listen((event) async {
      if (event == null) return;
      print("Received CallKit (Simulated Incoming Call) Event: ${event.event}");
      
      switch (event.event) {
        case Event.actionCallIncoming:
          print("Event Details: Received simulated incoming call, preparing to display Overlay...");
          // The structure of CallKit's event.body is complex, we pass the entire body directly
          await showOverlay(event.body); 
          break;
        case Event.actionCallAccept:
        case Event.actionCallDecline:
        case Event.actionCallEnded:
        case Event.actionCallTimeout:
          print("Event Details: Simulated incoming call ended/declined/timed out, preparing to close Overlay...");
          try {
            await FloatingWindowAndroid.closeOverlay();
          } catch (e) {
            print("Error closing simulated incoming call Overlay (may already be closed): $e");
          }
          break;
        default:
          print("Event Details: Unhandled CallKit event: ${event.event}");
          break;
      }
    });
    print("Status: Listening for 'Simulated Incoming Calls' started.");

    // Step 3: Listen for real system phone status
    _phoneStateSubscription?.cancel(); // Cancel any existing listeners to prevent duplication
    _phoneStateSubscription = PhoneState.stream.listen((phoneState) async {
      if (phoneState == null) return;
      print("Real phone state changed: ${phoneState.status}, Number: ${phoneState.number}");

      if (phoneState.status == PhoneStateStatus.CALL_INCOMING) {
        await handleRealPhoneCall(phoneState.number ?? 'Unknown Number', 'System Incoming Call');
      } else if (phoneState.status == PhoneStateStatus.CALL_ENDED || phoneState.status == PhoneStateStatus.NOTHING) {
        print("Real phone call ended, preparing to close Overlay...");
        try {
          await FloatingWindowAndroid.closeOverlay();
        } catch (e) {
          print("Error closing real incoming call Overlay (may already be closed): $e");
        }
      }
    });
    print("Status: Listening for 'Real System Incoming Calls' started.");

    print("--- CallKitService Initialization Completed ---");
  }

  /// Public method to automatically request all permissions using permission_handler
  static Future<bool> requestAllPermissions() async {
    print("Permission Check: Starting to request all permissions...");
    Map<Permission, PermissionStatus> statuses = await [
      Permission.phone,
      Permission.notification,
      Permission.systemAlertWindow,
      Permission.scheduleExactAlarm,
    ].request();

    bool allGranted = true;
    statuses.forEach((permission, status) {
      print('Permission Status - ${permission.toString()}: ${status.toString()}');
      if (!status.isGranted) {
        allGranted = false;
        if (permission == Permission.systemAlertWindow || permission == Permission.scheduleExactAlarm) {
            print("Guidance: ${permission.toString()} permission requires manual enabling in system settings.");
            openAppSettings(); // Automatically guide the user to the settings page
        }
      }
    });
    return allGranted;
  }
  
  /// Core method to display the overlay.
  /// This method tests the modified plugin's ability to handle rapid, sequential calls.
  static Future<void> showOverlay(Map<String, dynamic> data) async {
    print("Overlay Operation: Preparing to display overlay, data: $data");
    try {
      // Step 1: Close any existing overlay. This tests the plugin's state reset.
      await FloatingWindowAndroid.closeOverlay();
      print("Overlay Operation: Old overlay closed (if existed).");

      // Step 2: Show a new overlay. The `await` here is critical, as it now waits 
      // for the internal handshake to complete thanks to our plugin modifications.
      await FloatingWindowAndroid.showOverlay(
        height: 1000,
        width: 950,
       alignment: OverlayAlignment.center,
       flag: OverlayFlag.lockScreen,
        enableDrag: true,
      );
      
      // Step 3: Share data. Because the `showOverlay` future completed, we can be
      // 100% confident that the overlay is ready to receive this data.
      await FloatingWindowAndroid.shareData(data);
      print("Overlay Operation: Overlay displayed and data passed successfully!");
    } catch (e) {
      print("Overlay Operation: Serious error occurred while displaying/operating overlay: $e");
    }
  }

  /// Simulates an incoming call for testing
  static Future<void> showIncomingCall() async {
    print("Simulated Incoming Call: Starting...");
    try {
      final String callId = DateTime.now().millisecondsSinceEpoch.toString();
      final params = CallKitParams(
        id: callId,
        nameCaller: 'Simulated Caller',
        appName: 'Overlay Test',
        avatar: 'https://i.pravatar.cc/100',
        handle: '10086',
        type: 0,
        android: const AndroidParams(
          isCustomNotification: true,
          isShowLogo: false,
          ringtonePath: 'system_ringtone_default',
        ),
      );
      
      await FlutterCallkitIncoming.showCallkitIncoming(params);
      print("Simulated Incoming Call: Notification sent, waiting for onEvent to trigger...");
    } catch (e) {
      print("Simulated Incoming Call: Error during process: $e");
    }
  }
  
  /// [NEW] A dedicated method to stress test the overlay plugin with complex, nested mock data.
  /// Call this from a UI button to perform a robust end-to-end test.
  static Future<void> testWithComplexMockData() async {
    print("--- Starting Test with Complex Mock Data ---");

    // 1. Construct a complex, multi-level, multi-type mock Map.
    // This mimics the complexity of real-world data from APIs or other plugins.
    final complexData = {
      'id': 'mock_id_${DateTime.now().millisecondsSinceEpoch}',
      'nameCaller': 'Dr. Evelyn Reed (Mock)',
      'appName': 'Plugin Stress Test',
      'avatar': 'https://i.pravatar.cc/150?u=mockuser',
      'handle': '+1 (555) 123-4567',
      'type': 0, // Voice call
      'duration': 30000,
      'extra': {
        'userId': 'user-abcdef-123456',
        'call_type': 'premium_support',
        'encryption_enabled': true,
        'call_quality_score': 4.8,
        'regional_servers': ['us-west', 'eu-central', 'ap-southeast'],
        'metadata': null // Testing a null value
      },
      'android': {
        'isCustomNotification': true,
        'isShowLogo': false,
        'ringtonePath': 'system_ringtone_default',
        'backgroundColor': '#091C40',
        'actionColor': '#4CAF50'
      },
      'ios': {
        'supportsVideo': false,
        'includesCallsInRecents': true
      },
      'isSystemCall': false, // Explicitly add all keys the UI might expect
    };

    // 2. Directly call the core showOverlay method, passing in this complex data.
    // This perfectly reproduces the real-world usage pattern from the onEvent listener.
    await showOverlay(complexData);

    print("--- Test with Complex Mock Data Completed ---");
  }

  /// Entry method to handle real system incoming calls
  static Future<void> handleRealPhoneCall(String phoneNumber, String callerName) async {
    print("Real Incoming Call Handling: $callerName ($phoneNumber)");
    await showOverlay({
      'id': 'system_call_${DateTime.now().millisecondsSinceEpoch}',
      'nameCaller': callerName, // Keep key names consistent with CallKit
      'handle': phoneNumber,
      'avatar': '', // Ensure avatar exists to prevent null errors in UI
      'isSystemCall': true,
    });
  }

  /// Stops all listening services and releases resources
  static void dispose() {
    _phoneStateSubscription?.cancel();
    _phoneStateSubscription = null;
    FlutterCallkitIncoming.onEvent.listen(null); // Recommended way to clear listener
    print("All phone state listeners stopped and resources released.");
  }
}