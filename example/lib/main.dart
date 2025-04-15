import 'package:flutter/material.dart';
import 'pages/overlay_window.dart';
import 'pages/permission.dart';

// 悬浮窗入口点
@pragma("vm:entry-point")
void overlayMain() {
  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: OverlayWindow()),
  );
}

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PermissionPage(),
    ),
  );
}
