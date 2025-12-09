# 실제 데이터 연동 구현 예시

## 1. Usage Stats API 구현 예시

### 1.1 Kotlin 플러그인 파일

**파일**: `android/app/src/main/kotlin/com/example/clockisrock/UsageStatsPlugin.kt`

```kotlin
package com.example.clockisrock

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
        val appOpsManager = context.getSystemService(Context.APP_OPS_SERVICE) as android.app.AppOpsManager
        val mode = appOpsManager.checkOpNoThrow(
            android.app.AppOpsManager.OPSTR_GET_USAGE_STATS,
            android.os.Process.myUid(),
            context.packageName
        )
        return mode == android.app.AppOpsManager.MODE_ALLOWED
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

        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        )

        val packageManager = context.packageManager
        val usageStatsList = stats?.map { stat ->
            val appName = try {
                val appInfo = packageManager.getApplicationInfo(stat.packageName, 0)
                packageManager.getApplicationLabel(appInfo).toString()
            } catch (e: PackageManager.NameNotFoundException) {
                stat.packageName
            }

            mapOf(
                "packageName" to stat.packageName,
                "appName" to appName,
                "lastTimeUsed" to stat.lastTimeUsed,
                "totalTimeInForeground" to stat.totalTimeInForeground,
                "firstTimeStamp" to stat.firstTimeStamp,
                "lastTimeStamp" to stat.lastTimeStamp
            )
        } ?: emptyList()

        result.success(usageStatsList)
    }
}
```

### 1.2 MainActivity 수정

**파일**: `android/app/src/main/kotlin/com/example/clockisrock/MainActivity.kt`

```kotlin
package com.example.clockisrock

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(UsageStatsPlugin())
    }
}
```

### 1.3 Flutter 서비스 수정

**파일**: `lib/services/screen_data_service.dart` (수정 부분)

```dart
/// Usage Stats 권한 확인 및 요청
Future<bool> requestPermission() async {
  try {
    final result = await platform.invokeMethod<bool>('checkPermission');
    return result ?? false;
  } catch (e) {
    print('Usage Stats 권한 확인 오류: $e');
    return false;
  }
}

/// Usage Stats 설정 화면으로 이동
Future<void> openUsageStatsSettings() async {
  try {
    await platform.invokeMethod('openSettings');
  } catch (e) {
    print('설정 화면 열기 오류: $e');
  }
}

/// 특정 날짜의 스크린 사용 데이터 가져오기
Future<List<ScreenData>> getScreenDataForDate(DateTime date) async {
  final hasPermission = await requestPermission();
  if (!hasPermission) {
    throw Exception('Usage Stats 권한이 필요합니다.');
  }

  final startTime = DateTime(date.year, date.month, date.day, 0, 0, 0);
  final endTime = DateTime(date.year, date.month, date.day, 23, 59, 59);

  try {
    final result = await platform.invokeMethod<List<dynamic>>(
      'queryUsageStats',
      {
        'startTime': startTime.millisecondsSinceEpoch,
        'endTime': endTime.millisecondsSinceEpoch,
      },
    );

    final List<ScreenData> screenDataList = [];

    if (result != null) {
      for (var stat in result) {
        final totalTime = stat['totalTimeInForeground'] as int? ?? 0;
        if (totalTime > 0) {
          screenDataList.add(
            ScreenData(
              packageName: stat['packageName'] as String? ?? '',
              appName: stat['appName'] as String? ?? '',
              usageTime: Duration(milliseconds: totalTime),
              timestamp: DateTime.fromMillisecondsSinceEpoch(
                stat['lastTimeUsed'] as int? ?? 0,
              ),
            ),
          );
        }
      }
    }

    return screenDataList;
  } catch (e) {
    print('Usage Stats 조회 오류: $e');
    rethrow;
  }
}
```

---

## 2. Google Calendar API 구현 예시

### 2.1 인증 서비스

**파일**: `lib/services/auth_service.dart` (새로 생성)

```dart
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthService {
  static const String _clientId = 'YOUR_CLIENT_ID.apps.googleusercontent.com';
  static const String _clientSecret = 'YOUR_CLIENT_SECRET';
  static const List<String> _scopes = [calendar.CalendarApi.calendarReadonlyScope];

  Future<AutoRefreshingAuthClient> authenticate() async {
    // 저장된 토큰 확인
    final prefs = await SharedPreferences.getInstance();
    final tokenJson = prefs.getString('google_calendar_token');
    
    if (tokenJson != null) {
      try {
        final token = AccessCredentials.fromJson(jsonDecode(tokenJson));
        // 토큰이 유효한지 확인하고 갱신
        return autoRefreshingClient(
          ClientCredentials(_clientId, _clientSecret),
          token,
          httpClient,
        );
      } catch (e) {
        // 토큰이 유효하지 않으면 재인증
      }
    }

    // 새로운 인증
    final client = await clientViaUserConsent(
      ClientCredentials(_clientId, _clientSecret),
      _scopes,
      (url) async {
        // 웹뷰나 브라우저로 URL 열기
        // 실제로는 url_launcher 패키지 사용
        print('인증 URL: $url');
        // 사용자가 URL을 열고 인증 코드를 입력하도록 안내
      },
      httpClient,
    );

    // 토큰 저장
    await prefs.setString('google_calendar_token', jsonEncode(client.credentials));

    return client;
  }
}
```

### 2.2 Calendar 서비스 수정

**파일**: `lib/services/calendar_service.dart` (수정 부분)

```dart
import 'package:googleapis/calendar/v3.dart' as calendar;
import '../models/calendar_data.dart';
import 'auth_service.dart';

class CalendarService {
  final AuthService _authService = AuthService();
  calendar.CalendarApi? _calendarApi;

  /// 구글 캘린더 인증
  Future<bool> authenticate() async {
    try {
      final client = await _authService.authenticate();
      _calendarApi = calendar.CalendarApi(client);
      return true;
    } catch (e) {
      print('캘린더 인증 오류: $e');
      return false;
    }
  }

  /// 특정 날짜의 캘린더 이벤트 가져오기
  Future<List<CalendarEvent>> getEventsForDate(DateTime date) async {
    if (_calendarApi == null) {
      final authenticated = await authenticate();
      if (!authenticated) {
        throw Exception('캘린더 인증에 실패했습니다.');
      }
    }

    final startTime = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final endTime = DateTime(date.year, date.month, date.day, 23, 59, 59);

    try {
      final events = await _calendarApi!.events.list(
        'primary',
        timeMin: startTime.toUtc(),
        timeMax: endTime.toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
      );

      final List<CalendarEvent> calendarEvents = [];

      for (var event in events.items ?? []) {
        final start = event.start?.dateTime ?? event.start?.date;
        final end = event.end?.dateTime ?? event.end?.date;

        if (start != null && end != null) {
          calendarEvents.add(
            CalendarEvent(
              id: event.id ?? '',
              title: event.summary ?? '제목 없음',
              description: event.description,
              startTime: start,
              endTime: end,
              location: event.location,
              eventType: _determineEventType(event),
            ),
          );
        }
      }

      return calendarEvents;
    } catch (e) {
      print('캘린더 이벤트 조회 오류: $e');
      rethrow;
    }
  }

  /// 이벤트 타입 결정
  String? _determineEventType(calendar.Event event) {
    final summary = (event.summary ?? '').toLowerCase();
    final description = (event.description ?? '').toLowerCase();

    if (summary.contains('meeting') || summary.contains('회의') || 
        summary.contains('미팅')) {
      return 'meeting';
    } else if (summary.contains('work') || summary.contains('작업') ||
               summary.contains('프로젝트')) {
      return 'work';
    } else if (summary.contains('study') || summary.contains('공부') ||
               summary.contains('학습')) {
      return 'study';
    } else if (summary.contains('lunch') || summary.contains('점심') ||
               summary.contains('dinner') || summary.contains('저녁')) {
      return 'personal';
    }
    return null;
  }
}
```

### 2.3 필요한 추가 패키지

**파일**: `pubspec.yaml`

```yaml
dependencies:
  url_launcher: ^6.2.5  # 인증 URL 열기용
```

---

## 3. Health Connect 추가 설정

### 3.1 Health Connect 권한 선언

**파일**: `android/app/src/main/AndroidManifest.xml`

```xml
<!-- Health Connect 권한 -->
<uses-permission android:name="android.permission.READ_HEALTH_DATA" />

<!-- Health Connect 패키지 선언 -->
<queries>
    <package android:name="com.google.android.apps.healthdata" />
</queries>
```

### 3.2 Health Connect 앱 확인

**파일**: `lib/services/health_data_service.dart` (추가 메서드)

```dart
/// Health Connect 앱 설치 여부 확인
Future<bool> isHealthConnectInstalled() async {
  try {
    // Health Connect 패키지 확인
    // 실제 구현은 platform channel 필요
    return true; // 간단한 버전
  } catch (e) {
    return false;
  }
}

/// Health Connect 앱으로 이동
Future<void> openHealthConnectApp() async {
  try {
    // Health Connect 앱 열기
    // 실제 구현은 url_launcher 사용
  } catch (e) {
    print('Health Connect 앱 열기 오류: $e');
  }
}
```

---

## 4. 통합 테스트 체크리스트

### 4.1 Usage Stats
- [ ] Kotlin 플러그인 컴파일 확인
- [ ] 권한 요청 화면 정상 동작
- [ ] 실제 앱 사용 데이터 수집 확인
- [ ] 앱 이름 정확히 표시되는지 확인

### 4.2 Google Calendar
- [ ] OAuth 인증 플로우 정상 동작
- [ ] 토큰 저장 및 자동 갱신 확인
- [ ] 캘린더 이벤트 정확히 가져오는지 확인
- [ ] 이벤트 타입 분류 정확도 확인

### 4.3 Health Connect
- [ ] Health Connect 앱 설치 확인
- [ ] 권한 요청 정상 동작
- [ ] 실제 헬스 데이터 수집 확인
- [ ] 데이터 타입별 권한 확인

---

## 5. 주의사항

### 5.1 Usage Stats
- **에뮬레이터 제한**: Usage Stats는 실제 기기에서만 정확히 동작
- **배터리 최적화**: 일부 기기에서 배터리 최적화로 인해 데이터 수집 제한 가능
- **앱 이름**: PackageManager를 통해 가져오므로 정확도 높음

### 5.2 Google Calendar
- **OAuth 보안**: 클라이언트 시크릿은 서버에 저장하는 것이 안전 (클라이언트 앱에는 노출 지양)
- **토큰 관리**: Secure Storage 사용 권장
- **API 할당량**: Google Calendar API는 일일 할당량이 있음

### 5.3 Health Connect
- **Android 버전**: Android 14 이상 권장
- **데이터 동기화**: 삼성 헬스 등 다른 앱과의 동기화 확인 필요
- **권한**: 각 데이터 타입별로 개별 권한 요청 필요

---

이 예시 코드들을 참고하여 실제 데이터 연동을 구현하세요!


