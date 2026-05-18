package com.pocketpet

import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import com.pocketpet.plugins.ScreenTimePlugin
import com.pocketpet.plugins.NotificationPlugin

class MainActivity : FlutterActivity() {

    companion object {
        const val SCREEN_TIME_CHANNEL = "pocketpet/screentime"
        const val NOTIFICATION_CHANNEL = "pocketpet/notifications"
        const val OVERLAY_CHANNEL = "pocketpet/overlay"
        const val PERMISSION_CHANNEL = "pocketpet/permissions"
    }

    private lateinit var screenTimePlugin: ScreenTimePlugin

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        screenTimePlugin = ScreenTimePlugin(this)

        // --- Screen Time channel ---
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SCREEN_TIME_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getUsageStats" -> {
                        val hours = call.argument<Int>("hours") ?: 1
                        result.success(screenTimePlugin.getUsageStats(hours))
                    }
                    "getAppUsageMinutes" -> {
                        val pkg = call.argument<String>("package") ?: ""
                        val mins = call.argument<Int>("minutes") ?: 60
                        result.success(screenTimePlugin.getAppUsageMinutes(pkg, mins))
                    }
                    "hasUsagePermission" -> result.success(hasUsageStatsPermission())
                    "openUsageSettings" -> {
                        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // --- Permissions channel ---
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSION_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasOverlayPermission" -> result.success(Settings.canDrawOverlays(this))
                    "openOverlaySettings" -> {
                        startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION).apply {
                            data = android.net.Uri.parse("package:$packageName")
                        })
                        result.success(null)
                    }
                    "hasNotificationListenerPermission" -> {
                        val cn = "$packageName/.services.PetNotificationService"
                        val flat = Settings.Secure.getString(contentResolver,
                            "enabled_notification_listeners") ?: ""
                        result.success(flat.contains(cn))
                    }
                    "openNotificationListenerSettings" -> {
                        startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                        result.success(null)
                    }
                    "hasUsagePermission" -> result.success(hasUsageStatsPermission())
                    "openUsageSettings" -> {
                        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                        result.success(null)
                    }
                    "openAccessibilitySettings" -> {
                        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // --- Notification events channel (stream) ---
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_CHANNEL)
            .setStreamHandler(NotificationPlugin.streamHandler)
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(), packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }
}
