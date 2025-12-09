/// 헬스 데이터 (삼성 헬스 / Health Connect)
class HealthData {
  final DateTime timestamp;
  final double? steps;
  final double? heartRate;
  final double? calories;
  final double? distance; // 미터 단위
  final String? activityType;
  final double? sleepMinutes; // 수면 시간 (분)

  HealthData({
    required this.timestamp,
    this.steps,
    this.heartRate,
    this.calories,
    this.distance,
    this.activityType,
    this.sleepMinutes,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'steps': steps,
        'heartRate': heartRate,
        'calories': calories,
        'distance': distance,
        'activityType': activityType,
        'sleepMinutes': sleepMinutes,
      };

  factory HealthData.fromJson(Map<String, dynamic> json) => HealthData(
        timestamp: DateTime.parse(json['timestamp']),
        steps: json['steps']?.toDouble(),
        heartRate: json['heartRate']?.toDouble(),
        calories: json['calories']?.toDouble(),
        distance: json['distance']?.toDouble(),
        activityType: json['activityType'],
        sleepMinutes: json['sleepMinutes']?.toDouble(),
      );
}

/// 시간대별 헬스 요약
class HealthSummary {
  final DateTime timeSlot;
  final double totalSteps;
  final double? avgHeartRate;
  final double totalCalories;
  final double totalDistance;
  final bool isActive; // 활발한지 여부
  final double totalSleepMinutes; // 수면 시간 (분)
  final bool isSleeping; // 수면 중인지 여부

  HealthSummary({
    required this.timeSlot,
    required this.totalSteps,
    this.avgHeartRate,
    required this.totalCalories,
    required this.totalDistance,
    required this.isActive,
    this.totalSleepMinutes = 0,
    this.isSleeping = false,
  });
}


