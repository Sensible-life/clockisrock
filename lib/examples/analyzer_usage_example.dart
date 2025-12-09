/// 개선된 DataAnalyzer 사용 예제
///
/// 이 파일은 새로운 분석 시스템을 어떻게 사용하는지 보여줍니다.

import '../services/data_analyzer.dart';
import '../services/screen_data_service.dart';
import '../services/health_data_service.dart';
import '../services/calendar_service.dart';
import '../services/music_recommendation_service.dart';
import '../services/youtube_music_service.dart';

/// 기본 사용법
Future<void> basicUsageExample() async {
  // 1. 서비스 초기화
  final screenService = ScreenDataService();
  final healthService = HealthDataService();
  final calendarService = CalendarService();

  // 2. DataAnalyzer 생성 (YouTube API 없이)
  final analyzer = DataAnalyzer(
    screenDataService: screenService,
    healthDataService: healthService,
    calendarService: calendarService,
  );

  // 3. 특정 날짜 분석
  final today = DateTime.now();
  final analysis = await analyzer.analyzeDate(today);

  // 4. 결과 출력
  print('=== ${analysis.date.toString().split(' ')[0]} 분석 결과 ===\n');

  for (var slot in analysis.timeSlots) {
    if (slot.focusScore > 0.5 || slot.activityScore > 0.5) {
      print('${slot.timeSlot.hour}시:');
      print('  - Mental: ${slot.mentalState.name}');
      print('  - Physical: ${slot.physicalState.name}');
      print('  - Focus Score: ${slot.focusScore.toStringAsFixed(2)}');
      print('  - Activity Score: ${slot.activityScore.toStringAsFixed(2)}');
      print('  - 앱 카테고리: ${slot.appCategory.name}');
      print('  - 시간대: ${slot.timeOfDay.name}');
      print('  - 이벤트 컨텍스트: ${slot.eventContext.name}');
      print('  - Δ걸음수: ${slot.deltaSteps.toInt()}');
      print('  - 에너지 레벨: ${slot.energyLevel.toStringAsFixed(2)}');
      print('  - 인지 부하: ${slot.cognitiveLoad.toStringAsFixed(2)}');
      print('  - 생체리듬 가중치: ${slot.circadianMultiplier}');
      print('  - 분석: ${slot.reasoning}');
      print('');
    }
  }

  // 5. 음악 추천 출력
  print('=== 음악 추천 (${analysis.recommendations.length}개) ===\n');
  for (var rec in analysis.recommendations) {
    print('${rec.title} - ${rec.artist}');
    print('  장르: ${rec.genre}');
    print('  이유: ${rec.reasoning}');
    if (rec.youtubeId != null) {
      print('  YouTube: https://www.youtube.com/watch?v=${rec.youtubeId}');
    }
    print('');
  }
}

/// YouTube Music API 연동 사용법
Future<void> youtubeApiUsageExample() async {
  // 1. YouTube Music API 키 설정
  const youtubeApiKey = 'YOUR_YOUTUBE_API_KEY_HERE'; // TODO: 실제 API 키로 교체

  // 2. 서비스 초기화
  final screenService = ScreenDataService();
  final healthService = HealthDataService();
  final calendarService = CalendarService();

  // 3. YouTube Music Service 생성
  final youtubeService = YouTubeMusicService(apiKey: youtubeApiKey);

  // 4. MusicRecommendationService 생성 (YouTube 연동)
  final musicService = MusicRecommendationService(
    youtubeService: youtubeService,
  );

  // 5. DataAnalyzer 생성 (YouTube API 포함)
  final analyzer = DataAnalyzer(
    screenDataService: screenService,
    healthDataService: healthService,
    calendarService: calendarService,
    musicService: musicService,
  );

  // 6. 분석 실행
  final today = DateTime.now();
  final analysis = await analyzer.analyzeDate(today);

  // 7. 결과 출력 (실제 YouTube 음악 포함)
  print('=== YouTube Music 추천 (${analysis.recommendations.length}개) ===\n');
  for (var rec in analysis.recommendations) {
    print('${rec.title}');
    print('  아티스트: ${rec.artist}');
    print('  장르: ${rec.genre}');
    print('  이유: ${rec.reasoning}');
    if (rec.youtubeId != null) {
      print('  YouTube 링크: https://www.youtube.com/watch?v=${rec.youtubeId}');
    }
    print('');
  }
}

/// 특정 시간대의 상세 분석 예제
Future<void> detailedTimeSlotAnalysisExample() async {
  final screenService = ScreenDataService();
  final healthService = HealthDataService();
  final calendarService = CalendarService();

  final analyzer = DataAnalyzer(
    screenDataService: screenService,
    healthDataService: healthService,
    calendarService: calendarService,
  );

  final today = DateTime.now();
  final analysis = await analyzer.analyzeDate(today);

  // 오전 10시 분석 찾기
  final morningSlot = analysis.timeSlots.firstWhere(
    (slot) => slot.timeSlot.hour == 10,
    orElse: () => analysis.timeSlots.first,
  );

  print('=== 오전 10시 상세 분석 ===\n');
  print('기본 상태:');
  print('  Mental State: ${morningSlot.mentalState.name}');
  print('  Physical State: ${morningSlot.physicalState.name}');
  print('');

  print('점수:');
  print('  Focus Score: ${morningSlot.focusScore.toStringAsFixed(2)}');
  print('  Activity Score: ${morningSlot.activityScore.toStringAsFixed(2)}');
  print('');

  print('Derived Features:');
  print('  앱 카테고리: ${morningSlot.appCategory.name}');
  print('  시간대: ${morningSlot.timeOfDay.name}');
  print('  이벤트 컨텍스트: ${morningSlot.eventContext.name}');
  print('');

  print('변화량 분석:');
  print('  Δ걸음수: ${morningSlot.deltaSteps.toInt()} 걸음');
  print('  Δ심박수: ${morningSlot.deltaHeartRate.toStringAsFixed(1)} bpm');
  print('  Δ스크린: ${morningSlot.deltaScreenUsage.toStringAsFixed(1)} 분');
  print('');

  print('맥락 분석:');
  print('  생체리듬 가중치: ${morningSlot.circadianMultiplier}');
  print('  에너지 레벨: ${morningSlot.energyLevel.toStringAsFixed(2)}');
  print('  인지 부하: ${morningSlot.cognitiveLoad.toStringAsFixed(2)}');
  print('  세션 지속: ${morningSlot.sessionDuration.inMinutes}분');
  print('');

  print('분석 근거:');
  print('  ${morningSlot.reasoning}');
  print('');

  // 이 시간대에 적합한 음악
  final relevantMusic = analysis.recommendations.where(
    (rec) => rec.recommendedFor?.timeSlot.hour == 10,
  );

  if (relevantMusic.isNotEmpty) {
    print('추천 음악:');
    for (var rec in relevantMusic) {
      print('  - ${rec.title} (${rec.genre})');
      print('    ${rec.reasoning}');
    }
  }
}

/// 4분면 분석 예제
Future<void> quadrantAnalysisExample() async {
  final screenService = ScreenDataService();
  final healthService = HealthDataService();
  final calendarService = CalendarService();

  final analyzer = DataAnalyzer(
    screenDataService: screenService,
    healthDataService: healthService,
    calendarService: calendarService,
  );

  final today = DateTime.now();
  final analysis = await analyzer.analyzeDate(today);

  // 4분면별 시간대 분류
  final q1 = <int>[]; // High Focus, Low Activity
  final q2 = <int>[]; // High Focus, High Activity
  final q3 = <int>[]; // Low Focus, High Activity
  final q4 = <int>[]; // Low Focus, Low Activity

  for (var slot in analysis.timeSlots) {
    final hour = slot.timeSlot.hour;
    final focus = slot.focusScore;
    final activity = slot.activityScore;

    if (focus > 0.6 && activity < 0.4) {
      q1.add(hour);
    } else if (focus > 0.6 && activity > 0.6) {
      q2.add(hour);
    } else if (focus < 0.4 && activity > 0.6) {
      q3.add(hour);
    } else if (focus < 0.4 && activity < 0.4) {
      q4.add(hour);
    }
  }

  print('=== 4분면 분석 결과 ===\n');
  print('Q1 (집중/비활발): ${q1.map((h) => "${h}시").join(", ")}');
  print('   → 추천: Lo-Fi, Classical, Study Music\n');

  print('Q2 (집중/활발): ${q2.map((h) => "${h}시").join(", ")}');
  print('   → 추천: Upbeat Electronic, Indie Rock\n');

  print('Q3 (휴식/활발): ${q3.map((h) => "${h}시").join(", ")}');
  print('   → 추천: Workout Mix, EDM, Dance\n');

  print('Q4 (휴식/비활발): ${q4.map((h) => "${h}시").join(", ")}');
  print('   → 추천: Ambient, Meditation, Soft Jazz\n');
}

/// 전체 예제 실행
void main() async {
  print('╔════════════════════════════════════════╗');
  print('║  개선된 DataAnalyzer 사용 예제         ║');
  print('╚════════════════════════════════════════╝\n');

  // 1. 기본 사용법
  print('1️⃣  기본 사용법\n');
  await basicUsageExample();

  print('\n' + '=' * 50 + '\n');

  // 2. 상세 시간대 분석
  print('2️⃣  상세 시간대 분석\n');
  await detailedTimeSlotAnalysisExample();

  print('\n' + '=' * 50 + '\n');

  // 3. 4분면 분석
  print('3️⃣  4분면 분석\n');
  await quadrantAnalysisExample();

  print('\n' + '=' * 50 + '\n');

  // 4. YouTube API 연동 (주석 처리 - API 키 필요)
  // print('4️⃣  YouTube Music API 연동\n');
  // await youtubeApiUsageExample();

  print('\n✅ 모든 예제 실행 완료!');
}
