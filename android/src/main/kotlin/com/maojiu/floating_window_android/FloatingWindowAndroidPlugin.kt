package com.maojiu.floating_window_android

import android.app.Activity
import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import com.maojiu.floating_window_android.constants.Constants
import com.maojiu.floating_window_android.manager.OverlayManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** FloatingWindowAndroidPlugin */
class FloatingWindowAndroidPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  private lateinit var channel : MethodChannel
  private lateinit var eventChannel: EventChannel
  private lateinit var context: Context
  private var activity: Activity? = null
  private val overlayManager: OverlayManager by lazy { OverlayManager(context) }

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    context = flutterPluginBinding.applicationContext
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "floating_window_android")
    channel.setMethodCallHandler(this)

    eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, Constants.OVERLAY_EVENT_CHANNEL)
    eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
      override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        // 将 EventSink 连接到 OverlayManager 的静态桥梁
        OverlayManager.setEventSink(events)
      }

      override fun onCancel(arguments: Any?) {
        // 断开连接
        OverlayManager.setEventSink(null)
      }
    })
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      Constants.SHARE_DATA -> {
        try {
          // 不再通过实例，而是通过静态方法直接发送，确保数据能被缓存
          OverlayManager.shareDataToOverlay(call.argument<Any>(Constants.DATA))
          result.success(true)
        } catch (e: Exception) {
          result.error("SHARE_DATA_ERROR", e.message, null)
        }
      }
      
      // ... 其他的 onMethodCall case 保持不变 ...
      Constants.GET_PLATFORM_VERSION -> {
        result.success("Android ${android.os.Build.VERSION.RELEASE}")
      }
      
      Constants.IS_PERMISSION_GRANTED -> {
        result.success(overlayManager.isPermissionGranted())
      }
      
      Constants.REQUEST_PERMISSION -> {
        if (activity != null) {
          val intent = overlayManager.requestPermission()
          activity?.startActivity(intent)
          result.success(true)
        } else {
          result.error("NO_ACTIVITY", "Activity is not available", null)
        }
      }
      
      Constants.SHOW_OVERLAY -> {
        try {
          val height = call.argument<Int>(Constants.HEIGHT) ?: Constants.MATCH_PARENT
          val width = call.argument<Int>(Constants.WIDTH) ?: Constants.MATCH_PARENT
          val alignment = call.argument<String>(Constants.ALIGNMENT) ?: Constants.CENTER
          val notificationVisibility = call.argument<String>(Constants.NOTIFICATION_VISIBILITY)
          val flag = call.argument<String>(Constants.FLAG) ?: Constants.DEFAULT_FLAG
          val overlayTitle = call.argument<String>(Constants.OVERLAY_TITLE) ?: "Floating Window Activated"
          val overlayContent = call.argument<String>(Constants.OVERLAY_CONTENT)
          val enableDrag = call.argument<Boolean>(Constants.ENABLE_DRAG) ?: false
          val positionGravity = call.argument<String>(Constants.POSITION_GRAVITY) ?: Constants.NONE
          val startPosition = call.argument<Map<String, Any>>(Constants.START_POSITION)
          
          OverlayService.overlayHeight = height
          OverlayService.overlayWidth = width
          OverlayService.overlayAlignment = alignment
          OverlayService.overlayFlag = flag
          OverlayService.enableDrag = enableDrag
          OverlayService.positionGravity = positionGravity
          OverlayService.startPosition = startPosition
          
          val serviceIntent = Intent(context, OverlayService::class.java).apply {
            putExtra(Constants.OVERLAY_TITLE, overlayTitle)
            putExtra(Constants.OVERLAY_CONTENT, overlayContent)
            putExtra(Constants.NOTIFICATION_VISIBILITY, notificationVisibility)
            putExtra(Constants.ENABLE_DRAG, enableDrag)
          }
          
          if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
          } else {
            context.startService(serviceIntent)
          }
          
          overlayManager.showOverlay(
            height = height,
            width = width,
            alignment = alignment,
            flag = flag,
            enableDrag = enableDrag,
            positionGravity = positionGravity,
            startPosition = startPosition
          )
          
          result.success(true)
        } catch (e: Exception) {
          result.error("SHOW_OVERLAY_ERROR", e.message, null)
        }
      }
      
      Constants.CLOSE_OVERLAY -> {
        try {
          overlayManager.closeOverlay()
          
          if (OverlayService.isRunning()) {
            context.stopService(Intent(context, OverlayService::class.java))
          }
          
          result.success(true)
        } catch (e: Exception) {
          result.error("CLOSE_OVERLAY_ERROR", e.message, null)
        }
      }
      
      Constants.UPDATE_FLAG -> {
        try {
          val flag = call.argument<String>(Constants.FLAG) ?: Constants.DEFAULT_FLAG
          val success = overlayManager.updateFlag(flag)
          result.success(success)
        } catch (e: Exception) {
          result.error("UPDATE_FLAG_ERROR", e.message, null)
        }
      }
      
      Constants.RESIZE_OVERLAY -> {
        try {
          val width = call.argument<Int>(Constants.WIDTH) ?: Constants.MATCH_PARENT
          val height = call.argument<Int>(Constants.HEIGHT) ?: Constants.MATCH_PARENT
          val success = overlayManager.resizeOverlay(width, height)
          result.success(success)
        } catch (e: Exception) {
          result.error("RESIZE_OVERLAY_ERROR", e.message, null)
        }
      }
      
      Constants.MOVE_OVERLAY -> {
        try {
          val x = call.argument<Int>(Constants.X) ?: 0
          val y = call.argument<Int>(Constants.Y) ?: 0
          val success = overlayManager.moveOverlay(x, y)
          result.success(success)
        } catch (e: Exception) {
          result.error("MOVE_OVERLAY_ERROR", e.message, null)
        }
      }
      
      Constants.GET_OVERLAY_POSITION -> {
        try {
          val position = overlayManager.getOverlayPosition()
          result.success(position)
        } catch (e: Exception) {
          result.error("GET_OVERLAY_POSITION_ERROR", e.message, null)
        }
      }
      
      Constants.OPEN_MAIN_APP -> {
        try {
          val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
          if (intent != null) {
            val params = call.arguments<Map<String, Any>>()
            if (params != null) {
              for ((key, value) in params) {
                when (value) {
                  is String -> intent.putExtra(key, value)
                  is Int -> intent.putExtra(key, value)
                  is Double -> intent.putExtra(key, value)
                  is Boolean -> intent.putExtra(key, value)
                  is Float -> intent.putExtra(key, value)
                  is Long -> intent.putExtra(key, value)
                  else -> intent.putExtra(key, value.toString())
                }
              }
            }
            
            intent.addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                          Intent.FLAG_ACTIVITY_NEW_TASK or
                          Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED)
            context.startActivity(intent)
            result.success(true)
          } else {
            result.error("NO_LAUNCH_INTENT", "Could not get launch intent for package", null)
          }
        } catch (e: Exception) {
          result.error("OPEN_MAIN_APP_ERROR", e.message, null)
        }
      }
      
      Constants.IS_SHOWING -> {
        result.success(overlayManager.isShowing())
      }
      
      Constants.IS_MAIN_APP_RUNNING -> {
        try {
          val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
          val appProcesses = activityManager.runningAppProcesses ?: emptyList()
          
          val packageName = context.packageName
          var mainAppRunning = false
          
          for (process in appProcesses) {
            if (process.processName == packageName && 
                process.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND) {
              mainAppRunning = true
              break
            }
          }
          
          result.success(mainAppRunning)
        } catch (e: Exception) {
          result.error("IS_MAIN_APP_RUNNING_ERROR", e.message, null)
        }
      }
      
      Constants.PRELOAD_FLUTTER_ENGINE -> {
        try {
          val dartEntryPoint = call.argument<String>("dartEntryPoint") ?: "overlayMain"
          OverlayManager.preloadFlutterEngine(context, dartEntryPoint)
          result.success(true)
        } catch (e: Exception) {
          result.error("PRELOAD_ENGINE_ERROR", e.message, null)
        }
      }
      
      Constants.IS_FLUTTER_ENGINE_PRELOADED -> {
        try {
          val isPreloaded = OverlayManager.isFlutterEnginePreloaded()
          result.success(isPreloaded)
        } catch (e: Exception) {
          result.error("CHECK_PRELOAD_ERROR", e.message, null)
        }
      }
      
      Constants.CLEANUP_PRELOADED_ENGINE -> {
        try {
          OverlayManager.cleanupPreloadedEngine()
          result.success(true)
        } catch (e: Exception) {
          result.error("CLEANUP_ENGINE_ERROR", e.message, null)
        }
      }
      
      else -> {
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
  }
  
  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) { // <-- 错误已在此处修正
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }
}