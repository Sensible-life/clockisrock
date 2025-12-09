import 'screen_data.dart';
import 'health_data.dart';
import 'calendar_data.dart';

/// 집중/휴식 상태
enum MentalState {
  focused, // 집중
  relaxed, // 휴식
  neutral, // 중립
}

/// 활발/비활발 상태
enum PhysicalState {
  active, // 활발
  inactive, // 비활발
  moderate, // 보통
}

/// 앱 카테고리
enum AppCategory {
  productivity, // 생산성 (문서, 업무)
  communication, // 커뮤니케이션 (메신저, 이메일)
  entertainment, // 엔터테인먼트 (동영상, 게임)
  social, // 소셜 미디어
  creative, // 창작 (디자인, 음악, 영상 편집)
  education, // 교육, 학습
  health, // 건강, 운동
  utilities, // 유틸리티
  unknown, // 알 수 없음
}

/// 시간대 분류
enum TimeOfDay {
  earlyMorning, // 새벽 (0-6시)
  morning, // 아침 (6-12시)
  afternoon, // 오후 (12-18시)
  evening, // 저녁 (18-22시)
  night, // 밤 (22-24시)
}

/// 캘린더 이벤트 컨텍스트
enum EventContext {
  meeting, // 회의
  workout, // 운동
  meal, // 식사
  commute, // 이동
  focus, // 집중 작업
  personal, // 개인 일정
  none, // 없음
}

/// 시간대별 분석 결과
class TimeSlotAnalysis {
  final DateTime timeSlot;
  final MentalState mentalState;
  final PhysicalState physicalState;
  final double focusScore; // 0.0 ~ 1.0
  final double activityScore; // 0.0 ~ 1.0
  final ScreenUsageSummary? screenUsage;
  final HealthSummary? healthSummary;
  final CalendarSummary? calendarSummary;
  final String? reasoning; // 분석 근거

  // === Derived Features ===
  final AppCategory appCategory; // 주요 앱 카테고리
  final TimeOfDay timeOfDay; // 시간대 분류
  final EventContext eventContext; // 캘린더 이벤트 컨텍스트
  final double deltaSteps; // 이전 시간 대비 걸음 수 변화량
  final double deltaHeartRate; // 이전 시간 대비 심박 변화량
  final double deltaScreenUsage; // 이전 시간 대비 스크린 사용 변화량 (분)
  final double circadianMultiplier; // 생체리듬 가중치 (0.7 ~ 1.2)
  final Duration sessionDuration; // 주요 앱 세션 지속 시간
  final double energyLevel; // 추정 에너지 레벨 (0.0 ~ 1.0)
  final double cognitiveLoad; // 인지 부하 (0.0 ~ 1.0)

  TimeSlotAnalysis({
    required this.timeSlot,
    required this.mentalState,
    required this.physicalState,
    required this.focusScore,
    required this.activityScore,
    this.screenUsage,
    this.healthSummary,
    this.calendarSummary,
    this.reasoning,
    required this.appCategory,
    required this.timeOfDay,
    required this.eventContext,
    this.deltaSteps = 0.0,
    this.deltaHeartRate = 0.0,
    this.deltaScreenUsage = 0.0,
    this.circadianMultiplier = 1.0,
    this.sessionDuration = Duration.zero,
    this.energyLevel = 0.5,
    this.cognitiveLoad = 0.5,
  });

  Map<String, dynamic> toJson() => {
        'timeSlot': timeSlot.toIso8601String(),
        'mentalState': mentalState.name,
        'physicalState': physicalState.name,
        'focusScore': focusScore,
        'activityScore': activityScore,
        'screenUsage': screenUsage?.toJson(),
        'healthSummary': healthSummary?.toJson(),
        'calendarSummary': calendarSummary?.toJson(),
        'reasoning': reasoning,
        'appCategory': appCategory.name,
        'timeOfDay': timeOfDay.name,
        'eventContext': eventContext.name,
        'deltaSteps': deltaSteps,
        'deltaHeartRate': deltaHeartRate,
        'deltaScreenUsage': deltaScreenUsage,
        'circadianMultiplier': circadianMultiplier,
        'sessionDuration': sessionDuration.inMilliseconds,
        'energyLevel': energyLevel,
        'cognitiveLoad': cognitiveLoad,
      };
}

/// 하루 전체 분석 결과
class DailyAnalysis {
  final DateTime date;
  final List<TimeSlotAnalysis> timeSlots;
  final List<MusicRecommendation> recommendations;

  DailyAnalysis({
    required this.date,
    required this.timeSlots,
    required this.recommendations,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'timeSlots': timeSlots.map((ts) => ts.toJson()).toList(),
        'recommendations': recommendations.map((r) => r.toJson()).toList(),
      };
}

/// 음악 추천
class MusicRecommendation {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final String genre;
  final String? spotifyId;
  final String? youtubeId;
  final String? appleMusicId;
  final String reasoning; // 추천 이유
  final TimeSlotAnalysis? recommendedFor; // 추천된 시간대

  MusicRecommendation({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    required this.genre,
    this.spotifyId,
    this.youtubeId,
    this.appleMusicId,
    required this.reasoning,
    this.recommendedFor,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'album': album,
        'genre': genre,
        'spotifyId': spotifyId,
        'youtubeId': youtubeId,
        'appleMusicId': appleMusicId,
        'reasoning': reasoning,
      };
}

extension ScreenUsageSummaryJson on ScreenUsageSummary {
  Map<String, dynamic> toJson() => {
        'timeSlot': timeSlot.toIso8601String(),
        'totalUsage': totalUsage.inMilliseconds,
        'appUsages': appUsages.map((a) => a.toJson()).toList(),
        'dominantApp': dominantApp,
      };
}

extension HealthSummaryJson on HealthSummary {
  Map<String, dynamic> toJson() => {
        'timeSlot': timeSlot.toIso8601String(),
        'totalSteps': totalSteps,
        'avgHeartRate': avgHeartRate,
        'totalCalories': totalCalories,
        'totalDistance': totalDistance,
        'isActive': isActive,
      };
}

extension CalendarSummaryJson on CalendarSummary {
  Map<String, dynamic> toJson() => {
        'timeSlot': timeSlot.toIso8601String(),
        'events': events.map((e) => e.toJson()).toList(),
        'hasEvent': hasEvent,
        'primaryEventType': primaryEventType,
      };
}


