package com.maojiu.floating_window_android.manager

import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Point
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import com.maojiu.floating_window_android.constants.Constants
import io.flutter.embedding.android.FlutterTextureView
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel


class OverlayManager(
    private val context: Context
) {
    private val windowManager: WindowManager by lazy {
        context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    }

    private var flutterView: FlutterView? = null
    private var windowParams: WindowManager.LayoutParams? = null

    private var startX = 0f
    private var startY = 0f
    private var initialX = 0
    private var initialY = 0
    private var currentX = 0
    private var currentY = 0

    companion object {
        @Volatile
        private var instance: OverlayManager? = null
        
        fun getInstance(context: Context): OverlayManager =
            instance ?: synchronized(this) {
                instance ?: OverlayManager(context.applicationContext).also { instance = it }
            }
    }

    fun isPermissionGranted(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) Settings.canDrawOverlays(context) else true
    }

    fun requestPermission(): Intent {
        return Intent(
            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
            Uri.parse("package:${context.packageName}")
        ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    }

    fun showOverlay(
        height: Int = Constants.MATCH_PARENT,
        width: Int = Constants.MATCH_PARENT,
        alignment: String = Constants.CENTER,
        flag: String = Constants.DEFAULT_FLAG,
        enableDrag: Boolean = false,
        positionGravity: String = Constants.NONE,
        startPosition: Map<String, Any>? = null
    ) {
        val flutterEngine = FlutterEngineCache.getInstance().get(Constants.CACHED_ENGINE_ID)
        if (flutterEngine == null) {
            return
        }

        if (flutterView != null && flutterView?.isAttachedToWindow == true) {
            return
        }
        
        flutterEngine.lifecycleChannel.appIsResumed()

        val overlayControlChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, Constants.OVERLAY_CONTROL_CHANNEL)
        overlayControlChannel.setMethodCallHandler { call, result ->
            if (call.method == "close") {
                val serviceIntent = Intent(context, com.maojiu.floating_window_android.OverlayService::class.java)
                context.stopService(serviceIntent)
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
        
        flutterView = FlutterView(context, FlutterTextureView(context)).apply {
            attachToFlutterEngine(flutterEngine)
            fitsSystemWindows = true
            isFocusable = true
            isFocusableInTouchMode = true
            setBackgroundColor(Color.TRANSPARENT)
        }

        windowParams = setupWindowParams(height, width, alignment, flag).also { params ->
            if (startPosition != null) {
                currentX = (startPosition[Constants.X] as? Number)?.toInt() ?: 0
                currentY = (startPosition[Constants.Y] as? Number)?.toInt() ?: 0
                params.x = currentX
                params.y = currentY
            }

            if (enableDrag) {
                setupDragListener(flutterView, positionGravity)
            }

            try {
                windowManager.addView(flutterView, params)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun setupWindowParams(height: Int, width: Int, alignment: String, flag: String): WindowManager.LayoutParams {
        return WindowManager.LayoutParams().apply {
            format = PixelFormat.TRANSLUCENT
            flags = when (flag) {
                Constants.CLICK_THROUGH -> WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                Constants.FOCUS_POINTER -> WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL
                Constants.LOCK_SCREEN -> (WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH) or WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
                else -> WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH
            }
            type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY else WindowManager.LayoutParams.TYPE_PHONE
            this.width = if (width == Constants.MATCH_PARENT) WindowManager.LayoutParams.MATCH_PARENT else if (width == Constants.WRAP_CONTENT) WindowManager.LayoutParams.WRAP_CONTENT else width
            this.height = if (height == Constants.MATCH_PARENT) WindowManager.LayoutParams.MATCH_PARENT else if (height == Constants.WRAP_CONTENT) WindowManager.LayoutParams.WRAP_CONTENT else height
            gravity = when (alignment) {
                Constants.TOP -> Gravity.TOP or Gravity.CENTER_HORIZONTAL
                Constants.BOTTOM -> Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
                Constants.LEFT -> Gravity.START or Gravity.CENTER_VERTICAL
                Constants.RIGHT -> Gravity.END or Gravity.CENTER_VERTICAL
                Constants.TOP_LEFT -> Gravity.TOP or Gravity.START
                Constants.TOP_RIGHT -> Gravity.TOP or Gravity.END
                Constants.BOTTOM_LEFT -> Gravity.BOTTOM or Gravity.START
                Constants.BOTTOM_RIGHT -> Gravity.BOTTOM or Gravity.END
                else -> Gravity.CENTER
            }
        }
    }
    
    @SuppressLint("ClickableViewAccessibility")
    private fun setupDragListener(targetView: View?, positionGravity: String) {
        var isDragging = false
        targetView?.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    startX = event.rawX
                    startY = event.rawY
                    initialX = windowParams?.x ?: 0
                    initialY = windowParams?.y ?: 0
                    isDragging = false
                    false
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = event.rawX - startX
                    val dy = event.rawY - startY
                    if (!isDragging && (kotlin.math.abs(dx) > 5f || kotlin.math.abs(dy) > 5f)) {
                        isDragging = true
                    }
                    if (isDragging) {
                        currentX = (initialX + dx).toInt()
                        currentY = (initialY + dy).toInt()
                        windowParams?.let { params ->
                            params.x = currentX
                            params.y = currentY
                            try {
                                flutterView?.let { ov -> windowManager.updateViewLayout(ov, params) }
                            } catch (e: Exception) { e.printStackTrace() }
                        }
                        return@setOnTouchListener true
                    }
                    false
                }
                MotionEvent.ACTION_UP -> {
                    val wasDragging = isDragging
                    isDragging = false
                    if (wasDragging) {
                        handlePositionGravity(positionGravity)
                        return@setOnTouchListener true
                    }
                    false
                }
                else -> false
            }
        }
    }

    private fun handlePositionGravity(gravity: String) {
        if (gravity == Constants.NONE) return
        val size = Point()
        windowManager.defaultDisplay.getSize(size)
        val screenWidth = size.x
        when (gravity) {
            Constants.RIGHT -> currentX = screenWidth - (windowParams?.width ?: 0)
            Constants.LEFT -> currentX = 0
            Constants.AUTO -> currentX = if (currentX > screenWidth / 2) screenWidth - (windowParams?.width ?: 0) else 0
        }
        windowParams?.x = currentX
        try {
            windowManager.updateViewLayout(flutterView, windowParams)
        } catch (e: Exception) { e.printStackTrace() }
    }

    fun closeOverlay() {
        try {
            if (flutterView != null) {
                windowManager.removeView(flutterView)
                flutterView?.detachFromFlutterEngine()
                flutterView = null
                windowParams = null
                instance = null
                val flutterEngine = FlutterEngineCache.getInstance().get(Constants.CACHED_ENGINE_ID)
                flutterEngine?.lifecycleChannel?.appIsPaused()
            }
        } catch (e: Exception) { e.printStackTrace() }
    }

    fun updateFlag(flag: String): Boolean {
        if (windowParams == null || flutterView == null) return false
        windowParams?.flags = when (flag) {
            Constants.CLICK_THROUGH -> WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
            Constants.FOCUS_POINTER -> WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL
            else -> WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH
        }
        return try {
            windowManager.updateViewLayout(flutterView, windowParams)
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    fun resizeOverlay(width: Int, height: Int): Boolean {
        if (windowParams == null || flutterView == null) return false
        windowParams?.width = if (width == Constants.MATCH_PARENT) WindowManager.LayoutParams.MATCH_PARENT else if (width == Constants.WRAP_CONTENT) WindowManager.LayoutParams.WRAP_CONTENT else width
        windowParams?.height = if (height == Constants.MATCH_PARENT) WindowManager.LayoutParams.MATCH_PARENT else if (height == Constants.WRAP_CONTENT) WindowManager.LayoutParams.WRAP_CONTENT else height
        return try {
            windowManager.updateViewLayout(flutterView, windowParams)
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    fun moveOverlay(x: Int, y: Int): Boolean {
        if (windowParams == null || flutterView == null) return false
        windowParams?.x = x
        windowParams?.y = y
        currentX = x
        currentY = y
        return try {
            windowManager.updateViewLayout(flutterView, windowParams)
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    fun getOverlayPosition(): Map<String, Int> {
        return mapOf(Constants.X to (windowParams?.x ?: 0), Constants.Y to (windowParams?.y ?: 0))
    }

    fun isShowing(): Boolean {
        return flutterView != null && flutterView?.isAttachedToWindow == true
    }
}