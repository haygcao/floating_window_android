import 'package:floating_window_android/floating_window_android.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';

/// Permission request dialog
class PermissionDialog extends StatefulWidget {
  const PermissionDialog({super.key});

  @override
  State<PermissionDialog> createState() => _PermissionDialogState();
}

class _PermissionDialogState extends State<PermissionDialog> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    setState(() {
      _isLoading = true;
    });

    // Check permission
    bool permission = await FloatingWindowAndroid.isPermissionGranted();

    if (permission) {
      // Permission granted, close dialog
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else {
      // No permission, show request dialog
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    setState(() {
      _isLoading = true;
    });

    // Request permission
    await FloatingWindowAndroid.requestPermission();

    // Check permission again
    bool permission = await FloatingWindowAndroid.isPermissionGranted();

    if (permission) {
      // Permission granted, close dialog
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else {
      // Still no permission, show error message
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(0, 0, 8, 8),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      title: const Text(
        'Floating Window Permission Required',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
      ),
      content: const Text(
        'This app requires floating window permission to work properly. Please grant the permission to continue.',
        style: TextStyle(fontSize: 14, color: Colors.black87),
      ),
      actions:
          _isLoading
              ? [const Center(child: CircularProgressIndicator())]
              : [
                TextButton(
                  onPressed: () {
                    SystemNavigator.pop();
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _requestPermission,
                  child: Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
    );
  }
}

/// Permission check page
class PermissionPage extends StatefulWidget {
  const PermissionPage({super.key});

  @override
  State<PermissionPage> createState() => _PermissionPageState();
}

class _PermissionPageState extends State<PermissionPage> {
  // @override
  // void initState() {
  //   super.initState();
  //   _checkPermission();
  // }

  // Future<void> _checkPermission() async {
  //   // Check permission
  //   bool permission = await FloatingWindowAndroid.isPermissionGranted();

  //   if (!permission && mounted) {
  //     // If no permission, show dialog
  //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //       showDialog(
  //         context: context,
  //         barrierDismissible: false,
  //         builder: (context) => const PermissionDialog(),
  //       );
  //     });
  //   }

  //   setState(() {});
  // }

  @override
  Widget build(BuildContext context) {
    return const App();
  }
}
