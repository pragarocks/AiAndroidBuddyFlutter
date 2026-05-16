package com.pocketpet.services

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent

class PetAccessibilityService : AccessibilityService() {
    override fun onAccessibilityEvent(event: AccessibilityEvent?) { /* future: dismiss/reply */ }
    override fun onInterrupt() {}
}
