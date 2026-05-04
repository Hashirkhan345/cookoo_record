package com.cookoo.cookoorecord

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat

class DisplayCaptureForegroundService : Service() {
    companion object {
        private const val channelId = "Aks_display_capture"
        private const val channelName = "Screen recording"
        private const val notificationId = 4818

        private var isForeground = false
        private var foregroundReadyCallback: (() -> Unit)? = null
        private var foregroundStartFailedCallback: ((Exception) -> Unit)? = null

        fun start(
            context: Context,
            onReady: (() -> Unit)? = null,
            onFailure: ((Exception) -> Unit)? = null
        ) {
            if (isForeground) {
                onReady?.invoke()
                return
            }

            foregroundReadyCallback = onReady
            foregroundStartFailedCallback = onFailure
            val intent = Intent(context, DisplayCaptureForegroundService::class.java)
            try {
                ContextCompat.startForegroundService(context, intent)
            } catch (error: Exception) {
                val failureCallback = foregroundStartFailedCallback
                foregroundReadyCallback = null
                foregroundStartFailedCallback = null
                failureCallback?.invoke(error)
            }
        }

        fun stop(context: Context) {
            isForeground = false
            foregroundReadyCallback = null
            foregroundStartFailedCallback = null
            val intent = Intent(context, DisplayCaptureForegroundService::class.java)
            context.stopService(intent)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return try {
            startAsForegroundService()
            isForeground = true
            foregroundReadyCallback?.invoke()
            START_STICKY
        } catch (error: Exception) {
            isForeground = false
            foregroundStartFailedCallback?.invoke(error)
            stopSelf()
            START_NOT_STICKY
        } finally {
            foregroundReadyCallback = null
            foregroundStartFailedCallback = null
        }
    }

    override fun onDestroy() {
        isForeground = false
        stopForegroundCompat()
        super.onDestroy()
    }

    private fun startAsForegroundService() {
        createNotificationChannelIfNeeded()

        val notification = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(android.R.drawable.ic_menu_camera)
            .setContentTitle("Screen recording active")
            .setContentText("Aks is preparing or capturing your screen.")
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                notificationId,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION or
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE,
            )
            return
        }

        startForeground(notificationId, notification)
    }

    private fun createNotificationChannelIfNeeded() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val manager = getSystemService(NotificationManager::class.java) ?: return
        val channel = NotificationChannel(
            channelId,
            channelName,
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Required while Aks records the device screen."
            setShowBadge(false)
        }
        manager.createNotificationChannel(channel)
    }

    private fun stopForegroundCompat() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
            return
        }

        @Suppress("DEPRECATION")
        stopForeground(true)
    }
}
