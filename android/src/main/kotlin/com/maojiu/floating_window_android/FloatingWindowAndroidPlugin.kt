package com.maojiu.floating_window_android

import android.app.Activity
import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import com.maojiu.floating_window_android.constants.Constants
import com.maojiu.floating_window_android.manager.OverlayManager
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.FlutterEngineGroup
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BasicMessageChannel
import io.flutter.plugin.common.JSONMessageCodec
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class FloatingWindowAndroidPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  private lateinit var channel : MethodChannel
  private lateinit var context: Context
  private var activity: Activity? = null
  private val overlayManager: OverlayManager by lazy { OverlayManager(context) }
  private var messenger: BasicMessageChannel<Any>? = null

  // --- ADDED: A reusable function to create and cache the Flutter engine ---
  // This method centralizes the engine creation logic for use in multiple places (automatic and manual initialization).
  private fun createAndCacheEngine() {
    // Check the cache and create the engine only if it doesn't exist. This prevents duplicate creation and ensures a single floating window engine instance globally.
    if (FlutterEngineCache.getInstance().get(Constants.CACHED_ENGINE_ID) == null) {
      val engineGroup = FlutterEngineGroup(context)
      val dartEntryPoint = DartExecutor.DartEntrypoint(
          FlutterInjector.instance().flutterLoader().findAppBundlePath(), "overlayMain"
      )
      val engine = engineGroup.createAndRunEngine(context, dartEntryPoint)
      FlutterEngineCache.getInstance().put(Constants.CACHED_ENGINE_ID, engine)
    }
  }

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    context = flutterPluginBinding.applicationContext
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "floating_window_android")
    channel.setMethodCallHandler(this)

    messenger = BasicMessageChannel(
        flutterPluginBinding.binaryMessenger,
        Constants.MESSENGER_CHANNEL,
        JSONMessageCodec.INSTANCE
    )
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    // --- IMPORTANT: All cases below maintain the logic we previously confirmed, without any modifications ---
    when (call.method) {
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
        if (!overlayManager.isPermissionGranted()) {
            result.error("PERMISSION_DENIED", "Overlay permission is not granted", null)
            return
        }
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
          }

          if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
          } else {
            context.startService(serviceIntent)
          }

          result.success(true)
        } catch (e: Exception) {
          result.error("SHOW_OVERLAY_ERROR", e.message, null)
        }
      }

      Constants.CLOSE_OVERLAY -> {
        try {
          if (OverlayService.isRunning()) {
            val serviceIntent = Intent(context, OverlayService::class.java)
            context.stopService(serviceIntent)
          }
          result.success(true)
        } catch (e: Exception) {
          result.error("CLOSE_OVERLAY_ERROR", e.message, null)
        }
      }
      
      Constants.SHARE_DATA -> {
          try {
              val overlayEngine = FlutterEngineCache.getInstance().get(Constants.CACHED_ENGINE_ID)
              if (overlayEngine != null) {
                  val overlayMessenger = BasicMessageChannel(
                      overlayEngine.dartExecutor.binaryMessenger,
                      Constants.MESSENGER_CHANNEL,
                      JSONMessageCodec.INSTANCE
                  )
                  overlayMessenger.send(call.argument<Any>(Constants.DATA))
                  result.success(true)
              } else {
                  result.error("ENGINE_NOT_FOUND", "Cached overlay engine not found", null)
              }
          } catch (e: Exception) {
              result.error("SHARE_DATA_ERROR", e.message, null)
          }
      }

      Constants.IS_SHOWING -> {
        result.success(overlayManager.isShowing())
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
            intent.addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            result.success(true)
          } else {
            result.error("NO_LAUNCH_INTENT", "Could not get launch intent for package", null)
          }
        } catch (e: Exception) {
          result.error("OPEN_MAIN_APP_ERROR", e.message, null)
        }
      }

      Constants.IS_MAIN_APP_RUNNING -> {
        try {
          val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
          val appProcesses = activityManager.runningAppProcesses ?: emptyList()
          val packageName = context.packageName
          val mainAppRunning = appProcesses.any {
            it.processName == packageName && it.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND
          }
          result.success(mainAppRunning)
        } catch (e: Exception) {
          result.error("IS_MAIN_APP_RUNNING_ERROR", e.message, null)
        }
      }

      // --- ADDED: Logic for new and deprecated engine management APIs ---
      // This is the only incremental modification part this time.

       Constants.INITIALIZE_ENGINE,
      Constants.PRELOAD_FLUTTER_ENGINE -> { // Point preload and initialize to the same robust logic
          try {
              // Call the helper function to ensure the engine instance exists. If the user previously disposed it, it will be recreated here.
              createAndCacheEngine()
              result.success(true)
          } catch (e: Exception) {
              result.error("INITIALIZE_ERROR", e.message, null)
          }
      }
      
      // Point the new dispose and old cleanup to the same handling logic
      Constants.DISPOSE_ENGINE, Constants.CLEANUP_PRELOADED_ENGINE -> {
          try {
              val engine = FlutterEngineCache.getInstance().get(Constants.CACHED_ENGINE_ID)
              // Destroy the engine and remove it from the cache
              engine?.destroy()
              FlutterEngineCache.getInstance().remove(Constants.CACHED_ENGINE_ID)
              result.success(true)
          } catch (e: Exception) {
              result.error("DISPOSE_ERROR", e.message, null)
          }
      }

   
   
   
   
   

      Constants.IS_FLUTTER_ENGINE_PRELOADED -> {
          // For the deprecated isPreloaded API, we check if the engine is in the cache.
          // If the user called dispose, this will return false.
          val engine = FlutterEngineCache.getInstance().get(Constants.CACHED_ENGINE_ID)
          result.success(engine != null)
      }

     // --- ADDED: Logic for getting device pixel ratio ---
      Constants.GET_DEVICE_PIXEL_RATIO -> { 
          try {
              val density = context.resources.displayMetrics.density
              result.success(density.toDouble())
          } catch (e: Exception) {
              result.error("GET_DENSITY_ERROR", e.message, null)
          }
      }
      // --- ADDED: Logic for getting device pixel ratio ---

      else -> {
        result.notImplemented()
      }
    }
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    // [Core Logic] When the plugin is attached to the App's Activity, it automatically triggers the creation and caching of the engine.
    // This ensures that when the user needs to display the floating window, the engine is already ready for "instant-on" functionality.
    createAndCacheEngine()
  }

  // --- The following lifecycle methods remain unchanged ---
  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    messenger?.setMessageHandler(null)
  }
  
  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }
}