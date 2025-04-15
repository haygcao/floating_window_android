import 'package:floating_window_android/floating_window_android.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';

// 权限请求弹窗
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

    // 检查权限
    bool permission = await FloatingWindowAndroid.isPermissionGranted();

    if (permission) {
      // 已有权限，关闭弹窗
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else {
      // 没有权限，显示请求对话框
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    setState(() {
      _isLoading = true;
    });

    // 请求权限
    await FloatingWindowAndroid.requestPermission();

    // 再次检查权限
    bool permission = await FloatingWindowAndroid.isPermissionGranted();

    if (permission) {
      // 已获得权限，关闭弹窗
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else {
      // 仍然没有权限，显示错误信息
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
        '需要悬浮窗权限',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
      ),
      content: const Text(
        '本应用需要悬浮窗权限才能正常工作。请授予权限后再使用。',
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
                    '取消',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _requestPermission,
                  child: Text(
                    '设置',
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

// 权限检查页面
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
  //   // 检查权限
  //   bool permission = await FloatingWindowAndroid.isPermissionGranted();

  //   if (!permission && mounted) {
  //     // 如果没有权限，显示弹窗
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
