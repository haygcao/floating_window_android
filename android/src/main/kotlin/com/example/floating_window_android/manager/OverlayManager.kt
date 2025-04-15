package com.example.floating_window_android.manager

import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.graphics.Point
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import com.example.floating_window_android.constants.Constants
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterTextureView
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.MethodChannel

/**
 * Floating Window Manager
 */
class OverlayManager(
    private val context: Context
) {
    private val windowManager: WindowManager by lazy {
        context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    }
    
    private var overlayView: FrameLayout? = null
    private var flutterEngine: FlutterEngine? = null
    private var flutterView: FlutterView? = null
    private var eventSink: EventSink? = null
    private var windowParams: WindowManager.LayoutParams? = null
    
    private var enableDrag = false
    private var positionGravity = Constants.NONE
    private var startX = 0f
    private var startY = 0f
    private var initialX = 0
    private var initialY = 0
    private var currentX = 0
    private var currentY = 0
    
    /**
     * Check floating window permission
     */
    fun isPermissionGranted(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(context)
        } else {
            true
        }
    }
    
    /**
     * Request floating window permission
     */
    fun requestPermission(): Intent {
        return Intent(
            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
            Uri.parse("package:${context.packageName}")
        ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    }
    
    /**
     * Show floating window
     */
    fun showOverlay(
        height: Int = Constants.MATCH_PARENT,
        width: Int = Constants.MATCH_PARENT,
        alignment: String = Constants.CENTER,
        flag: String = Constants.DEFAULT_FLAG,
        enableDrag: Boolean = false,
        positionGravity: String = Constants.NONE,
        startPosition: Map<String, Any>? = null,
        dartEntryPoint: String = "overlayMain"
    ) {
        if (overlayView != null) {
            closeOverlay()
        }
        
        this.enableDrag = enableDrag
        this.positionGravity = positionGravity
        
        // Create Flutter engine
        flutterEngine = FlutterEngine(context)
        flutterEngine?.let { engine ->
            // Use direct entry point method without reflection
            val dartEntrypoint = DartExecutor.DartEntrypoint(
                FlutterInjector.instance().flutterLoader().findAppBundlePath(),
                dartEntryPoint
            )
            engine.dartExecutor.executeDartEntrypoint(dartEntrypoint)
            FlutterEngineCache.getInstance().put("overlay_engine", engine)
            
            // Set up dedicated method channel for the overlay engine
            val overlayControlChannel = MethodChannel(engine.dartExecutor.binaryMessenger, Constants.OVERLAY_CONTROL_CHANNEL)
            overlayControlChannel.setMethodCallHandler { call, result ->
                if (call.method == "close") {
                    // Directly call the OverlayManager's close logic
                    closeOverlay()
                    result.success(true)
                } else {
                    result.notImplemented()
                }
            }
            
            // Create Flutter view
            val textureView = FlutterTextureView(context)
            flutterView = FlutterView(context, textureView)
            flutterView?.attachToFlutterEngine(engine)
            
            // Create overlay view
            overlayView = FrameLayout(context)
            flutterView?.let {
                overlayView?.addView(
                    it,
                    FrameLayout.LayoutParams(
                        FrameLayout.LayoutParams.MATCH_PARENT,
                        FrameLayout.LayoutParams.MATCH_PARENT
                    )
                )
            }
            
            // Set up window parameters
            val params = setupWindowParams(height, width, alignment, flag)
            
            // Set initial position
            if (startPosition != null) {
                currentX = (startPosition[Constants.X] as? Number)?.toInt() ?: 0
                currentY = (startPosition[Constants.Y] as? Number)?.toInt() ?: 0
                params.x = currentX
                params.y = currentY
            }
            
            // Set up drag listener - changed to monitor flutterView
            if (enableDrag) {
                setupDragListener(flutterView)
            }
            
            // Add to window
            try {
                windowManager.addView(overlayView, params)
                windowParams = params
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
    
    /**
     * Set up window parameters
     */
    private fun setupWindowParams(
        height: Int,
        width: Int,
        alignment: String,
        flag: String
    ): WindowManager.LayoutParams {
        val params = WindowManager.LayoutParams().apply {
            format = PixelFormat.TRANSLUCENT
            
            // Set flags based on flag and enableDrag
            flags = when (flag) {
                Constants.CLICK_THROUGH -> {
                    // Click through: window doesn't receive any events
                    WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                }
                Constants.FOCUS_POINTER -> {
                    // Focus pointer: allows external events, self-interactive (remove NOT_FOCUSABLE)
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL
                }
                else -> { // defaultFlag
                    if (enableDrag) {
                        // Enable drag: only set NOT_TOUCH_MODAL, allow internal clicks and external events
                        WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL 
                    } else {
                        // Disable drag: set to 0, allow normal interaction and focus
                        0 
                    }
                }
            }
            
            type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                WindowManager.LayoutParams.TYPE_PHONE
            }
            
            this.width = if (width == Constants.MATCH_PARENT) {
                WindowManager.LayoutParams.MATCH_PARENT
            } else if (width == Constants.WRAP_CONTENT) {
                WindowManager.LayoutParams.WRAP_CONTENT
            } else {
                width
            }
            
            this.height = if (height == Constants.MATCH_PARENT) {
                WindowManager.LayoutParams.MATCH_PARENT
            } else if (height == Constants.WRAP_CONTENT) {
                WindowManager.LayoutParams.WRAP_CONTENT
            } else {
                height
            }
            
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
        
        return params
    }
    
    /**
     * Set up drag listener
     */
    @SuppressLint("ClickableViewAccessibility")
    private fun setupDragListener(targetView: View?) {
        var isDragging = false // Add a state flag to track if dragging
        targetView?.setOnTouchListener { _, event -> // Use the passed in view
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    // Record initial touch position and window position
                    startX = event.rawX
                    startY = event.rawY
                    initialX = windowParams?.x ?: 0
                    initialY = windowParams?.y ?: 0
                    isDragging = false // Reset dragging state
                    // Return false to let Flutter handle onTapDown etc.
                    false 
                }
                MotionEvent.ACTION_MOVE -> {
                    // Calculate movement distance
                    val dx = event.rawX - startX
                    val dy = event.rawY - startY
                    
                    // Only consider as dragging when movement exceeds threshold
                    if (!isDragging && (kotlin.math.abs(dx) > 5f || kotlin.math.abs(dy) > 5f)) {
                         isDragging = true // Start dragging
                    }
                    
                    if (isDragging) {
                        // Update current position
                        currentX = (initialX + dx).toInt()
                        currentY = (initialY + dy).toInt()
                        
                        // Update window position
                        windowParams?.let { params ->
                            params.x = currentX
                            params.y = currentY
                            
                            try {
                                // Ensure overlayView is not null
                                overlayView?.let { ov ->
                                    windowManager.updateViewLayout(ov, params)
                                }
                            } catch (e: Exception) {
                                e.printStackTrace()
                            }
                        }
                        // Dragging in progress, consume the event
                        return@setOnTouchListener true
                    }
                    // Not dragging or threshold not met, don't consume event, let Flutter handle it
                    false
                }
                MotionEvent.ACTION_UP -> {
                    val wasDragging = isDragging // Record if it was dragging at ACTION_UP
                    isDragging = false // Reset dragging state
                    
                    if (wasDragging) {
                        // If just finished dragging, handle gravity snapping
                        handlePositionGravity()
                        // And consume the event, as this is the end of a drag gesture
                        return@setOnTouchListener true 
                    }
                    // If not a drag gesture (i.e. click), don't consume event, let Flutter handle onTap/onTapUp
                    false
                }
                else -> false
            }
        }
    }
    
    /**
     * Handle position gravity
     */
    private fun handlePositionGravity() {
        if (positionGravity == Constants.NONE) {
            return
        }
        
        val size = Point()
        windowManager.defaultDisplay.getSize(size)
        val screenWidth = size.x
        
        // Determine left-right snapping based on screen position
        when (positionGravity) {
            Constants.RIGHT -> {
                currentX = screenWidth - (windowParams?.width ?: 0)
            }
            Constants.LEFT -> {
                currentX = 0
            }
            Constants.AUTO -> {
                if (currentX > screenWidth / 2) {
                    currentX = screenWidth - (windowParams?.width ?: 0)
                } else {
                    currentX = 0
                }
            }
        }
        
        windowParams?.x = currentX
        
        try {
            windowManager.updateViewLayout(overlayView, windowParams)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    /**
     * Close floating window
     */
    fun closeOverlay() {
        // ---> Added: Clean up dedicated channel <--- 
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
             MethodChannel(messenger, Constants.OVERLAY_CONTROL_CHANNEL).setMethodCallHandler(null)
        }
       // ---> End of addition <---
       
        try {
            if (overlayView != null) {
                windowManager.removeView(overlayView)
                overlayView = null
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        
        // Handle FlutterView
        val currentView = flutterView
        if (currentView != null) {
            currentView.detachFromFlutterEngine()
            flutterView = null
        }
        
        flutterEngine?.let { engine ->
            engine.destroy()
            FlutterEngineCache.getInstance().remove("overlay_engine")
        }
        flutterEngine = null
        
        windowParams = null
    }
    
    /**
     * Update floating window flag
     */
    fun updateFlag(flag: String): Boolean {
        if (windowParams == null || overlayView == null) {
            return false
        }
        
        windowParams?.flags = when (flag) {
            Constants.CLICK_THROUGH -> {
                WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                        WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
            }
            Constants.FOCUS_POINTER -> {
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL
            }
            else -> {
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
            }
        }
        
        try {
            windowManager.updateViewLayout(overlayView, windowParams)
            return true
        } catch (e: Exception) {
            e.printStackTrace()
        }
        
        return false
    }
    
    /**
     * Resize floating window
     */
    fun resizeOverlay(width: Int, height: Int): Boolean {
        if (windowParams == null || overlayView == null) {
            return false
        }
        
        windowParams?.width = if (width == Constants.MATCH_PARENT) {
            WindowManager.LayoutParams.MATCH_PARENT
        } else if (width == Constants.WRAP_CONTENT) {
            WindowManager.LayoutParams.WRAP_CONTENT
        } else {
            width
        }
        
        windowParams?.height = if (height == Constants.MATCH_PARENT) {
            WindowManager.LayoutParams.MATCH_PARENT
        } else if (height == Constants.WRAP_CONTENT) {
            WindowManager.LayoutParams.WRAP_CONTENT
        } else {
            height
        }
        
        try {
            windowManager.updateViewLayout(overlayView, windowParams)
            return true
        } catch (e: Exception) {
            e.printStackTrace()
        }
        
        return false
    }
    
    /**
     * Move floating window position
     */
    fun moveOverlay(x: Int, y: Int): Boolean {
        if (windowParams == null || overlayView == null) {
            return false
        }
        
        windowParams?.x = x
        windowParams?.y = y
        currentX = x
        currentY = y
        
        try {
            windowManager.updateViewLayout(overlayView, windowParams)
            return true
        } catch (e: Exception) {
            e.printStackTrace()
        }
        
        return false
    }
    
    /**
     * Get current floating window position
     */
    fun getOverlayPosition(): Map<String, Int> {
        return mapOf(
            Constants.X to (windowParams?.x ?: 0),
            Constants.Y to (windowParams?.y ?: 0)
        )
    }
    
    /**
     * Share data between floating window and main app
     */
    fun shareData(data: Any?): Boolean {
        if (eventSink == null) {
            return false
        }
        
        eventSink?.success(data)
        return true
    }
    
    /**
     * Set event sink
     */
    fun setEventSink(sink: EventSink?) {
        this.eventSink = sink
    }
    
    /**
     * Checks if the overlay is currently showing.
     */
    fun isShowing(): Boolean {
        return overlayView != null && overlayView?.isAttachedToWindow == true
    }
} 