package com.pocketpet.plugins

import io.flutter.plugin.common.EventChannel

/** Singleton stream handler — PetNotificationService pushes events here */
object NotificationPlugin {
    private var eventSink: EventChannel.EventSink? = null

    val streamHandler = object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            eventSink = events
        }
        override fun onCancel(arguments: Any?) {
            eventSink = null
        }
    }

    /** Called by PetNotificationService when a notification arrives */
    fun sendNotificationEvent(payload: Map<String, Any?>) {
        eventSink?.success(payload)
    }
}
