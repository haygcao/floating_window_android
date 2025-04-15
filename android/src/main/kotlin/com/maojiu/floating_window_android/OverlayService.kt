package com.maojiu.floating_window_android

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import com.maojiu.floating_window_android.constants.Constants
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

/**
 * Floating Window Service
 */
class OverlayService : Service() {
    private var overlayTitle: String = "Floating Window Activated"
    private var overlayContent: String? = null
    private var notificationVisibility: Int = NotificationCompat.VISIBILITY_PRIVATE
    private var flutterEngine: FlutterEngine? = null
    private var overlayControlChannel: MethodChannel? = null
    
    companion object {
        private const val NOTIFICATION_ID = 1001
        private var isRunning = false
        
        var overlayHeight: Int = Constants.MATCH_PARENT
        var overlayWidth: Int = Constants.MATCH_PARENT
        var overlayAlignment: String = Constants.CENTER
        var overlayFlag: String = Constants.DEFAULT_FLAG
        var enableDrag: Boolean = false
        var positionGravity: String = Constants.NONE
        var startPosition: Map<String, Any>? = null
        var dartEntryPoint: String = "overlayMain"
        
        /**
         * Check if service is running
         */
        fun isRunning(): Boolean {
            return isRunning
        }
    }
    
    override fun onCreate() {
        super.onCreate()
        isRunning = true
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        intent?.let {
            overlayTitle = it.getStringExtra("overlayTitle") ?: "Floating Window Activated"
            overlayContent = it.getStringExtra("overlayContent")
            
            val visibilityString = it.getStringExtra("notificationVisibility") ?: Constants.VISIBILITY_SECRET
            notificationVisibility = when (visibilityString) {
                "VISIBILITY_PUBLIC" -> NotificationCompat.VISIBILITY_PUBLIC
                "VISIBILITY_PRIVATE" -> NotificationCompat.VISIBILITY_PRIVATE
                else -> NotificationCompat.VISIBILITY_SECRET
            }
            
            // Get enableDrag parameter from Intent
            enableDrag = it.getBooleanExtra(Constants.ENABLE_DRAG, false)
        }
        
        // Create notification channel
        createNotificationChannel()
        
        // Start foreground service
        startForeground(NOTIFICATION_ID, createNotification())
        
        // Initialize Flutter engine
        setupFlutterEngine()
        
        return START_STICKY
    }
    
    /**
     * Create notification channel
     */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                Constants.NOTIFICATION_CHANNEL_ID,
                Constants.NOTIFICATION_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                lockscreenVisibility = notificationVisibility
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    /**
     * Create notification
     */
    private fun createNotification(): Notification {
        val pendingIntent = PendingIntent.getActivity(
            this, 0,
            packageManager.getLaunchIntentForPackage(packageName),
            PendingIntent.FLAG_IMMUTABLE
        )
        
        val builder = NotificationCompat.Builder(this, Constants.NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(overlayTitle)
            .setContentText(overlayContent)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setVisibility(notificationVisibility)
        
        return builder.build()
    }
    
    /**
     * Set up Flutter engine
     */
    private fun setupFlutterEngine() {
        flutterEngine = FlutterEngine(this)
        flutterEngine?.let { engine ->
            val flutterLoader = FlutterInjector.instance().flutterLoader()
            
            val entrypoint = DartExecutor.DartEntrypoint(
                flutterLoader.findAppBundlePath(),
                dartEntryPoint
            )
            
            engine.dartExecutor.executeDartEntrypoint(entrypoint)

            // Set up overlay control channel
            overlayControlChannel = MethodChannel(engine.dartExecutor.binaryMessenger, Constants.OVERLAY_CONTROL_CHANNEL)
            overlayControlChannel?.setMethodCallHandler { call, result ->
                when (call.method) {
                    Constants.CLOSE_OVERLAY_FROM_OVERLAY -> {
                        stopSelf() // Stop service
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }
    
    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
    
    override fun onDestroy() {
        isRunning = false
        overlayControlChannel?.setMethodCallHandler(null) // Clean up channel handler
        flutterEngine?.destroy()
        super.onDestroy()
    }
} 