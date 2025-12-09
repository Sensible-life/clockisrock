import 'dart:async';
import 'package:health/health.dart';
import '../models/health_data.dart';

class HealthDataService {
  Health? health;
  static const HealthDataType _steps = HealthDataType.STEPS;
  static const HealthDataType _heartRate = HealthDataType.HEART_RATE;
  static const HealthDataType _activeEnergyBurned = HealthDataType.ACTIVE_ENERGY_BURNED;
  static const HealthDataType _distanceWalkingRunning = HealthDataType.DISTANCE_WALKING_RUNNING;
  static const HealthDataType _sleep = HealthDataType.SLEEP_ASLEEP;

  List<HealthDataType> get types => [
        _steps,
        _heartRate,
        _activeEnergyBurned,
        _distanceWalkingRunning,
        _sleep,
      ];

  HealthDataService() {
    health = Health();
  }

  /// Health Connect 설치 확인
  Future<bool> isHealthConnectAvailable() async {
    if (health == null) return false;

    try {
      // Health Connect가 사용 가능한지 확인
      final types = [HealthDataType.STEPS];
      final available = await health!.hasPermissions(types);
      return available != null;
    } catch (e) {
      // ignore: avoid_print
      print('Health Connect 확인 오류: $e');
      return false;
    }
  }

  /// Health Connect 권한 요청
  Future<bool> requestPermission() async {
    if (health == null) return false;

    try {
      // 필수 데이터 타입들만 권한 요청
      final essentialTypes = [_steps, _heartRate, _activeEnergyBurned];
      final granted = await health!.requestAuthorization(essentialTypes);

      // 선택사항 데이터 (거리, 수면)
      try {
        await health!.requestAuthorization([_distanceWalkingRunning, _sleep]);
      } catch (e) {
        // ignore: avoid_print
        print('선택사항 데이터 권한 요청 실패: $e');
      }

      return granted;
    } catch (e) {
      // ignore: avoid_print
      print('Health 권한 요청 오류: $e');
      return false;
    }
  }

  /// 특정 날짜의 헬스 데이터 가져오기
  Future<List<HealthData>> getHealthDataForDate(DateTime date) async {
    if (health == null) {
      throw Exception('Health 서비스가 초기화되지 않았습니다.');
    }

    // 로컬 시간대 기준으로 날짜 범위 설정
    final localDate = date.isUtc ? date.toLocal() : date;
    final startTime = DateTime(localDate.year, localDate.month, localDate.day, 0, 0, 0);
    final endTime = DateTime(localDate.year, localDate.month, localDate.day, 23, 59, 59, 999);

    // ignore: avoid_print
    print('=== 헬스 데이터 조회 시작 ===');
    print('조회 날짜: ${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}');
    print('시작 시간 (로컬): $startTime');
    print('종료 시간 (로컬): $endTime');
    print('시작 시간 (UTC): ${startTime.toUtc()}');
    print('종료 시간 (UTC): ${endTime.toUtc()}');
    print('');
    print('⚠️ 참고: 현재 Health Connect API를 사용 중입니다.');
    print('삼성 기기에서는 삼성헬스 앱이 Health Connect에 데이터를 동기화해야 합니다.');
    print('Health Connect 앱 > 데이터 및 권한 > 데이터 소스에서 삼성헬스 연동을 확인하세요.');
    print('');

    try {
      // 필수 데이터 타입 권한 확인
      final essentialTypes = [_steps, _heartRate, _activeEnergyBurned];
      final hasPermission = await health!.hasPermissions(essentialTypes);
      // ignore: avoid_print
      print('권한 확인 결과: $hasPermission');
      
      if (hasPermission != true) {
        // ignore: avoid_print
        print('권한 요청 중...');
        final granted = await requestPermission();
        // ignore: avoid_print
        print('권한 요청 결과: $granted');
        if (!granted) {
          throw Exception('Health 권한이 필요합니다. Health Connect 앱을 설치하고 권한을 승인해주세요.');
        }
      }

      // 스텝 데이터
      // ignore: avoid_print
      print('걸음 수 데이터 조회 중...');
      print('  조회 시간 범위: ${startTime.toUtc()} ~ ${endTime.toUtc()} (UTC)');
      final steps = await health!.getHealthDataFromTypes(
        types: [_steps],
        startTime: startTime,
        endTime: endTime,
      );
      // ignore: avoid_print
      print('걸음 수 데이터 개수: ${steps.length}');
      if (steps.isEmpty) {
        print('  ⚠️ 데이터가 없습니다.');
        print('  삼성헬스 앱에서 Health Connect로 데이터를 동기화했는지 확인하세요.');
        print('  Health Connect 앱 > 데이터 및 권한 > 데이터 소스 > 삼성헬스');
      }
      var totalSteps = 0.0;
      for (var step in steps) {
        final value = _getNumericValue(step.value);
        totalSteps += value;
        // ignore: avoid_print
        print('  걸음 수: $value (${step.dateFrom} ~ ${step.dateTo})');
      }
      // ignore: avoid_print
      print('총 걸음 수: $totalSteps');

      // 심박수 데이터
      // ignore: avoid_print
      print('심박수 데이터 조회 중...');
      print('  조회 시간 범위 (로컬): $startTime ~ $endTime');
      print('  조회 시간 범위 (UTC): ${startTime.toUtc()} ~ ${endTime.toUtc()}');
      final heartRate = await health!.getHealthDataFromTypes(
        types: [_heartRate],
        startTime: startTime,
        endTime: endTime,
      );
      // ignore: avoid_print
      print('심박수 데이터 개수: ${heartRate.length}');
      if (heartRate.isEmpty) {
        print('  ⚠️ 데이터가 없습니다.');
        print('  삼성헬스 앱에서 Health Connect로 데이터를 동기화했는지 확인하세요.');
        print('  Health Connect 앱 > 데이터 및 권한 > 데이터 소스 > 삼성헬스');
        print('  또는 Health Connect 앱에서 직접 심박수 데이터가 있는지 확인하세요.');
      } else {
        print('  ✅ 데이터 포인트 상세:');
        var totalHeartRate = 0.0;
        var heartRateCount = 0;
        for (var hr in heartRate) {
          final value = _getNumericValue(hr.value);
          totalHeartRate += value;
          heartRateCount++;
          final dateFromLocal = hr.dateFrom.toLocal();
          final dateToLocal = hr.dateTo.toLocal();
          // ignore: avoid_print
          print('    심박수: ${value.toInt()} bpm');
          print('      시간: ${dateFromLocal.year}-${dateFromLocal.month.toString().padLeft(2, '0')}-${dateFromLocal.day.toString().padLeft(2, '0')} ${dateFromLocal.hour.toString().padLeft(2, '0')}:${dateFromLocal.minute.toString().padLeft(2, '0')} ~ ${dateToLocal.hour.toString().padLeft(2, '0')}:${dateToLocal.minute.toString().padLeft(2, '0')}');
          print('      UTC: ${hr.dateFrom} ~ ${hr.dateTo}');
        }
        if (heartRateCount > 0) {
          // ignore: avoid_print
          print('  평균 심박수: ${(totalHeartRate / heartRateCount).toInt()} bpm');
        }
      }

      // 칼로리 데이터
      // ignore: avoid_print
      print('칼로리(운동) 데이터 조회 중...');
      print('  조회 시간 범위 (로컬): $startTime ~ $endTime');
      print('  조회 시간 범위 (UTC): ${startTime.toUtc()} ~ ${endTime.toUtc()}');
      final calories = await health!.getHealthDataFromTypes(
        types: [_activeEnergyBurned],
        startTime: startTime,
        endTime: endTime,
      );
      // ignore: avoid_print
      print('칼로리 데이터 개수: ${calories.length}');
      if (calories.isEmpty) {
        print('  ⚠️ 데이터가 없습니다.');
        print('  삼성헬스 앱에서 Health Connect로 데이터를 동기화했는지 확인하세요.');
        print('  Health Connect 앱 > 데이터 및 권한 > 데이터 소스 > 삼성헬스');
        print('  또는 Health Connect 앱에서 직접 칼로리 데이터가 있는지 확인하세요.');
      } else {
        print('  ✅ 데이터 포인트 상세:');
        var totalCalories = 0.0;
        for (var cal in calories) {
          final value = _getNumericValue(cal.value);
          totalCalories += value;
          final dateFromLocal = cal.dateFrom.toLocal();
          final dateToLocal = cal.dateTo.toLocal();
          // ignore: avoid_print
          print('    칼로리: ${value.toInt()} kcal');
          print('      시간: ${dateFromLocal.year}-${dateFromLocal.month.toString().padLeft(2, '0')}-${dateFromLocal.day.toString().padLeft(2, '0')} ${dateFromLocal.hour.toString().padLeft(2, '0')}:${dateFromLocal.minute.toString().padLeft(2, '0')} ~ ${dateToLocal.hour.toString().padLeft(2, '0')}:${dateToLocal.minute.toString().padLeft(2, '0')}');
          print('      UTC: ${cal.dateFrom} ~ ${cal.dateTo}');
        }
        // ignore: avoid_print
        print('  총 칼로리: ${totalCalories.toInt()} kcal');
      }

      // 거리 데이터 (선택사항 - 실패해도 괜찮음)
      List<HealthDataPoint> distance = [];
      try {
        distance = await health!.getHealthDataFromTypes(
          types: [_distanceWalkingRunning],
          startTime: startTime,
          endTime: endTime,
        );
      } catch (e) {
        // ignore: avoid_print
        print('거리 데이터 가져오기 실패 (선택사항): $e');
      }

      // 수면 데이터 (선택사항 - 실패해도 괜찮음)
      // ignore: avoid_print
      print('수면 데이터 조회 중...');
      List<HealthDataPoint> sleep = [];
      try {
        sleep = await health!.getHealthDataFromTypes(
          types: [_sleep],
          startTime: startTime,
          endTime: endTime,
        );
        // ignore: avoid_print
        print('수면 데이터 개수: ${sleep.length}');
        var totalSleepMinutes = 0.0;
        for (var slp in sleep) {
          final duration = slp.dateTo.difference(slp.dateFrom).inMinutes.toDouble();
          totalSleepMinutes += duration;
          // ignore: avoid_print
          print('  수면: ${duration.toInt()}분 (${slp.dateFrom} ~ ${slp.dateTo})');
        }
        // ignore: avoid_print
        print('총 수면 시간: ${totalSleepMinutes.toInt()}분');
      } catch (e) {
        // ignore: avoid_print
        print('수면 데이터 가져오기 실패 (선택사항): $e');
      }

      // 데이터를 시간대별로 그룹화
      final Map<DateTime, HealthData> healthDataMap = {};

      // 스텝 데이터 처리
      // ignore: avoid_print
      print('걸음 수 데이터를 시간대별로 그룹화 중...');
      final validSteps = <HealthDataPoint>[];
      
      for (var data in steps) {
        final dateFromLocal = data.dateFrom.toLocal();
        final dateToLocal = data.dateTo.toLocal();
        final duration = dateToLocal.difference(dateFromLocal);
        
        // 일일 총합 데이터 필터링:
        // 1. 00:00:00부터 시작하고
        // 2. 시간 간격이 12시간 이상이거나 하루 전체인 경우 제외
        final isStartOfDay = dateFromLocal.hour == 0 && 
                             dateFromLocal.minute == 0 && 
                             dateFromLocal.second == 0;
        final isLongDuration = duration.inHours >= 12;
        
        if (isStartOfDay && isLongDuration) {
          // ignore: avoid_print
          print('  ⚠️ 일일 총합 데이터 제외: ${data.value} 걸음 (${dateFromLocal} ~ ${dateToLocal}, ${duration.inHours}시간)');
          continue;
        }
        
        validSteps.add(data);
        // ignore: avoid_print
        print('  ✅ 유효한 데이터: ${data.value} 걸음 (${dateFromLocal} ~ ${dateToLocal}, ${duration.inMinutes}분)');
      }
      
      // ignore: avoid_print
      print('  유효한 걸음 수 데이터: ${validSteps.length}개 (전체 ${steps.length}개 중)');
      
      for (var data in validSteps) {
        final timestamp = data.dateFrom.isBefore(data.dateTo) ? data.dateFrom : data.dateTo;
        final hour = DateTime(timestamp.year, timestamp.month, timestamp.day, timestamp.hour);

        if (!healthDataMap.containsKey(hour)) {
          healthDataMap[hour] = HealthData(timestamp: hour);
        }

        final existing = healthDataMap[hour]!;
        final value = _getNumericValue(data.value);
        final timestampLocal = timestamp.toLocal();
        // ignore: avoid_print
        print('  ${timestampLocal.hour}시에 ${value.toInt()} 걸음 추가 (${timestampLocal})');
        healthDataMap[hour] = HealthData(
          timestamp: hour,
          steps: (existing.steps ?? 0) + value,
          heartRate: existing.heartRate,
          calories: existing.calories,
          distance: existing.distance,
          sleepMinutes: existing.sleepMinutes,
        );
      }
      // ignore: avoid_print
      print('걸음 수 그룹화 완료: ${healthDataMap.length}개 시간대');

      // 심박수 데이터 처리
      // ignore: avoid_print
      print('심박수 데이터를 시간대별로 그룹화 중...');
      for (var data in heartRate) {
        final timestamp = data.dateFrom.isBefore(data.dateTo) ? data.dateFrom : data.dateTo;
        final hour = DateTime(timestamp.year, timestamp.month, timestamp.day, timestamp.hour);

        if (!healthDataMap.containsKey(hour)) {
          healthDataMap[hour] = HealthData(timestamp: hour);
        }

        final existing = healthDataMap[hour]!;
        final value = _getNumericValue(data.value);
        // ignore: avoid_print
        print('  ${hour.hour}시에 ${value.toInt()} bpm 추가 (${timestamp})');
        final heartRateValues = [existing.heartRate, value]
            .where((v) => v != null)
            .cast<double>()
            .toList();

        healthDataMap[hour] = HealthData(
          timestamp: hour,
          steps: existing.steps,
          heartRate: heartRateValues.isEmpty
              ? null
              : heartRateValues.reduce((a, b) => a + b) / heartRateValues.length,
          calories: existing.calories,
          distance: existing.distance,
          sleepMinutes: existing.sleepMinutes,
        );
      }
      // ignore: avoid_print
      print('심박수 그룹화 완료: ${healthDataMap.length}개 시간대');

      // 칼로리 데이터 처리
      // ignore: avoid_print
      print('칼로리 데이터를 시간대별로 그룹화 중...');
      for (var data in calories) {
        final timestamp = data.dateFrom.isBefore(data.dateTo) ? data.dateFrom : data.dateTo;
        final hour = DateTime(timestamp.year, timestamp.month, timestamp.day, timestamp.hour);

        if (!healthDataMap.containsKey(hour)) {
          healthDataMap[hour] = HealthData(timestamp: hour);
        }

        final existing = healthDataMap[hour]!;
        final value = _getNumericValue(data.value);
        // ignore: avoid_print
        print('  ${hour.hour}시에 ${value.toInt()} kcal 추가 (${timestamp})');
        healthDataMap[hour] = HealthData(
          timestamp: hour,
          steps: existing.steps,
          heartRate: existing.heartRate,
          calories: (existing.calories ?? 0) + value,
          distance: existing.distance,
          sleepMinutes: existing.sleepMinutes,
        );
      }
      // ignore: avoid_print
      print('칼로리 그룹화 완료: ${healthDataMap.length}개 시간대');

      // 거리 데이터 처리
      for (var data in distance) {
        final timestamp = data.dateFrom.isBefore(data.dateTo) ? data.dateFrom : data.dateTo;
        final hour = DateTime(timestamp.year, timestamp.month, timestamp.day, timestamp.hour);

        if (!healthDataMap.containsKey(hour)) {
          healthDataMap[hour] = HealthData(timestamp: hour);
        }

        final existing = healthDataMap[hour]!;
        final value = _getNumericValue(data.value);
        healthDataMap[hour] = HealthData(
          timestamp: hour,
          steps: existing.steps,
          heartRate: existing.heartRate,
          calories: existing.calories,
          distance: (existing.distance ?? 0) + value,
          sleepMinutes: existing.sleepMinutes,
        );
      }

      // 수면 데이터 처리
      for (var data in sleep) {
        final timestamp = data.dateFrom.isBefore(data.dateTo) ? data.dateFrom : data.dateTo;
        final hour = DateTime(timestamp.year, timestamp.month, timestamp.day, timestamp.hour);

        if (!healthDataMap.containsKey(hour)) {
          healthDataMap[hour] = HealthData(timestamp: hour);
        }

        final existing = healthDataMap[hour]!;
        // 수면 데이터는 시작-종료 시간의 차이를 분 단위로 계산
        final sleepDuration = data.dateTo.difference(data.dateFrom).inMinutes.toDouble();
        healthDataMap[hour] = HealthData(
          timestamp: hour,
          steps: existing.steps,
          heartRate: existing.heartRate,
          calories: existing.calories,
          distance: existing.distance,
          sleepMinutes: (existing.sleepMinutes ?? 0) + sleepDuration,
        );
      }

      final result = healthDataMap.values.toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      // ignore: avoid_print
      print('=== 헬스 데이터 조회 완료 ===');
      print('총 ${result.length}개 시간대의 데이터');
      print('');
      if (result.isEmpty) {
        print('⚠️ 시간대별 데이터가 없습니다.');
        print('데이터가 있는 시간대만 표시됩니다.');
      } else {
        print('시간대별 상세 데이터:');
        for (var data in result) {
          final dateStr = '${data.timestamp.year}-${data.timestamp.month.toString().padLeft(2, '0')}-${data.timestamp.day.toString().padLeft(2, '0')}';
          final hourStr = '${data.timestamp.hour.toString().padLeft(2, '0')}시';
          print('  [$dateStr $hourStr]');
          if (data.steps != null && data.steps! > 0) {
            print('    걸음 수: ${data.steps!.toInt()} 걸음');
          }
          if (data.heartRate != null && data.heartRate! > 0) {
            print('    심박수: ${data.heartRate!.toInt()} bpm');
          }
          if (data.calories != null && data.calories! > 0) {
            print('    칼로리: ${data.calories!.toInt()} kcal');
          }
          if (data.distance != null && data.distance! > 0) {
            print('    거리: ${(data.distance! / 1000).toStringAsFixed(2)} km');
          }
          if (data.sleepMinutes != null && data.sleepMinutes! > 0) {
            print('    수면: ${data.sleepMinutes!.toInt()}분');
          }
          print('');
        }
      }
      
      return result;
    } catch (e) {
      // ignore: avoid_print
      print('Health 데이터 가져오기 오류: $e');
      rethrow;
    }
  }

  /// HealthValue에서 숫자 값 추출
  double _getNumericValue(HealthValue value) {
    if (value is NumericHealthValue) {
      return value.numericValue.toDouble();
    }
    // 다른 타입의 경우 0 반환
    return 0.0;
  }

  /// 시간대별 헬스 요약 가져오기
  Future<List<HealthSummary>> getHealthSummaryByTimeSlot(DateTime date) async {
    final healthData = await getHealthDataForDate(date);
    
    final List<HealthSummary> summaries = [];
    
    for (var data in healthData) {
      // 활발한지 판단 (스텝이 500 이상이거나 심박수가 100 이상)
      final isActive = (data.steps ?? 0) >= 500 || (data.heartRate ?? 0) >= 100;

      // 수면 중인지 판단 (수면 시간이 30분 이상)
      final isSleeping = (data.sleepMinutes ?? 0) >= 30;

      summaries.add(
        HealthSummary(
          timeSlot: data.timestamp,
          totalSteps: data.steps ?? 0,
          avgHeartRate: data.heartRate,
          totalCalories: data.calories ?? 0,
          totalDistance: data.distance ?? 0,
          isActive: isActive,
          totalSleepMinutes: data.sleepMinutes ?? 0,
          isSleeping: isSleeping,
        ),
      );
    }

    return summaries;
  }
}
