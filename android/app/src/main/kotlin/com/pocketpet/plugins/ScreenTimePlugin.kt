package com.pocketpet.plugins

import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.pm.PackageManager

class ScreenTimePlugin(private val context: Context) {

    private val usageStatsManager: UsageStatsManager by lazy {
        context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
    }

    private val packageManager: PackageManager get() = context.packageManager

    /** Returns a list of maps: [{package, appLabel, usageMinutes}] for the last [hours] hours */
    fun getUsageStats(hours: Int): List<Map<String, Any>> {
        val endTime = System.currentTimeMillis()
        val startTime = endTime - hours * 60L * 60 * 1000

        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_BEST, startTime, endTime
        ) ?: return emptyList()

        return stats
            .filter { it.totalTimeInForeground > 0 }
            .sortedByDescending { it.totalTimeInForeground }
            .mapNotNull { stat ->
                val label = try {
                    val appInfo = packageManager.getApplicationInfo(stat.packageName, 0)
                    packageManager.getApplicationLabel(appInfo).toString()
                } catch (e: Exception) { stat.packageName }

                mapOf(
                    "package" to stat.packageName,
                    "appLabel" to label,
                    "usageMinutes" to (stat.totalTimeInForeground / 60_000L).toInt()
                )
            }
    }

    /** Returns minutes spent in a specific [packageName] app within the last [minutes] window */
    fun getAppUsageMinutes(packageName: String, minutes: Int): Int {
        val endTime = System.currentTimeMillis()
        val startTime = endTime - minutes * 60L * 1000

        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_BEST, startTime, endTime
        ) ?: return 0

        val stat = stats.find { it.packageName == packageName } ?: return 0
        return (stat.totalTimeInForeground / 60_000L).toInt()
    }
}
