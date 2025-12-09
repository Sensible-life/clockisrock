package com.example.clockisrock

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class UsageStatsPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "com.example.clockisrock/usage_stats")
        channel.setMethodCallHandler(this)
        context = binding.applicationContext
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "checkPermission" -> {
                result.success(checkUsageStatsPermission())
            }
            "openSettings" -> {
                openUsageStatsSettings()
                result.success(null)
            }
            "queryUsageStats" -> {
                val startTime = call.argument<Long>("startTime") ?: 0L
                val endTime = call.argument<Long>("endTime") ?: 0L
                queryUsageStats(startTime, endTime, result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun checkUsageStatsPermission(): Boolean {
        val appOpsManager = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOpsManager.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            android.os.Process.myUid(),
            context.packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun openUsageStatsSettings() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        context.startActivity(intent)
    }

    private fun queryUsageStats(startTime: Long, endTime: Long, result: MethodChannel.Result) {
        if (!checkUsageStatsPermission()) {
            result.error("PERMISSION_DENIED", "Usage Stats permission not granted", null)
            return
        }

        try {
            val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val packageManager = context.packageManager
            
            // 하루 전체의 앱별 총 사용 시간 가져오기
            val dailyStats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                startTime,
                endTime
            )
            
            // 오늘 날짜 범위 내의 Events만 조회 (00시부터 23시 59분 59초까지)
            val events = usageStatsManager.queryEvents(startTime, endTime)
            
            // 앱별로 시간대별 사용 시간 계산
            val appUsageByHour = mutableMapOf<String, MutableMap<Int, Long>>() // packageName -> hour -> duration
            val appNames = mutableMapOf<String, String>() // packageName -> appName
            
            // Events를 순회하며 시간대별 사용 시간 계산
            val packageStates = mutableMapOf<String, Long>() // packageName -> startTime
            
            while (events.hasNextEvent()) {
                val event = UsageEvents.Event()
                events.getNextEvent(event)
                
                when (event.eventType) {
                    UsageEvents.Event.ACTIVITY_RESUMED -> {
                        packageStates[event.packageName] = event.timeStamp
                    }
                    UsageEvents.Event.ACTIVITY_PAUSED -> {
                        val eventStartTime = packageStates.remove(event.packageName)
                        if (eventStartTime != null && eventStartTime > 0) {
                            val eventEndTime = event.timeStamp
                            
                            // 오늘 날짜 범위(00시~23시59분59초)로 제한
                            val todayStart = startTime
                            val todayEnd = endTime
                            val actualStartTime = if (eventStartTime < todayStart) todayStart else eventStartTime
                            val actualEndTime = if (eventEndTime > todayEnd) todayEnd else eventEndTime
                            
                            // 오늘 범위 내에 있는 경우만 처리
                            if (actualStartTime < actualEndTime && actualStartTime >= todayStart && actualEndTime <= todayEnd) {
                                if (!appUsageByHour.containsKey(event.packageName)) {
                                    appUsageByHour[event.packageName] = mutableMapOf()
                                }
                                
                                // 시작 시간부터 종료 시간까지 모든 시간대에 정확히 분배
                                var currentTime = actualStartTime
                                val calendar = java.util.Calendar.getInstance()
                                
                                while (currentTime < actualEndTime) {
                                    calendar.timeInMillis = currentTime
                                    val currentHour = calendar.get(java.util.Calendar.HOUR_OF_DAY)
                                    
                                    // 현재 시간대의 시작 시간 계산
                                    val hourStart = calendar.clone() as java.util.Calendar
                                    hourStart.set(java.util.Calendar.MINUTE, 0)
                                    hourStart.set(java.util.Calendar.SECOND, 0)
                                    hourStart.set(java.util.Calendar.MILLISECOND, 0)
                                    
                                    // 다음 시간대의 시작 시간 계산
                                    val nextHourStart = hourStart.clone() as java.util.Calendar
                                    nextHourStart.add(java.util.Calendar.HOUR_OF_DAY, 1)
                                    
                                    // 현재 시간대에서 사용한 시간 계산 (오늘 범위 내로 제한)
                                    val hourEnd = when {
                                        nextHourStart.timeInMillis > actualEndTime -> actualEndTime
                                        nextHourStart.timeInMillis > todayEnd -> todayEnd
                                        else -> nextHourStart.timeInMillis
                                    }
                                    val durationInHour = hourEnd - currentTime
                                    
                                    if (durationInHour > 0 && currentHour in 0..23) {
                                        appUsageByHour[event.packageName]!![currentHour] = 
                                            (appUsageByHour[event.packageName]!![currentHour] ?: 0L) + durationInHour
                                    }
                                    
                                    currentTime = hourEnd
                                }
                            }
                            
                            // 앱 이름 저장
                            if (!appNames.containsKey(event.packageName)) {
                                try {
                                    val appInfo = packageManager.getApplicationInfo(event.packageName, 0)
                                    appNames[event.packageName] = packageManager.getApplicationLabel(appInfo).toString()
                                } catch (e: PackageManager.NameNotFoundException) {
                                    appNames[event.packageName] = event.packageName
                                }
                            }
                        }
                    }
                }
            }
            
            // 하루 전체 총 사용 시간도 포함하여 반환
            val resultList = mutableListOf<Map<String, Any>>()
            
            // Daily stats로 총 사용 시간 확인
            dailyStats?.forEach { stat ->
                if (stat.totalTimeInForeground > 0) {
                    val appName = try {
                        val appInfo = packageManager.getApplicationInfo(stat.packageName, 0)
                        packageManager.getApplicationLabel(appInfo).toString()
                    } catch (e: PackageManager.NameNotFoundException) {
                        stat.packageName
                    }
                    
                    // 시간대별 사용 시간 가져오기
                    val hourlyUsage = appUsageByHour[stat.packageName] ?: emptyMap<Int, Long>()
                    
                    // 시간대별 합계 계산 (검증용)
                    val hourlyTotal = hourlyUsage.values.sum()
                    
                    // 시간대별 합계와 총 시간이 다르면 경고 (디버그용)
                    if (hourlyTotal != stat.totalTimeInForeground && hourlyUsage.isNotEmpty()) {
                        android.util.Log.w("UsageStatsPlugin", 
                            "앱 ${stat.packageName}: 시간대별 합계(${hourlyTotal}ms) != 총 시간(${stat.totalTimeInForeground}ms)")
                    }
                    
                    resultList.add(mapOf(
                        "packageName" to stat.packageName,
                        "appName" to appName,
                        "lastTimeUsed" to stat.lastTimeUsed,
                        "totalTimeInForeground" to stat.totalTimeInForeground,
                        "firstTimeStamp" to stat.firstTimeStamp,
                        "lastTimeStamp" to stat.lastTimeStamp,
                        "hourlyUsage" to hourlyUsage.map { (hour, duration) ->
                            mapOf("hour" to hour, "duration" to duration)
                        },
                        "hourlyTotal" to hourlyTotal // 검증용
                    ))
                }
            }

            result.success(resultList)
        } catch (e: Exception) {
            result.error("QUERY_ERROR", "Failed to query usage stats: ${e.message}", e.stackTraceToString())
        }
    }
}

