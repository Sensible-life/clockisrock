# 구글 캘린더 연동 설정 가이드

ClockisRock 앱에서 구글 캘린더를 연동하려면 Google Cloud Console에서 OAuth 2.0 설정이 필요합니다.

## 1. Google Cloud Console 프로젝트 생성

### 1.1 프로젝트 만들기

1. [Google Cloud Console](https://console.cloud.google.com/) 접속
2. 상단 프로젝트 선택 드롭다운 → **"새 프로젝트"** 클릭
3. 프로젝트 이름 입력: `ClockisRock` (또는 원하는 이름)
4. **"만들기"** 클릭

## 2. Google Calendar API 활성화

### 2.1 API 라이브러리에서 검색

1. 좌측 메뉴 → **"API 및 서비스"** → **"라이브러리"**
2. 검색창에 `Google Calendar API` 입력
3. **"Google Calendar API"** 클릭
4. **"사용"** 버튼 클릭

## 3. OAuth 동의 화면 구성

### 3.1 OAuth 동의 화면 설정

1. 좌측 메뉴 → **"API 및 서비스"** → **"OAuth 동의 화면"**
2. User Type 선택: **"외부"** 선택 → **"만들기"** 클릭

### 3.2 앱 정보 입력

**1단계: OAuth 동의 화면**
- **앱 이름**: `ClockisRock`
- **사용자 지원 이메일**: 본인 이메일 선택
- **개발자 연락처 정보**: 본인 이메일 입력
- **"저장 후 계속"** 클릭

**2단계: 범위**
- **"범위 추가 또는 삭제"** 클릭
- 검색창에 `calendar.readonly` 입력
- `https://www.googleapis.com/auth/calendar.readonly` 체크
- **"업데이트"** 클릭
- **"저장 후 계속"** 클릭

**3단계: 테스트 사용자**
- **"테스트 사용자 추가"** 클릭
- 본인 Gmail 주소 입력
- **"저장 후 계속"** 클릭

**4단계: 요약**
- 내용 확인 후 **"대시보드로 돌아가기"**

## 4. OAuth 2.0 클라이언트 ID 생성

### 4.1 Android 클라이언트 ID 만들기

1. 좌측 메뉴 → **"API 및 서비스"** → **"사용자 인증 정보"**
2. 상단 **"+ 사용자 인증 정보 만들기"** → **"OAuth 클라이언트 ID"** 클릭
3. 애플리케이션 유형: **"Android"** 선택
4. 이름: `ClockisRock Android` 입력

### 4.2 SHA-1 인증서 지문 얻기

터미널에서 다음 명령어 실행:

#### 디버그 키스토어 (개발용):
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

#### 출력 예시:
```
인증서 지문:
SHA1: 12:34:56:78:9A:BC:DE:F0:12:34:56:78:9A:BC:DE:F0:12:34:56:78
```

### 4.3 패키지 이름 및 SHA-1 입력

- **패키지 이름**: `com.example.clockisrock`
- **SHA-1 인증서 지문**: 위에서 얻은 SHA-1 값 붙여넣기
- **"만들기"** 클릭

### 4.4 클라이언트 ID 확인

생성된 OAuth 2.0 클라이언트 ID를 확인하고 복사해두세요 (나중에 필요할 수 있음).

## 5. (선택사항) 웹 클라이언트 ID 추가

Google Sign-In이 일부 기기에서 웹 클라이언트를 요구할 수 있으므로 추가로 생성:

1. **"+ 사용자 인증 정보 만들기"** → **"OAuth 클라이언트 ID"**
2. 애플리케이션 유형: **"웹 애플리케이션"** 선택
3. 이름: `ClockisRock Web`
4. **"만들기"** 클릭

## 6. 릴리즈 버전용 설정 (배포 시)

### 6.1 릴리즈 키스토어 SHA-1

배포용 APK를 빌드하려면 릴리즈 키스토어가 필요합니다:

```bash
keytool -genkey -v -keystore ~/clockisrock-release-key.jks -alias clockisrock -keyalg RSA -keysize 2048 -validity 10000
```

생성된 키스토어의 SHA-1:
```bash
keytool -list -v -keystore ~/clockisrock-release-key.jks -alias clockisrock
```

### 6.2 릴리즈용 클라이언트 ID 추가

1. Google Cloud Console → **"사용자 인증 정보"**
2. 새로운 Android OAuth 클라이언트 ID 생성
3. 이름: `ClockisRock Android Release`
4. 패키지: `com.example.clockisrock`
5. SHA-1: 릴리즈 키스토어의 SHA-1 입력

## 7. 앱에서 테스트

### 7.1 패키지 설치

```bash
flutter pub get
```

### 7.2 앱 실행

```bash
flutter run
```

### 7.3 구글 로그인 테스트

1. 앱 실행
2. **"구글 캘린더 연동하기"** 버튼 클릭
3. Google 로그인 화면에서 **테스트 사용자로 추가한 계정** 선택
4. 권한 요청 화면에서 **"허용"** 클릭
5. 로그인 성공 시 버튼이 **"구글 캘린더 연동됨"** 으로 변경됨

## 8. 문제 해결

### 8.1 "Error 10" 또는 "Developer Error"

**원인:** SHA-1 인증서 지문이 잘못되었거나 패키지 이름이 맞지 않음

**해결:**
1. SHA-1 지문을 다시 확인
2. `android/app/build.gradle.kts`의 `applicationId`가 `com.example.clockisrock`인지 확인
3. Google Cloud Console에서 SHA-1과 패키지 이름 재확인

### 8.2 "앱이 확인되지 않음" 경고

**원인:** OAuth 동의 화면이 "테스트" 모드

**해결:**
1. 테스트 사용자로 추가한 계정으로 로그인
2. **"고급"** → **"ClockisRock(으)로 이동(안전하지 않음)"** 클릭

### 8.3 Calendar API 호출 실패

**원인:** Calendar API가 활성화되지 않음

**해결:**
1. Google Cloud Console → API 라이브러리
2. "Google Calendar API" 검색
3. **"사용"** 클릭

## 9. 프로덕션 배포 시

### 9.1 OAuth 동의 화면 게시

테스트 사용자만 로그인 가능한 상태를 해제하려면:

1. OAuth 동의 화면 → **"앱 게시"** 클릭
2. Google 검토 프로세스 진행 (일반적으로 며칠 소요)

### 9.2 Play Console 설정

Google Play Store에 앱을 출시할 때:

1. Play Console에서 앱 서명 키의 SHA-1 확인
2. Google Cloud Console에 해당 SHA-1 추가

---

## 참고 자료

- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)
- [Google Calendar API Documentation](https://developers.google.com/calendar/api/guides/overview)
- [OAuth 2.0 for Mobile Apps](https://developers.google.com/identity/protocols/oauth2/native-app)
