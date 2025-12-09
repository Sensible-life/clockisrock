# 실제 데이터 연동 가이드

이 문서는 ClockisRock 앱에서 실제 데이터를 연동하기 위해 필요한 모든 것들을 설명합니다.

## 1. Usage Stats API (스크린 타임 데이터)

### 필요한 것들

#### 1.1 안드로이드 네이티브 코드 구현

**파일 위치**: `android/app/src/main/kotlin/com/example/clockisrock/UsageStatsPlugin.kt`

필요한 기능:
- UsageStatsManager를 사용한 앱 사용 통계 조회
- 권한 확인 및 설정 화면 열기
- MethodChannel을 통한 Flutter와 통신

**주요 클래스/메서드**:
```kotlin
- UsageStatsManager.queryUsageStats()
- Settings.ACTION_USAGE_ACCESS_SETTINGS (설정 화면 열기)
- PackageManager.getApplicationLabel() (앱 이름 가져오기)
```

#### 1.2 권한 설정

이미 `AndroidManifest.xml`에 추가됨:
```xml
<uses-permission android:name="android.permission.PACKAGE_USAGE_STATS" />
```

**사용자 액션 필요**:
- 설정 > 앱 > 특별 액세스 > 사용 통계 액세스
- ClockisRock 앱 선택 및 권한 부여

#### 1.3 구현 단계

1. **Kotlin 플러그인 파일 생성**
   - `UsageStatsPlugin.kt` 생성
   - MethodChannel 설정
   - UsageStatsManager 연동

2. **Flutter 서비스 수정**
   - `screen_data_service.dart`의 MethodChannel 호출 구현
   - 실제 데이터 파싱 로직 추가

3. **테스트**
   - 실제 기기에서 테스트 (에뮬레이터에서는 제한적)

---

## 2. Health Connect API (헬스 데이터)

### 필요한 것들

#### 2.1 Health Connect 앱 설치

**사용자 액션 필요**:
- Google Play Store에서 "Health Connect" 앱 설치
- Android 14 이상에서는 기본 포함

#### 2.2 권한 설정

이미 `AndroidManifest.xml`에 추가됨:
```xml
<uses-permission android:name="android.permission.READ_HEALTH_DATA" />
```

**추가 필요 사항**:
- Health Connect에서 읽기 권한 명시적 요청
- 사용자가 Health Connect 앱에서 권한 승인

#### 2.3 데이터 타입 권한

현재 구현된 데이터 타입:
- `HealthDataType.STEPS` (걸음 수)
- `HealthDataType.HEART_RATE` (심박수)
- `HealthDataType.ACTIVE_ENERGY_BURNED` (활동 칼로리)
- `HealthDataType.DISTANCE_WALKING_RUNNING` (이동 거리)

**각 데이터 타입별 권한 요청 필요**

#### 2.4 삼성 헬스 연동 (선택사항)

삼성 헬스를 직접 연동하려면:
- Samsung Health SDK 필요
- Samsung Developer 계정 등록
- SDK 라이선스 키 발급

**대안**: Health Connect를 통해 삼성 헬스 데이터 자동 동기화 (권장)

#### 2.5 구현 상태

현재 `health_data_service.dart`는 이미 구현되어 있음:
- Health Connect 연동 코드 포함
- 권한 요청 로직 포함
- 데이터 수집 로직 포함

**추가 작업 필요**:
- 실제 기기에서 테스트
- 권한 요청 UI 개선
- 에러 핸들링 강화

---

## 3. Google Calendar API (캘린더 데이터)

### 필요한 것들

#### 3.1 Google Cloud Console 설정

1. **프로젝트 생성**
   - [Google Cloud Console](https://console.cloud.google.com/) 접속
   - 새 프로젝트 생성 또는 기존 프로젝트 선택

2. **API 활성화**
   - "API 및 서비스" > "라이브러리"
   - "Google Calendar API" 검색 및 활성화

3. **OAuth 2.0 클라이언트 ID 생성**
   - "API 및 서비스" > "사용자 인증 정보"
   - "사용자 인증 정보 만들기" > "OAuth 클라이언트 ID"
   - 애플리케이션 유형: Android
   - 패키지 이름: `com.example.clockisrock`
   - SHA-1 인증서 지문 필요 (디버그/릴리즈 각각)

#### 3.2 SHA-1 인증서 지문 얻기

**디버그 키스토어**:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**릴리즈 키스토어** (나중에):
```bash
keytool -list -v -keystore [키스토어 경로] -alias [앨리어스]
```

#### 3.3 OAuth 2.0 클라이언트 ID 설정

생성된 클라이언트 ID를 앱에 추가:
- `android/app/src/main/res/values/strings.xml`에 클라이언트 ID 저장
- 또는 환경 변수로 관리

#### 3.4 구현 단계

1. **인증 플로우 구현**
   - `googleapis_auth` 패키지 사용
   - OAuth 2.0 인증 화면 표시
   - 액세스 토큰 저장 (SharedPreferences 또는 secure storage)

2. **Calendar API 호출**
   - `googleapis` 패키지의 Calendar API 사용
   - 이벤트 목록 조회
   - 시간 범위 필터링

3. **토큰 갱신**
   - 리프레시 토큰으로 액세스 토큰 갱신
   - 만료 시 재인증

#### 3.5 필요한 패키지

이미 `pubspec.yaml`에 추가됨:
```yaml
googleapis: ^13.1.0
googleapis_auth: ^1.6.0
```

#### 3.6 구현 예시 코드 위치

`lib/services/calendar_service.dart`에 TODO 주석으로 표시됨

---

## 4. 전체 구현 체크리스트

### 4.1 Usage Stats API
- [ ] Kotlin 플러그인 파일 생성 (`UsageStatsPlugin.kt`)
- [ ] MethodChannel 통신 구현
- [ ] 앱 이름 가져오기 로직 구현
- [ ] `screen_data_service.dart` 실제 데이터 연동
- [ ] 실제 기기에서 테스트

### 4.2 Health Connect
- [ ] Health Connect 앱 설치 확인
- [ ] 권한 요청 UI 테스트
- [ ] 실제 헬스 데이터 수집 테스트
- [ ] 삼성 헬스 동기화 확인 (선택사항)

### 4.3 Google Calendar
- [ ] Google Cloud Console 프로젝트 생성
- [ ] Calendar API 활성화
- [ ] OAuth 2.0 클라이언트 ID 생성
- [ ] SHA-1 인증서 지문 등록
- [ ] 인증 플로우 구현
- [ ] Calendar API 호출 구현
- [ ] 토큰 관리 구현

### 4.4 공통
- [ ] 에러 핸들링 강화
- [ ] 로딩 상태 표시
- [ ] 권한 거부 시 안내 메시지
- [ ] 데이터 없을 때 처리

---

## 5. 보안 고려사항

### 5.1 민감한 데이터 보호
- OAuth 토큰은 Secure Storage 사용
- Health 데이터는 로컬에만 저장 (필요시)
- 사용자 동의 없이 데이터 공유 금지

### 5.2 권한 관리
- 최소 권한 원칙 준수
- 사용자에게 권한 필요 이유 명확히 설명
- 권한 거부 시 대안 제시

### 5.3 개인정보 보호
- GDPR, 개인정보보호법 준수
- 데이터 수집 목적 명시
- 사용자 데이터 삭제 기능 제공

---

## 6. 테스트 가이드

### 6.1 Usage Stats 테스트
1. 실제 안드로이드 기기 필요 (에뮬레이터 제한적)
2. 여러 앱 사용 후 데이터 확인
3. 권한 거부 시나리오 테스트

### 6.2 Health Connect 테스트
1. Health Connect 앱에서 샘플 데이터 입력
2. 앱에서 데이터 수집 확인
3. 권한 거부 시나리오 테스트

### 6.3 Google Calendar 테스트
1. 테스트용 Google 계정 사용
2. 여러 캘린더 이벤트 생성
3. 인증 플로우 테스트
4. 토큰 만료 시나리오 테스트

---

## 7. 참고 자료

### 7.1 공식 문서
- [Android UsageStatsManager](https://developer.android.com/reference/android/app/usage/UsageStatsManager)
- [Health Connect](https://developer.android.com/guide/health-and-fitness/health-connect)
- [Google Calendar API](https://developers.google.com/calendar/api/guides/overview)
- [Google OAuth 2.0](https://developers.google.com/identity/protocols/oauth2)

### 7.2 Flutter 패키지
- [health 패키지](https://pub.dev/packages/health)
- [googleapis 패키지](https://pub.dev/packages/googleapis)
- [googleapis_auth 패키지](https://pub.dev/packages/googleapis_auth)

### 7.3 예제 코드
- Health Connect 예제: `lib/services/health_data_service.dart`
- Calendar 서비스 구조: `lib/services/calendar_service.dart`

---

## 8. 다음 단계

1. **우선순위 1**: Usage Stats API 구현 (가장 복잡)
2. **우선순위 2**: Google Calendar API 구현 (OAuth 설정 필요)
3. **우선순위 3**: Health Connect 테스트 및 개선 (이미 구현됨)

각 단계별로 구현 가이드를 따로 작성할 수 있습니다.


