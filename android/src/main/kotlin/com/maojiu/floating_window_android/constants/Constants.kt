package com.maojiu.floating_window_android.constants

/**
 * Floating Window Constants
 */
object Constants {
    // Method name constants
    const val IS_PERMISSION_GRANTED = "isPermissionGranted"
    const val REQUEST_PERMISSION = "requestPermission"
    const val SHOW_OVERLAY = "showOverlay"
    const val CLOSE_OVERLAY = "closeOverlay"
    const val UPDATE_FLAG = "updateFlag"
    const val RESIZE_OVERLAY = "resizeOverlay"
    const val MOVE_OVERLAY = "moveOverlay"
    const val GET_OVERLAY_POSITION = "getOverlayPosition"
    const val SHARE_DATA = "shareData"
    const val GET_PLATFORM_VERSION = "getPlatformVersion"
    const val OPEN_MAIN_APP = "openMainApp"
    const val CLOSE_OVERLAY_FROM_OVERLAY = "close"
    const val OVERLAY_CONTROL_CHANNEL = "floating_window_android/overlay_control"
    const val IS_SHOWING = "isShowing"
    const val IS_MAIN_APP_RUNNING = "isMainAppRunning"

    // Event channels
    const val OVERLAY_EVENT_CHANNEL = "floating_window_android/overlay_listener"

    // Parameter constants
    const val HEIGHT = "height"
    const val WIDTH = "width"
    const val ALIGNMENT = "alignment"
    const val NOTIFICATION_VISIBILITY = "notificationVisibility"
    const val FLAG = "flag"
    const val OVERLAY_TITLE = "overlayTitle"
    const val OVERLAY_CONTENT = "overlayContent"
    const val ENABLE_DRAG = "enableDrag"
    const val POSITION_GRAVITY = "positionGravity"
    const val START_POSITION = "startPosition"
    const val X = "x"
    const val Y = "y"
    const val DATA = "data"

    // Overlay flag constants
    const val CLICK_THROUGH = "clickThrough"
    const val DEFAULT_FLAG = "defaultFlag"
    const val FOCUS_POINTER = "focusPointer"
    const val LOCK_SCREEN = "lockScreen"

    // Alignment constants
    const val TOP = "top"
    const val BOTTOM = "bottom"
    const val LEFT = "left"
    const val RIGHT = "right"
    const val CENTER = "center"
    const val TOP_LEFT = "topLeft"
    const val TOP_RIGHT = "topRight"
    const val BOTTOM_LEFT = "bottomLeft"
    const val BOTTOM_RIGHT = "bottomRight"

    // Position gravity constants
    const val NONE = "none"
    const val AUTO = "auto"

    // Window size constants
    const val MATCH_PARENT = -1
    const val WRAP_CONTENT = -2

    // Notification channel
    const val NOTIFICATION_CHANNEL_ID = "floating_window_channel"
    const val NOTIFICATION_CHANNEL_NAME = "Floating Window Notification"

    // Notification visibility constants
    const val VISIBILITY_SECRET = "VISIBILITY_SECRET"
    const val VISIBILITY_PUBLIC = "VISIBILITY_PUBLIC"
    const val VISIBILITY_PRIVATE = "VISIBILITY_PRIVATE"

    // Flutter engine preloading methods
    const val PRELOAD_FLUTTER_ENGINE = "preloadFlutterEngine"
    const val IS_FLUTTER_ENGINE_PRELOADED = "isFlutterEnginePreloaded"
    const val CLEANUP_PRELOADED_ENGINE = "cleanupPreloadedEngine"
}