/// 스마트폰 스크린 사용 데이터
class ScreenData {
  final String packageName;
  final String appName;
  final Duration usageTime;
  final DateTime timestamp;

  ScreenData({
    required this.packageName,
    required this.appName,
    required this.usageTime,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'appName': appName,
        'usageTime': usageTime.inMilliseconds,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ScreenData.fromJson(Map<String, dynamic> json) => ScreenData(
        packageName: json['packageName'],
        appName: json['appName'],
        usageTime: Duration(milliseconds: json['usageTime']),
        timestamp: DateTime.parse(json['timestamp']),
      );
}

/// 시간대별 스크린 사용 요약
class ScreenUsageSummary {
  final DateTime timeSlot;
  final Duration totalUsage;
  final List<ScreenData> appUsages;
  final String? dominantApp;

  ScreenUsageSummary({
    required this.timeSlot,
    required this.totalUsage,
    required this.appUsages,
    this.dominantApp,
  });
}


