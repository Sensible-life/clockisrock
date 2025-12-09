import 'dart:async';
import 'package:flutter/services.dart';
import 'package:android_intent_plus/android_intent.dart';
import '../models/screen_data.dart';
import 'package:permission_handler/permission_handler.dart';

class ScreenDataService {
  static const platform = MethodChannel('com.example.clockisrock/usage_stats');

  /// Usage Stats 권한 확인 및 요청
  Future<bool> requestPermission() async {
    try {
      final result = await platform.invokeMethod<bool>('checkPermission');
      // ignore: avoid_print
      print('Usage Stats 권한 확인 결과: $result');
      return result ?? false;
    } catch (e) {
      // ignore: avoid_print
      print('Usage Stats 권한 확인 오류: $e');
      return false;
    }
  }

  /// Usage Stats 설정 화면으로 이동
  Future<void> openUsageStatsSettings() async {
    try {
      // 안드로이드 Intent를 사용하여 Usage Stats 설정 화면 열기
      final AndroidIntent intent = AndroidIntent(
        action: 'android.settings.USAGE_ACCESS_SETTINGS',
      );
      await intent.launch();
    } catch (e) {
      // ignore: avoid_print
      print('Usage Stats 설정 화면 열기 오류: $e');
      // 대안: 일반 앱 설정 화면 열기
      try {
        await openAppSettings();
      } catch (e2) {
        // ignore: avoid_print
        print('앱 설정 화면 열기 오류: $e2');
      }
    }
  }

  /// 특정 날짜의 스크린 사용 데이터 가져오기
  Future<List<ScreenData>> getScreenDataForDate(DateTime date) async {
    // 한국 시간대(UTC+9)로 날짜 범위 설정
    // DateTime.now()는 로컬 시간대를 사용하므로, 한국에 있으면 한국 시간대(UTC+9)를 사용
    // date가 UTC일 수 있으므로 로컬 시간대로 변환
    final now = DateTime.now(); // 현재 로컬 시간
    final localDate = date.isUtc ? date.toLocal() : date;
    
    // 로컬 시간대 기준으로 해당 날짜의 00:00:00과 23:59:59 생성
    // DateTime 생성자는 로컬 시간대를 사용하므로, 한국에 있으면 한국 시간대를 사용
    final startTime = DateTime(localDate.year, localDate.month, localDate.day, 0, 0, 0);
    final endTime = DateTime(localDate.year, localDate.month, localDate.day, 23, 59, 59, 999);
    
    // ignore: avoid_print
    // print('=== 스크린 데이터 조회 시작 ===');
    // print('현재 시간: $now (로컬)');
    // print('입력 날짜: $date (UTC: ${date.isUtc})');
    // print('로컬 날짜: $localDate');
    // print('조회 날짜: ${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}');
    // print('시작 시간: $startTime (로컬 시간대, isUtc: ${startTime.isUtc})');
    // print('종료 시간: $endTime (로컬 시간대, isUtc: ${endTime.isUtc})');
    // print('시작 시간 UTC: ${startTime.toUtc()}');
    // print('종료 시간 UTC: ${endTime.toUtc()}');
    // print('시작 시간 (밀리초): ${startTime.millisecondsSinceEpoch}');
    // print('종료 시간 (밀리초): ${endTime.millisecondsSinceEpoch}');
    
    try {
      // 실제 Usage Stats API 호출 시도
      final result = await platform.invokeMethod(
        'queryUsageStats',
        {
          'startTime': startTime.millisecondsSinceEpoch,
          'endTime': endTime.millisecondsSinceEpoch,
        },
      );
      
      // ignore: avoid_print
      // print('Usage Stats API 호출 성공');
      // print('반환된 데이터 타입: ${result.runtimeType}');
      
      if (result != null) {
        // 타입 안전하게 변환
        final List<dynamic> resultList = result is List ? result : [];
        // ignore: avoid_print
        // print('반환된 데이터 개수: ${resultList.length}');
        
        if (resultList.isNotEmpty) {
          final List<ScreenData> screenDataList = [];
          
          // ignore: avoid_print
          // print('=== 실제 디지털 웰빙 데이터 (Usage Stats API) ===');
          
          // 각 항목을 Map으로 변환
          final List<Map<String, dynamic>> sortedStats = [];
          for (var item in resultList) {
            if (item is Map) {
              // Map<Object?, Object?>를 Map<String, dynamic>으로 변환
              final Map<String, dynamic> stat = {};
              item.forEach((key, value) {
                stat[key.toString()] = value;
              });
              sortedStats.add(stat);
            }
          }
          
          // 사용 시간 순으로 정렬
          sortedStats.sort((a, b) {
            final timeA = (a['totalTimeInForeground'] as num?)?.toInt() ?? 0;
            final timeB = (b['totalTimeInForeground'] as num?)?.toInt() ?? 0;
            return timeB.compareTo(timeA); // 내림차순
          });
          
          // ignore: avoid_print
          // print('총 ${sortedStats.length}개 앱의 사용 데이터:');
          
          for (var stat in sortedStats) {
            final packageName = stat['packageName']?.toString() ?? '';
            final appName = stat['appName']?.toString() ?? '';
            final totalTimeInForeground = (stat['totalTimeInForeground'] as num?)?.toInt() ?? 0;
            final lastTimeUsed = (stat['lastTimeUsed'] as num?)?.toInt() ?? 0;
            final firstTimeStamp = (stat['firstTimeStamp'] as num?)?.toInt() ?? 0;
            final lastTimeStamp = (stat['lastTimeStamp'] as num?)?.toInt() ?? 0;
            final hourlyUsageRaw = stat['hourlyUsage'];
            final List<dynamic> hourlyUsage = hourlyUsageRaw is List ? hourlyUsageRaw : [];
            
            final usageMinutes = (totalTimeInForeground / 1000 / 60).round();
            final usageHours = usageMinutes ~/ 60;
            final remainingMinutes = usageMinutes % 60;
            
            // ignore: avoid_print
            // if (usageHours > 0) {
            //   print('  $appName: ${usageHours}시간 ${remainingMinutes}분 (총 ${totalTimeInForeground}ms)');
            // } else {
            //   print('  $appName: ${remainingMinutes}분 (총 ${totalTimeInForeground}ms)');
            // }
            // print('    패키지: $packageName');
            
            // 타임스탬프는 밀리초 단위이므로 UTC로 간주하고 로컬 시간대로 변환
            // 하지만 Usage Stats API는 시스템 시간대를 사용하므로 isUtc: false 사용
            final firstTimeLocal = DateTime.fromMillisecondsSinceEpoch(firstTimeStamp, isUtc: false);
            final lastTimeLocal = DateTime.fromMillisecondsSinceEpoch(lastTimeUsed, isUtc: false);
            
            // 오늘 날짜 범위로 클리핑
            final todayStart = startTime;
            final todayEnd = endTime;
            final firstTimeInToday = firstTimeLocal.isBefore(todayStart) ? todayStart : firstTimeLocal;
            final lastTimeInToday = lastTimeLocal.isAfter(todayEnd) ? todayEnd : lastTimeLocal;
            
            // ignore: avoid_print
            // print('    첫 사용 (원본): $firstTimeLocal');
            // print('    첫 사용 (오늘 범위): $firstTimeInToday');
            // print('    마지막 사용 (원본): $lastTimeLocal');
            // print('    마지막 사용 (오늘 범위): $lastTimeInToday');
            
            // 시간대별 사용 시간이 있으면 표시
            if (hourlyUsage.isNotEmpty) {
              // ignore: avoid_print
              // print('    시간대별 사용:');
              var totalHourlyMinutes = 0;
              var totalHourlyMs = 0;
              for (var hourData in hourlyUsage) {
                if (hourData is Map) {
                  final hour = ((hourData['hour'] as num?)?.toInt()) ?? 0;
                  final duration = ((hourData['duration'] as num?)?.toInt()) ?? 0;
                  final hourMinutes = (duration / 1000 / 60).round();
                  totalHourlyMinutes += hourMinutes;
                  totalHourlyMs += duration;
                  // ignore: avoid_print
                  // print('      ${hour}시: ${hourMinutes}분 (${duration}ms)');
                }
              }
              // ignore: avoid_print
              // print('    시간대별 합계: ${totalHourlyMinutes ~/ 60}시간 ${totalHourlyMinutes % 60}분 ($totalHourlyMinutes분, ${totalHourlyMs}ms)');
              // print('    총 사용 시간: ${usageHours}시간 ${remainingMinutes}분 ($usageMinutes분, ${totalTimeInForeground}ms)');
              // if (totalHourlyMs != totalTimeInForeground) {
              //   print('    ⚠️ 경고: 시간대별 합계(${totalHourlyMs}ms)와 총 사용 시간(${totalTimeInForeground}ms)이 일치하지 않습니다!');
              //   print('    차이: ${(totalTimeInForeground - totalHourlyMs) / 1000 / 60}분');
              // }
            }
            
            if (totalTimeInForeground > 0) {
              // 시간대별 사용 시간이 있으면 각 시간대별로 ScreenData 생성
              if (hourlyUsage.isNotEmpty) {
                for (var hourData in hourlyUsage) {
                  if (hourData is Map) {
                    final hour = ((hourData['hour'] as num?)?.toInt()) ?? 0;
                    final duration = ((hourData['duration'] as num?)?.toInt()) ?? 0;
                    
                    if (duration > 0) {
                      // 로컬 날짜와 시간대 사용
                      final localDate = date.toLocal();
                      screenDataList.add(
                        ScreenData(
                          packageName: packageName,
                          appName: appName,
                          usageTime: Duration(milliseconds: duration),
                          timestamp: DateTime(localDate.year, localDate.month, localDate.day, hour, 0),
                        ),
                      );
                    }
                  }
                }
              } else {
                // 시간대별 데이터가 없으면 총 사용 시간을 오늘 날짜의 첫 사용 시간대에 할당
                // 하지만 이 경우는 실제로는 시간대별 데이터가 있어야 하므로 경고
                // ignore: avoid_print
                // print('    ⚠️ 경고: 시간대별 데이터가 없습니다. 총 사용 시간을 첫 시간대에 할당합니다.');
                
                if (firstTimeStamp > 0) {
                  // 타임스탬프를 로컬 시간대로 변환
                  final usageTime = DateTime.fromMillisecondsSinceEpoch(firstTimeStamp, isUtc: false);
                  // 오늘 범위로 클리핑
                  final todayStart = startTime;
                  final actualUsageTime = usageTime.isBefore(todayStart) ? todayStart : usageTime;
                  final hour = DateTime(actualUsageTime.year, actualUsageTime.month, actualUsageTime.day, actualUsageTime.hour);
                  
                  screenDataList.add(
                    ScreenData(
                      packageName: packageName,
                      appName: appName,
                      usageTime: Duration(milliseconds: totalTimeInForeground),
                      timestamp: hour,
                    ),
                  );
                }
              }
            }
          }
          
        // ignore: avoid_print
        // print('변환된 스크린 데이터 개수: ${screenDataList.length}');
        // print('=== 스크린 데이터 조회 완료 ===');
          
          return screenDataList;
        } else {
          // ignore: avoid_print
          // print('Usage Stats API에서 데이터가 없습니다. 샘플 데이터 반환');
        }
      } else {
        // ignore: avoid_print
        // print('Usage Stats API에서 데이터가 없거나 실패했습니다. 샘플 데이터 반환');
      }
    } catch (e) {
      // ignore: avoid_print
      // print('Usage Stats API 호출 실패: $e');
      // print('스택 트레이스: ${StackTrace.current}');
      // print('샘플 데이터를 반환합니다.');
    }
    
    // 데모 버전: 샘플 데이터 반환
    // 실제 구현에서는 Usage Stats API 사용
    final List<ScreenData> screenDataList = [];

    // ignore: avoid_print
    // print('샘플 데이터 생성 중...');
    
    // 샘플 데이터 생성
    final apps = [
      {'name': 'Chrome', 'package': 'com.android.chrome'},
      {'name': 'Gmail', 'package': 'com.google.android.gm'},
      {'name': 'Slack', 'package': 'com.slack'},
      {'name': 'YouTube', 'package': 'com.google.android.youtube'},
      {'name': 'Instagram', 'package': 'com.instagram.android'},
    ];

    for (int hour = 9; hour < 18; hour++) {
      final appIndex = hour % apps.length;
      final app = apps[appIndex];
      final usageMinutes = 20 + (hour % 3) * 15; // 20-50분 사이

      screenDataList.add(
        ScreenData(
          packageName: app['package']!,
          appName: app['name']!,
          usageTime: Duration(minutes: usageMinutes),
          timestamp: DateTime(date.year, date.month, date.day, hour, 0),
        ),
      );
    }
    
    // ignore: avoid_print
    // print('샘플 데이터 생성 완료: ${screenDataList.length}개');
    // print('=== 스크린 데이터 조회 완료 (샘플) ===');

    return screenDataList;
  }

  /// 시간대별로 스크린 사용 데이터 그룹화
  Future<List<ScreenUsageSummary>> getScreenUsageByTimeSlot(DateTime date) async {
    // ignore: avoid_print
    // print('=== 시간대별 스크린 데이터 그룹화 시작 ===');
    // print('대상 날짜: ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}');
    
    final screenData = await getScreenDataForDate(date);
    
    // ignore: avoid_print
    // print('가져온 스크린 데이터 총 개수: ${screenData.length}');
    
    // 1시간 단위로 그룹화
    final Map<int, List<ScreenData>> grouped = {};
    
    for (var data in screenData) {
      final hour = data.timestamp.hour;
      if (!grouped.containsKey(hour)) {
        grouped[hour] = [];
      }
      grouped[hour]!.add(data);
      
      // ignore: avoid_print
      // print('  ${hour}시: ${data.appName} - ${data.usageTime.inMinutes}분');
    }
    
    // ignore: avoid_print
    // print('그룹화된 시간대: ${grouped.keys.toList()..sort()}');

    final List<ScreenUsageSummary> summaries = [];
    
    for (var entry in grouped.entries) {
      final hour = entry.key;
      final dataList = entry.value;
      
      final totalUsage = dataList.fold<Duration>(
        Duration.zero,
        (sum, data) => sum + data.usageTime,
      );

      // 가장 많이 사용한 앱 찾기
      final appUsageMap = <String, Duration>{};
      for (var data in dataList) {
        appUsageMap[data.packageName] = 
            (appUsageMap[data.packageName] ?? Duration.zero) + data.usageTime;
      }

      String? dominantApp;
      Duration maxUsage = Duration.zero;
      appUsageMap.forEach((package, duration) {
        if (duration > maxUsage) {
          maxUsage = duration;
          dominantApp = package;
        }
      });
      
      // ignore: avoid_print
      // print('${hour}시 요약: 총 ${totalUsage.inMinutes}분, 주요 앱: $dominantApp');

      summaries.add(
        ScreenUsageSummary(
          timeSlot: DateTime(date.year, date.month, date.day, hour),
          totalUsage: totalUsage,
          appUsages: dataList,
          dominantApp: dominantApp,
        ),
      );
    }
    
    // 24시간 모두 생성 (데이터가 없는 시간대도 포함)
    for (int hour = 0; hour < 24; hour++) {
      if (!grouped.containsKey(hour)) {
        summaries.add(
          ScreenUsageSummary(
            timeSlot: DateTime(date.year, date.month, date.day, hour),
            totalUsage: Duration.zero,
            appUsages: [],
            dominantApp: null,
          ),
        );
      }
    }

    summaries.sort((a, b) => a.timeSlot.compareTo(b.timeSlot));
    
    // ignore: avoid_print
    // print('최종 요약 개수: ${summaries.length}');
    // print('=== 시간대별 스크린 데이터 그룹화 완료 ===');
    
    return summaries;
  }

  /// 패키지 이름에서 앱 이름 추출 (간단한 버전)
  String _getAppName(String packageName) {
    // 패키지 이름의 마지막 부분을 앱 이름으로 사용
    final parts = packageName.split('.');
    if (parts.isEmpty) return packageName;
    
    String lastPart = parts.last;
    // 첫 글자를 대문자로
    if (lastPart.isNotEmpty) {
      lastPart = lastPart[0].toUpperCase() + lastPart.substring(1);
    }
    return lastPart;
  }
}


