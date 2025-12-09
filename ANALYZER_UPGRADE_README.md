# DataAnalyzer 개선 사항 문서

## 📋 목차
1. [개선 개요](#개선-개요)
2. [새로운 기능](#새로운-기능)
3. [기술적 개선 사항](#기술적-개선-사항)
4. [사용 방법](#사용-방법)
5. [YouTube Music API 설정](#youtube-music-api-설정)

---

## 🎯 개선 개요

기존의 `DataAnalyzer`는 단순한 threshold 기반 분석으로 **사용자 행동의 맥락을 충분히 파악하지 못했습니다**. 이번 개선을 통해 다음과 같은 문제를 해결했습니다:

### 기존 문제점
- ❌ 앱 분류가 너무 단순함 (키워드 매칭만 사용)
- ❌ 시간대별 생체리듬을 고려하지 않음
- ❌ 이전 시간대와의 변화량(Δ)을 분석하지 않음
- ❌ 캘린더 이벤트 컨텍스트가 부족함
- ❌ 랜덤 음악 추천 (실제 검색 없음)

### 개선 결과
- ✅ **9가지 앱 카테고리**로 세분화된 분류
- ✅ **생체리듬 기반 가중치** 적용 (시간대별 집중력/활동성 보정)
- ✅ **변화량 분석** (Δsteps, ΔheartRate, Δscreen usage)
- ✅ **7가지 이벤트 컨텍스트** 인식 (회의, 운동, 식사 등)
- ✅ **YouTube Music API 연동**으로 실제 음악 추천

---

## 🚀 새로운 기능

### 1. Derived Features (파생 특징)

기존의 raw data 외에 다음과 같은 **derived features**가 추가되었습니다:

```dart
class TimeSlotAnalysis {
  // 기존 필드...

  // === Derived Features ===
  final AppCategory appCategory;           // 앱 카테고리 (9종)
  final TimeOfDay timeOfDay;               // 시간대 분류 (5종)
  final EventContext eventContext;         // 이벤트 컨텍스트 (7종)
  final double deltaSteps;                 // 걸음 수 변화량
  final double deltaHeartRate;             // 심박 변화량
  final double deltaScreenUsage;           // 스크린 사용 변화량
  final double circadianMultiplier;        // 생체리듬 가중치
  final Duration sessionDuration;          // 세션 지속 시간
  final double energyLevel;                // 에너지 레벨 (0.0-1.0)
  final double cognitiveLoad;              // 인지 부하 (0.0-1.0)
}
```

### 2. 앱 카테고리 분류

```dart
enum AppCategory {
  productivity,    // 생산성 (문서, 업무)
  communication,   // 커뮤니케이션 (메신저, 이메일)
  entertainment,   // 엔터테인먼트 (동영상, 게임)
  social,         // 소셜 미디어
  creative,       // 창작 (디자인, 음악, 영상)
  education,      // 교육, 학습
  health,         // 건강, 운동
  utilities,      // 유틸리티
  unknown,        // 알 수 없음
}
```

**80+ 키워드 기반 semantic classification**을 사용하여 앱을 분류합니다.

### 3. 시간대 분류 & 생체리듬

```dart
enum TimeOfDay {
  earlyMorning,  // 0-6시
  morning,       // 6-12시
  afternoon,     // 12-18시
  evening,       // 18-22시
  night,         // 22-24시
}
```

**생체리듬 가중치 (Circadian Multiplier)**:
- 오전 9-12시: **1.2** (집중력 peak)
- 저녁 18-21시: **1.2** (활동 peak)
- 오후 14-16시: **0.85** (에너지 저하)
- 밤/새벽: **0.7** (피로)

### 4. 이벤트 컨텍스트 인식

```dart
enum EventContext {
  meeting,   // 회의
  workout,   // 운동
  meal,      // 식사
  commute,   // 이동
  focus,     // 집중 작업
  personal,  // 개인 일정
  none,      // 없음
}
```

캘린더 이벤트 제목/설명에서 **자동으로 컨텍스트를 추출**합니다.

### 5. 변화량 기반 분석

```dart
// 이전 시간 대비 변화량 계산
final deltaSteps = currentSteps - previousSteps;
final deltaHeartRate = currentHR - previousHR;
final deltaScreenUsage = currentUsage - previousUsage;
```

**변화량이 중요한 이유:**
- 절대값만으로는 상태 전이를 감지할 수 없음
- 예: 걸음 수 500 → 2000 = 갑자기 활동 시작
- 예: 심박 80 → 120 = 운동 또는 긴장

### 6. Context-Aware Rule Engine

단순 threshold가 아닌 **맥락 기반 규칙**을 사용합니다:

```
회의 직후 + 심박 안정됨 + 스크린 사용 증가
  → "집중 피로" 상태로 판단
  → Ambient/Lo-fi 음악 추천

운동 직후 + 걸음 수 급감 + 낮은 스크린 사용
  → "쿨다운" 상태로 판단
  → Soft Electronic/Chill 음악 추천

밤 12시 이후 + 높은 스크린 사용
  → "피로하지만 활동" 상태 (생체리듬 가중치 0.7 적용)
  → Sleep-inducing 음악 추천
```

### 7. YouTube Music API 연동

**실제 음악을 검색하여 추천**합니다:

```dart
final youtubeService = YouTubeMusicService(apiKey: 'YOUR_API_KEY');
final recommendations = await youtubeService.searchMusicByQuadrant(
  focusScore: 0.8,
  activityScore: 0.3,
  analysis: timeSlotAnalysis,
);
```

**4분면 기반 음악 매핑:**

|              | Low Activity          | High Activity        |
|--------------|-----------------------|----------------------|
| **High Focus** | Lo-Fi, Classical      | Upbeat Electronic    |
| **Low Focus**  | Ambient, Meditation   | Workout Mix, EDM     |

---

## 🔧 기술적 개선 사항

### 1. Sequential State Modeling

```dart
// 이전 시간대 정보를 다음 분석에 전달
for (int hour = 0; hour < 24; hour++) {
  final previousSlot = timeSlotAnalyses.isNotEmpty
      ? timeSlotAnalyses.last
      : null;

  final analysis = _analyzeTimeSlot(
    // ...
    previousSlot: previousSlot,  // 전달!
  );
}
```

이제 각 시간대가 **독립적이지 않고** 이전 상태의 영향을 받습니다.

### 2. Multi-Factor Scoring

기존:
```dart
// 단순 가산
score = baseScore + screenBonus + calendarBonus;
```

개선:
```dart
// 여러 요인을 종합적으로 고려
score = (mentalStateScore + cognitiveLoadScore) / 2
      * circadianMultiplier
      + appCategoryBonus
      + contextBonus;
```

### 3. Energy & Cognitive Load Estimation

```dart
// 에너지 레벨 추정
double energyLevel = circadianMultiplier  // 생체리듬 기반
                   + physicalStateBonus   // 활동 상태
                   + heartRateBonus;      // 심박수

// 인지 부하 추정
double cognitiveLoad = appCategoryLoad    // 앱 종류
                     + sessionDuration    // 지속 시간
                     + eventLoad;         // 이벤트 부하
```

### 4. Fallback 메커니즘

```dart
try {
  // YouTube API 사용
  recommendations = await youtubeService.search(...);
} catch (e) {
  // 실패 시 폴백 추천 사용
  recommendations = getFallbackRecommendations(...);
}
```

API 실패에도 **안정적으로 작동**합니다.

---

## 📖 사용 방법

### 기본 사용법

```dart
// 1. 서비스 초기화
final screenService = ScreenDataService();
final healthService = HealthDataService();
final calendarService = CalendarService();

// 2. DataAnalyzer 생성
final analyzer = DataAnalyzer(
  screenDataService: screenService,
  healthDataService: healthService,
  calendarService: calendarService,
);

// 3. 분석 실행
final today = DateTime.now();
final analysis = await analyzer.analyzeDate(today);

// 4. 결과 사용
for (var slot in analysis.timeSlots) {
  print('${slot.timeSlot.hour}시: ${slot.reasoning}');
  print('  Focus: ${slot.focusScore.toStringAsFixed(2)}');
  print('  Activity: ${slot.activityScore.toStringAsFixed(2)}');
  print('  에너지: ${slot.energyLevel.toStringAsFixed(2)}');
  print('  인지 부하: ${slot.cognitiveLoad.toStringAsFixed(2)}');
}
```

### YouTube Music API 연동

```dart
// 1. YouTube Service 생성
final youtubeService = YouTubeMusicService(
  apiKey: 'YOUR_YOUTUBE_API_KEY',
);

// 2. Music Service 생성
final musicService = MusicRecommendationService(
  youtubeService: youtubeService,
);

// 3. DataAnalyzer에 전달
final analyzer = DataAnalyzer(
  screenDataService: screenService,
  healthDataService: healthService,
  calendarService: calendarService,
  musicService: musicService,  // 추가!
);

// 4. 분석 (실제 YouTube 음악 포함)
final analysis = await analyzer.analyzeDate(today);

for (var rec in analysis.recommendations) {
  print('${rec.title} - ${rec.artist}');
  print('YouTube: https://www.youtube.com/watch?v=${rec.youtubeId}');
}
```

### 상세 예제

`lib/examples/analyzer_usage_example.dart` 파일을 참고하세요:

```bash
dart run lib/examples/analyzer_usage_example.dart
```

---

## 🔑 YouTube Music API 설정

### 1. API Key 발급

1. [Google Cloud Console](https://console.cloud.google.com/) 접속
2. 프로젝트 생성 또는 선택
3. **API 및 서비스 > 라이브러리** 이동
4. "YouTube Data API v3" 검색 및 활성화
5. **사용자 인증 정보 > API 키 만들기**
6. API 키 복사

### 2. API Key 사용

**방법 1: 환경 변수 (권장)**

```dart
// .env 파일
YOUTUBE_API_KEY=your_api_key_here

// Dart 코드
final apiKey = Platform.environment['YOUTUBE_API_KEY'] ?? '';
final youtubeService = YouTubeMusicService(apiKey: apiKey);
```

**방법 2: 설정 파일**

```dart
// lib/config/api_keys.dart
class ApiKeys {
  static const youtubeApiKey = 'YOUR_API_KEY';
}

// 사용
final youtubeService = YouTubeMusicService(
  apiKey: ApiKeys.youtubeApiKey,
);
```

### 3. 할당량 관리

YouTube Data API v3는 **하루 10,000 유닛 무료**입니다:
- 검색 요청: 100 유닛/회
- 따라서 하루 **최대 100회 검색 가능**

**최적화 팁:**
- 중요한 시간대만 추천 생성 (현재 구현됨)
- 결과 캐싱
- 폴백 추천 활용

---

## 📊 분석 정확도 비교

### 기존 시스템
```
시나리오: 밤 12시, 유튜브 1시간 시청, 걸음 수 50
기존 판단: "집중 상태" (스크린 사용 많음)
문제: 밤늦게 엔터테인먼트 앱 사용을 집중으로 오판
```

### 개선된 시스템
```
시나리오: 밤 12시, 유튜브 1시간 시청, 걸음 수 50
개선 판단: "휴식 상태" (피로)
근거:
  - 앱 카테고리: entertainment (-0.3)
  - 시간대: night (생체리듬 0.7)
  - 스크린 사용이 많지만 밤이므로 집중 가중치 감소
  - 에너지 레벨: 0.3 (낮음)
추천: Ambient, Sleep-inducing 음악
```

---

## 🎵 음악 추천 예시

### Q1: High Focus + Low Activity
```
상황: 오전 10시, Notion 사용 45분, 걸음 수 200
추천:
  - Lo-Fi Hip Hop Study Mix
  - Classical Piano for Focus
  - Deep Concentration Beats
```

### Q2: High Focus + High Activity
```
상황: 오후 3시, 회의 중, 걸음 수 1500
추천:
  - Upbeat Indie Rock
  - Energetic Electronic
  - Motivational Pop
```

### Q3: Low Focus + High Activity
```
상황: 저녁 7시, 운동 중, 걸음 수 3000, 심박 140
추천:
  - Workout Mix 2024
  - High Energy EDM
  - Cardio Beats
```

### Q4: Low Focus + Low Activity
```
상황: 밤 11시, 스크린 10분, 걸음 수 30
추천:
  - Ambient Sleep Sounds
  - Peaceful Meditation
  - Soft Jazz for Relaxation
```

---

## 🧪 테스트 방법

```dart
// lib/examples/analyzer_usage_example.dart 실행
dart run lib/examples/analyzer_usage_example.dart

// 출력 예시:
// ╔════════════════════════════════════════╗
// ║  개선된 DataAnalyzer 사용 예제         ║
// ╚════════════════════════════════════════╝
//
// 1️⃣  기본 사용법
// 10시:
//   - Mental: focused
//   - Physical: inactive
//   - Focus Score: 0.82
//   - Activity Score: 0.23
//   - 앱 카테고리: productivity
//   - Δ걸음수: 150
//   - 에너지 레벨: 0.95
//   - 인지 부하: 0.78
```

---

## 📈 향후 개선 계획

1. **Machine Learning 모델 적용**
   - 사용자별 패턴 학습
   - 개인화된 threshold 자동 조정

2. **더 정교한 Context Reasoning**
   - 연속된 3-4 시간의 패턴 분석
   - 주간/월간 트렌드 파악

3. **Spotify/Apple Music 연동**
   - 다양한 음악 플랫폼 지원

4. **실시간 분석**
   - 현재 시간 기준 실시간 추천

---

## 💡 핵심 개선 요약

| 항목 | 기존 | 개선 |
|------|------|------|
| 앱 분류 | 15개 키워드 | 80+ 키워드, 9개 카테고리 |
| 시간 고려 | 없음 | 생체리듬 가중치 (0.7-1.2) |
| 변화량 분석 | 없음 | Δsteps, ΔHR, Δscreen |
| 이벤트 컨텍스트 | 단순 유무 | 7가지 세분화 |
| 음악 추천 | 하드코딩 | YouTube API 실시간 검색 |
| 에너지/부하 | 없음 | 추정 알고리즘 추가 |

---

## 👨‍💻 개발자 노트

이번 개선의 핵심은 **"상태(label)가 아닌 맥락(context)"**을 이해하는 것입니다.

기존: "지금 집중 중인가? Yes/No"
개선: "왜 이 상태인가? 앞으로 어떻게 변할 것인가?"

이를 통해 **정확도가 크게 향상**되었으며, 음악 추천의 만족도도 높아질 것으로 기대됩니다.

---

**제작:** Claude Code
**날짜:** 2025-12-02
**버전:** 2.0
