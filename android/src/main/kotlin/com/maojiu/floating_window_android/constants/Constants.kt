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

    // Message Channel for reliable communication
    const val MESSENGER_CHANNEL = "floating_window_android/messenger"
    const val CACHED_ENGINE_ID = "floating_window_engine_id"

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

    // --- ADDED: New engine management constants ---
    // These constants are used for the new manual engine control API.
    // --- ADDED: 为新的引擎手动管理功能和兼容旧API而添加的常量 ---
    /**
     * 新增: 用于从Dart端手动触发引擎初始化。
     * 场景：用户从“仅通知”模式切换回“悬浮窗”模式时，需要重新创建之前被dispose的引擎。
     */
    const val INITIALIZE_ENGINE = "initializeEngine"

    /**
     * 新增: 用于从Dart端手动触发引擎销毁。
     * 场景：用户选择“仅通知”模式，不再需要悬浮窗时，调用此方法释放引擎占用的内存。
     */
    const val DISPOSE_ENGINE = "disposeEngine"

    /**
     * 保留: 兼容旧的 `preloadFlutterEngine` API调用。
     * 在新架构中，此调用无实际预加载作用，因为引擎是自动创建的。
     */
    const val PRELOAD_FLUTTER_ENGINE = "preloadFlutterEngine"
    
    /**
     * 保留: 兼容旧的 `isFlutterEnginePreloaded` API调用。
     * 在新架构中，此调用用于检查自动缓存的引擎当前是否存在。
     */
    const val IS_FLUTTER_ENGINE_PRELOADED = "isFlutterEnginePreloaded"

    /**
     * 保留: 兼容旧的 `cleanupPreloadedEngine` API调用。
     * 在新架构中，此调用将被路由到新的销毁逻辑，等同于 `disposeEngine`。
     */
    const val CLEANUP_PRELOADED_ENGINE = "cleanupPreloadedEngine"





}