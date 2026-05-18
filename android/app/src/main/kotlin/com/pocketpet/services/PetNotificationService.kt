package com.pocketpet.services

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import com.pocketpet.plugins.NotificationPlugin

class PetNotificationService : NotificationListenerService() {

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val extras = sbn.notification.extras
        NotificationPlugin.sendNotificationEvent(
            mapOf(
                "id"          to sbn.key,
                "packageName" to sbn.packageName,
                "title"       to (extras?.getString("android.title") ?: ""),
                "text"        to (extras?.getCharSequence("android.text")?.toString() ?: ""),
                "timestamp"   to sbn.postTime,
                "priority"    to sbn.notification.priority,
                "category"    to (sbn.notification.category ?: "")
            )
        )
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        NotificationPlugin.sendNotificationEvent(
            mapOf("id" to sbn.key, "removed" to true)
        )
    }
}
