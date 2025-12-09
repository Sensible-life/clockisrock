# ClockisRock 🎵

당신의 하루 데이터를 분석하여 최적의 음악을 추천하는 안드로이드 앱입니다.

## 기능

### 데이터 수집
- **스마트폰 스크린 데이터**: 앱 사용 시간 및 패턴 분석
- **워치 데이터**: 삼성 헬스 / Health Connect 연동 (걸음 수, 심박수, 칼로리 등)
- **구글 캘린더**: 일정 정보를 통한 활동 패턴 분석

### 데이터 분석
- **집중/휴식 상태 분석**: 스크린 사용 패턴과 캘린더 이벤트를 기반으로 마음/뇌 상태 판단
- **활발/비활발 상태 분석**: 헬스 데이터를 기반으로 몸 상태(움직임) 판단
- **시간대별 분석**: 24시간을 1시간 단위로 분석

### 음악 추천
- 집중 시간대: Lo-Fi Hip Hop, 클래식 등 집중력 향상 음악
- 활발한 시간대: Electronic, Pop 등 에너지 넘치는 음악
- 휴식 시간대: Ambient, Meditation 등 편안한 음악

### 시각화
- 시간대별 집중도/활동량 차트
- 시간대별 상세 분석 결과
- 음악 추천 카드

## 설치 및 실행

### 요구사항
- Flutter SDK 3.8.1 이상
- Android SDK (minSdk: 23, targetSdk: 최신)
- 안드로이드 기기 또는 에뮬레이터

### 설치 방법

1. 의존성 설치
```bash
flutter pub get
```

2. 앱 실행
```bash
flutter run
```

## 권한 설정

앱을 사용하기 전에 다음 권한을 허용해야 합니다:

1. **Usage Stats 권한**
   - 설정 > 앱 > ClockisRock > 특별 액세스 > 사용 통계 액세스
   - 또는 앱 내 "Usage Stats 권한 설정" 버튼 클릭

2. **Health Connect 권한**
   - Health Connect 앱에서 권한 허용
   - 앱 실행 시 자동으로 권한 요청

3. **구글 캘린더 권한**
   - 구글 계정 로그인 및 캘린더 접근 권한 허용

## 프로젝트 구조

```
lib/
├── main.dart                 # 앱 진입점
├── models/                   # 데이터 모델
│   ├── screen_data.dart
│   ├── health_data.dart
│   ├── calendar_data.dart
│   └── analysis_result.dart
├── services/                 # 데이터 수집 및 분석 서비스
│   ├── screen_data_service.dart
│   ├── health_data_service.dart
│   ├── calendar_service.dart
│   ├── data_analyzer.dart
│   └── music_recommendation_service.dart
├── screens/                  # 화면
│   ├── home_screen.dart
│   └── analysis_screen.dart
└── widgets/                  # 재사용 가능한 위젯
    ├── analysis_chart.dart
    └── music_recommendation_card.dart
```

## 사용 방법

1. 앱 실행 후 권한 설정
2. "오늘 분석하기" 버튼 클릭
3. 데이터 수집 및 분석 (몇 초 소요)
4. 분석 결과 화면에서:
   - 시간대별 집중도/활동량 차트 확인
   - 각 시간대별 상세 분석 결과 확인
   - 추천 음악 목록 확인

## 데모 버전

현재 버전은 데모 버전으로, 실제 데이터 대신 샘플 데이터를 사용합니다:
- 스크린 데이터: 샘플 앱 사용 데이터
- 헬스 데이터: Health Connect 연동 (실제 데이터 사용 가능)
- 캘린더 데이터: 샘플 이벤트 데이터

실제 프로덕션 버전에서는:
- 안드로이드 네이티브 코드를 통한 Usage Stats API 연동
- Google Calendar API OAuth 2.0 인증
- 음악 스트리밍 서비스 API 연동 (Spotify, Apple Music 등)

## 기술 스택

- **Flutter**: 크로스 플랫폼 프레임워크
- **Health Connect**: 헬스 데이터 수집
- **fl_chart**: 데이터 시각화
- **Google Calendar API**: 캘린더 데이터 수집

## 라이선스

이 프로젝트는 개인 프로젝트입니다.
