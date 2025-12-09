import '../models/analysis_result.dart';
import '../models/screen_data.dart';
import '../models/health_data.dart';
import '../models/calendar_data.dart';
import 'screen_data_service.dart';
import 'health_data_service.dart';
import 'calendar_service.dart';
import 'music_recommendation_service.dart';

/// 데이터 분석 서비스
class DataAnalyzer {
  final ScreenDataService _screenDataService;
  final HealthDataService _healthDataService;
  final CalendarService _calendarService;
  final MusicRecommendationService? _musicService;

  DataAnalyzer({
    required ScreenDataService screenDataService,
    required HealthDataService healthDataService,
    required CalendarService calendarService,
    MusicRecommendationService? musicService,
  })  : _screenDataService = screenDataService,
        _healthDataService = healthDataService,
        _calendarService = calendarService,
        _musicService = musicService;

  /// 특정 날짜의 전체 분석 수행
  Future<DailyAnalysis> analyzeDate(DateTime date) async {
    // 모든 데이터 수집
    final screenSummaries = await _screenDataService.getScreenUsageByTimeSlot(date);
    final healthSummaries = await _healthDataService.getHealthSummaryByTimeSlot(date);
    final calendarSummaries = await _calendarService.getCalendarSummaryByTimeSlot(date);

    // 시간대별 분석 수행 (이전 시간대 정보 활용)
    final List<TimeSlotAnalysis> timeSlotAnalyses = [];

    // 24시간 모두 분석
    for (int hour = 0; hour < 24; hour++) {
      final timeSlot = DateTime(date.year, date.month, date.day, hour);

      final screenSummary = screenSummaries.firstWhere(
        (s) => s.timeSlot.hour == hour,
        orElse: () => ScreenUsageSummary(
          timeSlot: timeSlot,
          totalUsage: Duration.zero,
          appUsages: [],
        ),
      );

      final healthSummary = healthSummaries.firstWhere(
        (h) => h.timeSlot.hour == hour,
        orElse: () => HealthSummary(
          timeSlot: timeSlot,
          totalSteps: 0,
          totalCalories: 0,
          totalDistance: 0,
          isActive: false,
        ),
      );

      final calendarSummary = calendarSummaries.firstWhere(
        (c) => c.timeSlot.hour == hour,
        orElse: () => CalendarSummary(
          timeSlot: timeSlot,
          events: [],
          hasEvent: false,
        ),
      );

      // 이전 시간대 분석 결과를 전달 (첫 시간은 null)
      final previousSlot = timeSlotAnalyses.isNotEmpty
          ? timeSlotAnalyses.last
          : null;

      final analysis = _analyzeTimeSlot(
        timeSlot: timeSlot,
        screenSummary: screenSummary,
        healthSummary: healthSummary,
        calendarSummary: calendarSummary,
        previousSlot: previousSlot,
      );

      timeSlotAnalyses.add(analysis);
    }

    // 음악 추천 생성 (향상됨)
    final recommendations = await _generateMusicRecommendationsAdvanced(timeSlotAnalyses);

    return DailyAnalysis(
      date: date,
      timeSlots: timeSlotAnalyses,
      recommendations: recommendations,
    );
  }

  /// 시간대별 분석 수행 (개선된 버전)
  TimeSlotAnalysis _analyzeTimeSlot({
    required DateTime timeSlot,
    required ScreenUsageSummary screenSummary,
    required HealthSummary healthSummary,
    required CalendarSummary calendarSummary,
    TimeSlotAnalysis? previousSlot, // 이전 시간대 분석 결과
  }) {
    // === Feature Engineering ===

    // 1. Baseline features (기본 특징)
    final appCategory = _classifyApp(screenSummary.dominantApp);
    final timeOfDay = _getTimeOfDay(timeSlot.hour);
    final eventContext = _getEventContext(calendarSummary);

    // 2. Derived features (파생 특징)
    final deltaSteps = previousSlot != null
        ? healthSummary.totalSteps - (previousSlot.healthSummary?.totalSteps ?? 0)
        : 0.0;

    final deltaHeartRate = previousSlot != null &&
                          healthSummary.avgHeartRate != null &&
                          previousSlot.healthSummary?.avgHeartRate != null
        ? healthSummary.avgHeartRate! - previousSlot.healthSummary!.avgHeartRate!
        : 0.0;

    final deltaScreenUsage = previousSlot != null
        ? (screenSummary.totalUsage.inMinutes - (previousSlot.screenUsage?.totalUsage.inMinutes ?? 0)).toDouble()
        : 0.0;

    // 3. Circadian rhythm multiplier (생체리듬 가중치)
    final circadianMultiplier = _getCircadianMultiplier(timeSlot.hour);

    // 4. Session duration (세션 지속 시간)
    final sessionDuration = _getSessionDuration(screenSummary);

    // === State Analysis with Context ===

    // 5. 집중/휴식 상태 분석 (향상됨)
    final mentalState = _analyzeMentalStateAdvanced(
      screenSummary: screenSummary,
      calendarSummary: calendarSummary,
      appCategory: appCategory,
      eventContext: eventContext,
      timeOfDay: timeOfDay,
      circadianMultiplier: circadianMultiplier,
    );

    // 6. 활발/비활발 상태 분석 (향상됨)
    final physicalState = _analyzePhysicalStateAdvanced(
      healthSummary: healthSummary,
      deltaSteps: deltaSteps,
      deltaHeartRate: deltaHeartRate,
      eventContext: eventContext,
    );

    // 7. 에너지 레벨 추정
    final energyLevel = _estimateEnergyLevel(
      healthSummary: healthSummary,
      physicalState: physicalState,
      timeOfDay: timeOfDay,
      circadianMultiplier: circadianMultiplier,
    );

    // 8. 인지 부하 추정
    final cognitiveLoad = _estimateCognitiveLoad(
      screenSummary: screenSummary,
      calendarSummary: calendarSummary,
      appCategory: appCategory,
      sessionDuration: sessionDuration,
      mentalState: mentalState,
    );

    // 9. 집중도 점수 계산 (향상됨)
    final focusScore = _calculateFocusScoreAdvanced(
      screenSummary: screenSummary,
      calendarSummary: calendarSummary,
      mentalState: mentalState,
      appCategory: appCategory,
      cognitiveLoad: cognitiveLoad,
      circadianMultiplier: circadianMultiplier,
    );

    // 10. 활동 점수 계산 (향상됨)
    final activityScore = _calculateActivityScoreAdvanced(
      healthSummary: healthSummary,
      physicalState: physicalState,
      deltaSteps: deltaSteps,
      energyLevel: energyLevel,
    );

    // 11. 분석 근거 생성 (향상됨)
    final reasoning = _generateReasoningAdvanced(
      mentalState: mentalState,
      physicalState: physicalState,
      screenSummary: screenSummary,
      healthSummary: healthSummary,
      calendarSummary: calendarSummary,
      appCategory: appCategory,
      eventContext: eventContext,
      deltaSteps: deltaSteps,
      energyLevel: energyLevel,
      cognitiveLoad: cognitiveLoad,
    );

    return TimeSlotAnalysis(
      timeSlot: timeSlot,
      mentalState: mentalState,
      physicalState: physicalState,
      focusScore: focusScore,
      activityScore: activityScore,
      screenUsage: screenSummary,
      healthSummary: healthSummary,
      calendarSummary: calendarSummary,
      reasoning: reasoning,
      appCategory: appCategory,
      timeOfDay: timeOfDay,
      eventContext: eventContext,
      deltaSteps: deltaSteps,
      deltaHeartRate: deltaHeartRate,
      deltaScreenUsage: deltaScreenUsage,
      circadianMultiplier: circadianMultiplier,
      sessionDuration: sessionDuration,
      energyLevel: energyLevel,
      cognitiveLoad: cognitiveLoad,
    );
  }

  /// 집중/휴식 상태 분석
  MentalState _analyzeMentalState({
    required ScreenUsageSummary screenSummary,
    required CalendarSummary calendarSummary,
  }) {
    // 캘린더 이벤트가 있으면 집중 상태로 간주
    if (calendarSummary.hasEvent) {
      final isFocusEvent = _calendarService.isFocusEventType(
        calendarSummary.primaryEventType,
      );
      if (isFocusEvent) {
        return MentalState.focused;
      }
    }

    // 스크린 사용 시간이 많으면 집중 상태
    final totalUsageMinutes = screenSummary.totalUsage.inMinutes;
    if (totalUsageMinutes > 45) {
      // 생산성 앱인지 확인 (간단한 휴리스틱)
      final isProductiveApp = _isProductiveApp(screenSummary.dominantApp);
      if (isProductiveApp) {
        return MentalState.focused;
      } else {
        // 엔터테인먼트 앱이면 휴식
        return MentalState.relaxed;
      }
    } else if (totalUsageMinutes < 15) {
      // 사용 시간이 적으면 휴식 상태
      return MentalState.relaxed;
    }

    return MentalState.neutral;
  }

  /// 활발/비활발 상태 분석
  PhysicalState _analyzePhysicalState({
    required HealthSummary healthSummary,
  }) {
    if (healthSummary.isActive) {
      // 스텝이 많거나 심박수가 높으면 활발
      if (healthSummary.totalSteps > 1000 || 
          (healthSummary.avgHeartRate ?? 0) > 120) {
        return PhysicalState.active;
      } else {
        return PhysicalState.moderate;
      }
    } else {
      // 스텝이 매우 적으면 비활발
      if (healthSummary.totalSteps < 100) {
        return PhysicalState.inactive;
      } else {
        return PhysicalState.moderate;
      }
    }
  }

  /// 집중도 점수 계산
  double _calculateFocusScore({
    required ScreenUsageSummary screenSummary,
    required CalendarSummary calendarSummary,
    required MentalState mentalState,
  }) {
    double score = 0.5; // 기본값

    // 캘린더 이벤트가 있으면 점수 증가
    if (calendarSummary.hasEvent) {
      if (_calendarService.isFocusEventType(calendarSummary.primaryEventType)) {
        score += 0.3;
      } else {
        score -= 0.2; // 개인 일정이면 집중도 감소
      }
    }

    // 스크린 사용 패턴 분석
    final usageMinutes = screenSummary.totalUsage.inMinutes;
    if (usageMinutes > 30) {
      final isProductive = _isProductiveApp(screenSummary.dominantApp);
      if (isProductive) {
        score += 0.2;
      } else {
        score -= 0.1; // 비생산적 앱 사용
      }
    } else if (usageMinutes < 10) {
      score -= 0.1; // 사용량이 적으면 집중도 낮음
    }

    // Mental State 반영
    switch (mentalState) {
      case MentalState.focused:
        score += 0.2;
        break;
      case MentalState.relaxed:
        score -= 0.2;
        break;
      case MentalState.neutral:
        break;
    }

    return score.clamp(0.0, 1.0);
  }

  /// 활동 점수 계산
  double _calculateActivityScore({
    required HealthSummary healthSummary,
    required PhysicalState physicalState,
  }) {
    double score = 0.5; // 기본값

    // 스텝 수 기반 점수
    final stepsScore = (healthSummary.totalSteps / 2000).clamp(0.0, 1.0);
    score = (score + stepsScore) / 2;

    // 심박수 기반 점수
    if (healthSummary.avgHeartRate != null) {
      final heartRateScore = ((healthSummary.avgHeartRate! - 60) / 60).clamp(0.0, 1.0);
      score = (score + heartRateScore) / 2;
    }

    // Physical State 반영
    switch (physicalState) {
      case PhysicalState.active:
        score += 0.2;
        break;
      case PhysicalState.inactive:
        score -= 0.2;
        break;
      case PhysicalState.moderate:
        break;
    }

    return score.clamp(0.0, 1.0);
  }

  /// 생산성 앱인지 확인 (간단한 휴리스틱) - 하위호환성 유지
  bool _isProductiveApp(String? packageName) {
    return _classifyApp(packageName) == AppCategory.productivity;
  }

  /// 앱 카테고리 분류 (향상된 semantic classification)
  AppCategory _classifyApp(String? packageName) {
    if (packageName == null) return AppCategory.unknown;

    final lowerPackage = packageName.toLowerCase();

    // 생산성 앱
    final productivityKeywords = [
      'office', 'docs', 'sheets', 'word', 'excel', 'powerpoint',
      'notion', 'evernote', 'onenote', 'notes', 'todoist', 'trello',
      'asana', 'jira', 'confluence', 'monday', 'airtable',
    ];
    if (productivityKeywords.any((kw) => lowerPackage.contains(kw))) {
      return AppCategory.productivity;
    }

    // 커뮤니케이션 앱
    final communicationKeywords = [
      'slack', 'teams', 'zoom', 'meet', 'webex', 'skype',
      'email', 'gmail', 'outlook', 'mail', 'messenger',
      'telegram', 'whatsapp', 'signal', 'discord',
    ];
    if (communicationKeywords.any((kw) => lowerPackage.contains(kw))) {
      return AppCategory.communication;
    }

    // 엔터테인먼트 앱
    final entertainmentKeywords = [
      'youtube', 'netflix', 'twitch', 'spotify', 'tiktok',
      'game', 'play', 'steam', 'epic', 'video', 'movie',
      'tv', 'hulu', 'disney', 'prime', 'music',
    ];
    if (entertainmentKeywords.any((kw) => lowerPackage.contains(kw))) {
      return AppCategory.entertainment;
    }

    // 소셜 미디어 앱
    final socialKeywords = [
      'facebook', 'instagram', 'twitter', 'reddit', 'linkedin',
      'social', 'kakao', 'line', 'wechat', 'snapchat',
    ];
    if (socialKeywords.any((kw) => lowerPackage.contains(kw))) {
      return AppCategory.social;
    }

    // 창작 앱
    final creativeKeywords = [
      'photoshop', 'illustrator', 'figma', 'sketch', 'canva',
      'design', 'photo', 'lightroom', 'premiere', 'finalcut',
      'davinci', 'blender', 'unity', 'unreal', 'procreate',
      'garage', 'logic', 'ableton', 'fl studio',
    ];
    if (creativeKeywords.any((kw) => lowerPackage.contains(kw))) {
      return AppCategory.creative;
    }

    // 교육 앱
    final educationKeywords = [
      'duolingo', 'coursera', 'udemy', 'khan', 'learning',
      'education', 'study', 'school', 'university', 'course',
      'tutorial', 'lesson', 'book', 'reader', 'kindle',
    ];
    if (educationKeywords.any((kw) => lowerPackage.contains(kw))) {
      return AppCategory.education;
    }

    // 건강 앱
    final healthKeywords = [
      'health', 'fitness', 'workout', 'exercise', 'yoga',
      'strava', 'nike', 'peloton', 'myfitnesspal', 'fitbit',
      'samsung health', 'apple health', 'google fit',
    ];
    if (healthKeywords.any((kw) => lowerPackage.contains(kw))) {
      return AppCategory.health;
    }

    // 유틸리티 앱
    final utilityKeywords = [
      'settings', 'calculator', 'clock', 'alarm', 'calendar',
      'weather', 'maps', 'navigation', 'browser', 'chrome',
      'safari', 'firefox', 'file', 'storage', 'drive',
    ];
    if (utilityKeywords.any((kw) => lowerPackage.contains(kw))) {
      return AppCategory.utilities;
    }

    return AppCategory.unknown;
  }

  /// 분석 근거 생성
  String _generateReasoning({
    required MentalState mentalState,
    required PhysicalState physicalState,
    required ScreenUsageSummary screenSummary,
    required HealthSummary healthSummary,
    required CalendarSummary calendarSummary,
  }) {
    final reasons = <String>[];

    // 집중 상태 근거
    if (mentalState == MentalState.focused) {
      if (calendarSummary.hasEvent) {
        reasons.add('${calendarSummary.primaryEventType} 일정이 있어 집중 상태입니다');
      } else if (screenSummary.totalUsage.inMinutes > 30) {
        reasons.add('${screenSummary.dominantApp ?? "앱"}을 ${screenSummary.totalUsage.inMinutes}분 사용했습니다');
      }
    } else if (mentalState == MentalState.relaxed) {
      reasons.add('스크린 사용량이 적어 휴식 상태입니다');
    }

    // 활동 상태 근거
    if (physicalState == PhysicalState.active) {
      reasons.add('${healthSummary.totalSteps.toInt()}걸음, 심박수 ${healthSummary.avgHeartRate?.toInt() ?? 0}bpm로 활발합니다');
    } else if (physicalState == PhysicalState.inactive) {
      reasons.add('활동량이 적어 비활발 상태입니다');
    }

    return reasons.isEmpty ? '데이터 부족' : reasons.join(', ');
  }

  /// 음악 추천 생성 (향상된 버전)
  Future<List<MusicRecommendation>> _generateMusicRecommendationsAdvanced(
    List<TimeSlotAnalysis> timeSlots,
  ) async {
    // MusicRecommendationService를 사용하여 추천 생성
    if (_musicService != null) {
      try {
        return await _musicService!.generateRecommendations(timeSlots);
      } catch (e) {
        print('Error generating music recommendations: $e');
        // 에러 시 폴백 사용
        return _generateMusicRecommendations(timeSlots);
      }
    } else {
      // 서비스가 없으면 기존 방식 사용
      return _generateMusicRecommendations(timeSlots);
    }
  }

  /// 음악 추천 생성 (폴백 버전)
  List<MusicRecommendation> _generateMusicRecommendations(
    List<TimeSlotAnalysis> timeSlots,
  ) {
    // 각 시간대별로 음악 추천 생성
    final recommendations = <MusicRecommendation>[];

    for (var slot in timeSlots) {
      // 집중 시간대
      if (slot.mentalState == MentalState.focused &&
          slot.physicalState == PhysicalState.inactive) {
        recommendations.add(
          MusicRecommendation(
            id: 'focus-${slot.timeSlot.hour}',
            title: 'Focus Flow',
            artist: 'Lo-Fi Study',
            genre: 'Lo-Fi Hip Hop',
            reasoning: '집중이 필요한 시간대입니다. 집중력을 높이는 Lo-Fi 음악을 추천합니다.',
            recommendedFor: slot,
          ),
        );
      }
      // 활발한 시간대
      else if (slot.physicalState == PhysicalState.active) {
        recommendations.add(
          MusicRecommendation(
            id: 'active-${slot.timeSlot.hour}',
            title: 'Energy Boost',
            artist: 'Upbeat Mix',
            genre: 'Electronic',
            reasoning: '활발한 활동 시간대입니다. 에너지를 높이는 업템포 음악을 추천합니다.',
            recommendedFor: slot,
          ),
        );
      }
      // 휴식 시간대
      else if (slot.mentalState == MentalState.relaxed &&
               slot.physicalState == PhysicalState.inactive) {
        recommendations.add(
          MusicRecommendation(
            id: 'relax-${slot.timeSlot.hour}',
            title: 'Peaceful Moments',
            artist: 'Ambient Sounds',
            genre: 'Ambient',
            reasoning: '휴식 시간대입니다. 마음을 진정시키는 앰비언트 음악을 추천합니다.',
            recommendedFor: slot,
          ),
        );
      }
    }

    return recommendations;
  }

  // ============================================================================
  // === 새로운 Helper 메소드들 (향상된 분석) ===
  // ============================================================================

  /// 시간대 분류
  TimeOfDay _getTimeOfDay(int hour) {
    if (hour >= 0 && hour < 6) {
      return TimeOfDay.earlyMorning;
    } else if (hour >= 6 && hour < 12) {
      return TimeOfDay.morning;
    } else if (hour >= 12 && hour < 18) {
      return TimeOfDay.afternoon;
    } else if (hour >= 18 && hour < 22) {
      return TimeOfDay.evening;
    } else {
      return TimeOfDay.night;
    }
  }

  /// 캘린더 이벤트 컨텍스트 분류
  EventContext _getEventContext(CalendarSummary calendarSummary) {
    if (!calendarSummary.hasEvent) {
      return EventContext.none;
    }

    final eventType = calendarSummary.primaryEventType?.toLowerCase() ?? '';

    if (eventType.contains('meeting') || eventType.contains('회의')) {
      return EventContext.meeting;
    } else if (eventType.contains('workout') || eventType.contains('운동') || eventType.contains('gym')) {
      return EventContext.workout;
    } else if (eventType.contains('meal') || eventType.contains('식사') || eventType.contains('lunch') || eventType.contains('dinner')) {
      return EventContext.meal;
    } else if (eventType.contains('commute') || eventType.contains('이동') || eventType.contains('travel')) {
      return EventContext.commute;
    } else if (eventType.contains('focus') || eventType.contains('work') || eventType.contains('집중') || eventType.contains('작업')) {
      return EventContext.focus;
    } else {
      return EventContext.personal;
    }
  }

  /// 생체리듬 기반 가중치 (circadian rhythm multiplier)
  double _getCircadianMultiplier(int hour) {
    // 인간의 자연적인 생체리듬에 기반한 가중치
    if (hour >= 9 && hour <= 12) {
      return 1.2; // 오전: 집중력 peak
    } else if (hour >= 18 && hour <= 21) {
      return 1.2; // 저녁: 활동 peak
    } else if (hour >= 14 && hour <= 16) {
      return 0.85; // 오후: 에너지 저하 (점심 후)
    } else if (hour >= 23 || hour <= 6) {
      return 0.7; // 밤/새벽: 피로
    } else {
      return 1.0; // 기본
    }
  }

  /// 세션 지속 시간 계산
  Duration _getSessionDuration(ScreenUsageSummary screenSummary) {
    // 주요 앱의 사용 시간을 세션으로 간주
    if (screenSummary.appUsages.isEmpty) {
      return Duration.zero;
    }

    // 가장 많이 사용한 앱의 시간을 세션 지속 시간으로
    final longestUsage = screenSummary.appUsages
        .map((app) => app.usageTime)
        .reduce((a, b) => a > b ? a : b);

    return longestUsage;
  }

  /// 향상된 집중/휴식 상태 분석
  MentalState _analyzeMentalStateAdvanced({
    required ScreenUsageSummary screenSummary,
    required CalendarSummary calendarSummary,
    required AppCategory appCategory,
    required EventContext eventContext,
    required TimeOfDay timeOfDay,
    required double circadianMultiplier,
  }) {
    double focusIndicator = 0.0;

    // 1. 이벤트 컨텍스트에 따른 판단
    if (eventContext == EventContext.focus || eventContext == EventContext.meeting) {
      focusIndicator += 0.4;
    } else if (eventContext == EventContext.meal || eventContext == EventContext.commute) {
      focusIndicator -= 0.3;
    }

    // 2. 앱 카테고리에 따른 판단
    switch (appCategory) {
      case AppCategory.productivity:
      case AppCategory.education:
        focusIndicator += 0.3;
        break;
      case AppCategory.entertainment:
      case AppCategory.social:
        focusIndicator -= 0.3;
        break;
      case AppCategory.creative:
        focusIndicator += 0.2; // 창작도 집중이 필요하지만 다른 종류
        break;
      default:
        break;
    }

    // 3. 스크린 사용 시간 고려
    final usageMinutes = screenSummary.totalUsage.inMinutes;
    if (usageMinutes > 40) {
      focusIndicator += 0.2;
    } else if (usageMinutes < 10) {
      focusIndicator -= 0.2;
    }

    // 4. 생체리듬 고려 (밤늦게 스크린 사용은 집중이 아닐 수 있음)
    if (timeOfDay == TimeOfDay.night || timeOfDay == TimeOfDay.earlyMorning) {
      focusIndicator *= 0.7; // 밤/새벽은 집중도 낮게 평가
    }

    // 5. 최종 판단
    if (focusIndicator > 0.3) {
      return MentalState.focused;
    } else if (focusIndicator < -0.2) {
      return MentalState.relaxed;
    } else {
      return MentalState.neutral;
    }
  }

  /// 향상된 활발/비활발 상태 분석
  PhysicalState _analyzePhysicalStateAdvanced({
    required HealthSummary healthSummary,
    required double deltaSteps,
    required double deltaHeartRate,
    required EventContext eventContext,
  }) {
    double activityIndicator = 0.0;

    // 1. 이벤트 컨텍스트
    if (eventContext == EventContext.workout) {
      return PhysicalState.active; // 운동 중이면 무조건 active
    } else if (eventContext == EventContext.commute) {
      activityIndicator += 0.3; // 이동 중이면 활동적
    }

    // 2. 절대 스텝 수
    final steps = healthSummary.totalSteps;
    if (steps > 1500) {
      activityIndicator += 0.4;
    } else if (steps < 100) {
      activityIndicator -= 0.4;
    }

    // 3. 스텝 변화량 (중요!)
    if (deltaSteps > 500) {
      activityIndicator += 0.3; // 갑자기 활동 증가
    } else if (deltaSteps < -200) {
      activityIndicator -= 0.2; // 활동 감소
    }

    // 4. 심박수
    final heartRate = healthSummary.avgHeartRate ?? 70;
    if (heartRate > 100) {
      activityIndicator += 0.3;
    } else if (heartRate < 65) {
      activityIndicator -= 0.2;
    }

    // 5. 심박 변화량
    if (deltaHeartRate > 15) {
      activityIndicator += 0.2; // 심박 증가
    } else if (deltaHeartRate < -10) {
      activityIndicator -= 0.2; // 안정화
    }

    // 최종 판단
    if (activityIndicator > 0.4) {
      return PhysicalState.active;
    } else if (activityIndicator < -0.3) {
      return PhysicalState.inactive;
    } else {
      return PhysicalState.moderate;
    }
  }

  /// 에너지 레벨 추정
  double _estimateEnergyLevel({
    required HealthSummary healthSummary,
    required PhysicalState physicalState,
    required TimeOfDay timeOfDay,
    required double circadianMultiplier,
  }) {
    double energy = 0.5; // 기본값

    // 1. 생체리듬 기반 에너지
    energy = circadianMultiplier;

    // 2. 활동 상태 기반
    switch (physicalState) {
      case PhysicalState.active:
        energy += 0.2;
        break;
      case PhysicalState.inactive:
        energy -= 0.2;
        break;
      default:
        break;
    }

    // 3. 심박수 고려
    final heartRate = healthSummary.avgHeartRate ?? 70;
    if (heartRate > 90) {
      energy += 0.1;
    } else if (heartRate < 60) {
      energy -= 0.1;
    }

    return energy.clamp(0.0, 1.0);
  }

  /// 인지 부하 추정
  double _estimateCognitiveLoad({
    required ScreenUsageSummary screenSummary,
    required CalendarSummary calendarSummary,
    required AppCategory appCategory,
    required Duration sessionDuration,
    required MentalState mentalState,
  }) {
    double load = 0.5; // 기본값

    // 1. 앱 카테고리 기반
    switch (appCategory) {
      case AppCategory.productivity:
      case AppCategory.education:
        load += 0.3;
        break;
      case AppCategory.communication:
        load += 0.2;
        break;
      case AppCategory.creative:
        load += 0.25;
        break;
      case AppCategory.entertainment:
        load -= 0.2;
        break;
      default:
        break;
    }

    // 2. 세션 지속 시간 (긴 집중은 부하 증가)
    if (sessionDuration.inMinutes > 45) {
      load += 0.2;
    }

    // 3. 이벤트 여부
    if (calendarSummary.hasEvent) {
      load += 0.15;
    }

    // 4. Mental state 반영
    if (mentalState == MentalState.focused) {
      load += 0.15;
    }

    return load.clamp(0.0, 1.0);
  }

  /// 향상된 집중도 점수 계산
  double _calculateFocusScoreAdvanced({
    required ScreenUsageSummary screenSummary,
    required CalendarSummary calendarSummary,
    required MentalState mentalState,
    required AppCategory appCategory,
    required double cognitiveLoad,
    required double circadianMultiplier,
  }) {
    double score = 0.5;

    // 1. Mental state 기반
    switch (mentalState) {
      case MentalState.focused:
        score += 0.3;
        break;
      case MentalState.relaxed:
        score -= 0.3;
        break;
      default:
        break;
    }

    // 2. 인지 부하 (높을수록 집중 중)
    score += (cognitiveLoad - 0.5) * 0.4;

    // 3. 생체리듬 가중치 적용
    score *= circadianMultiplier;

    // 4. 앱 카테고리
    if (appCategory == AppCategory.productivity || appCategory == AppCategory.education) {
      score += 0.15;
    } else if (appCategory == AppCategory.entertainment) {
      score -= 0.1;
    }

    return score.clamp(0.0, 1.0);
  }

  /// 향상된 활동 점수 계산
  double _calculateActivityScoreAdvanced({
    required HealthSummary healthSummary,
    required PhysicalState physicalState,
    required double deltaSteps,
    required double energyLevel,
  }) {
    double score = 0.5;

    // 1. Physical state 기반
    switch (physicalState) {
      case PhysicalState.active:
        score += 0.3;
        break;
      case PhysicalState.inactive:
        score -= 0.3;
        break;
      default:
        break;
    }

    // 2. 스텝 수 기반 (정규화)
    final stepsScore = (healthSummary.totalSteps / 2000).clamp(0.0, 1.0);
    score = (score + stepsScore) / 2;

    // 3. 변화량 반영 (중요!)
    if (deltaSteps > 500) {
      score += 0.15; // 갑자기 활동 증가
    } else if (deltaSteps < -200) {
      score -= 0.1; // 활동 감소
    }

    // 4. 에너지 레벨 반영
    score = (score + energyLevel) / 2;

    return score.clamp(0.0, 1.0);
  }

  /// 향상된 분석 근거 생성
  String _generateReasoningAdvanced({
    required MentalState mentalState,
    required PhysicalState physicalState,
    required ScreenUsageSummary screenSummary,
    required HealthSummary healthSummary,
    required CalendarSummary calendarSummary,
    required AppCategory appCategory,
    required EventContext eventContext,
    required double deltaSteps,
    required double energyLevel,
    required double cognitiveLoad,
  }) {
    final reasons = <String>[];

    // 1. 이벤트 컨텍스트
    if (eventContext != EventContext.none) {
      final contextNames = {
        EventContext.meeting: '회의',
        EventContext.workout: '운동',
        EventContext.meal: '식사',
        EventContext.commute: '이동',
        EventContext.focus: '집중 작업',
        EventContext.personal: '개인 일정',
      };
      reasons.add('${contextNames[eventContext]} 중입니다');
    }

    // 2. 앱 카테고리와 사용 시간
    if (screenSummary.totalUsage.inMinutes > 15) {
      final categoryNames = {
        AppCategory.productivity: '생산성',
        AppCategory.communication: '커뮤니케이션',
        AppCategory.entertainment: '엔터테인먼트',
        AppCategory.social: '소셜',
        AppCategory.creative: '창작',
        AppCategory.education: '교육',
        AppCategory.health: '건강',
      };
      if (categoryNames.containsKey(appCategory)) {
        reasons.add('${categoryNames[appCategory]} 앱을 ${screenSummary.totalUsage.inMinutes}분 사용');
      }
    }

    // 3. 활동량
    if (physicalState == PhysicalState.active) {
      reasons.add('${healthSummary.totalSteps.toInt()}걸음으로 활발하게 활동 중');
      if (deltaSteps > 500) {
        reasons.add('활동량이 급격히 증가했습니다');
      }
    } else if (physicalState == PhysicalState.inactive) {
      reasons.add('활동량이 적은 상태입니다');
    }

    // 4. 에너지 레벨
    if (energyLevel > 0.7) {
      reasons.add('에너지 레벨이 높습니다');
    } else if (energyLevel < 0.4) {
      reasons.add('피로한 상태일 수 있습니다');
    }

    // 5. 인지 부하
    if (cognitiveLoad > 0.7) {
      reasons.add('높은 집중력이 필요한 작업 중');
    }

    return reasons.isEmpty ? '데이터 부족' : reasons.join(', ');
  }
}


