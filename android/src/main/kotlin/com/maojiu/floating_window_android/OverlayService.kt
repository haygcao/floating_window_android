package com.maojiu.floating_window_android

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import com.maojiu.floating_window_android.constants.Constants
import com.maojiu.floating_window_android.manager.OverlayManager

class OverlayService : Service() {
    private var overlayTitle: String = "Floating Window Activated"
    private var overlayContent: String? = null
    private var notificationVisibility: Int = NotificationCompat.VISIBILITY_PRIVATE

    companion object {
        private const val NOTIFICATION_ID = 1001
        @Volatile
        private var isRunning = false

        var overlayHeight: Int = Constants.MATCH_PARENT
        var overlayWidth: Int = Constants.MATCH_PARENT
        var overlayAlignment: String = Constants.CENTER
        var overlayFlag: String = Constants.DEFAULT_FLAG
        var enableDrag: Boolean = false
        var positionGravity: String = Constants.NONE
        var startPosition: Map<String, Any>? = null

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
            overlayTitle = it.getStringExtra(Constants.OVERLAY_TITLE) ?: "Floating Window Activated"
            overlayContent = it.getStringExtra(Constants.OVERLAY_CONTENT)
            val visibilityString = it.getStringExtra(Constants.NOTIFICATION_VISIBILITY)
            notificationVisibility = when (visibilityString) {
                "VISIBILITY_PUBLIC" -> NotificationCompat.VISIBILITY_PUBLIC
                "VISIBILITY_PRIVATE" -> NotificationCompat.VISIBILITY_PRIVATE
                else -> NotificationCompat.VISIBILITY_SECRET
            }
        }

        createNotificationChannel()
        startForeground(NOTIFICATION_ID, createNotification())

        val overlayManager = OverlayManager.getInstance(this)
        overlayManager.showOverlay(
            height = overlayHeight,
            width = overlayWidth,
            alignment = overlayAlignment,
            flag = overlayFlag,
            enableDrag = enableDrag,
            positionGravity = positionGravity,
            startPosition = startPosition
        )

        return START_STICKY
    }

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
    
    private fun createNotification(): Notification {
        val pendingIntent = packageManager.getLaunchIntentForPackage(packageName)?.let {
            PendingIntent.getActivity(this, 0, it, PendingIntent.FLAG_IMMUTABLE)
        }

        return NotificationCompat.Builder(this, Constants.NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(overlayTitle)
            .setContentText(overlayContent)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setVisibility(notificationVisibility)
            .build()
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
        OverlayManager.getInstance(this).closeOverlay()
    }
}