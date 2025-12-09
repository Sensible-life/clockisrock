import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import '../models/calendar_data.dart';

/// 구글 캘린더 서비스
class CalendarService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      calendar.CalendarApi.calendarReadonlyScope,
    ],
  );

  GoogleSignInAccount? _currentUser;
  calendar.CalendarApi? _calendarApi;

  /// 구글 계정 로그인 및 인증
  Future<bool> authenticate() async {
    try {
      // 이미 로그인되어 있는지 확인
      _currentUser = await _googleSignIn.signInSilently();

      // 로그인되어 있지 않으면 명시적 로그인
      if (_currentUser == null) {
        _currentUser = await _googleSignIn.signIn();
      }

      if (_currentUser == null) {
        // ignore: avoid_print
        print('구글 로그인 취소됨');
        return false;
      }

      // Calendar API 클라이언트 생성
      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) {
        // ignore: avoid_print
        print('인증된 HTTP 클라이언트를 가져올 수 없습니다');
        return false;
      }

      _calendarApi = calendar.CalendarApi(httpClient);
      // ignore: avoid_print
      print('구글 캘린더 인증 성공: ${_currentUser!.email}');
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('구글 캘린더 인증 오류: $e');
      return false;
    }
  }

  /// 로그아웃
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _calendarApi = null;
  }

  /// 로그인 상태 확인
  bool get isAuthenticated => _currentUser != null && _calendarApi != null;

  /// 특정 날짜의 캘린더 이벤트 가져오기
  Future<List<CalendarEvent>> getEventsForDate(DateTime date) async {
    // 인증 확인
    if (!isAuthenticated) {
      final authenticated = await authenticate();
      if (!authenticated) {
        // ignore: avoid_print
        print('캘린더 인증 실패 - 샘플 데이터 반환');
        return _getSampleEvents(date);
      }
    }

    try {
      // 로컬 시간대로 시작/종료 시간 설정
      final startTime = DateTime(date.year, date.month, date.day, 0, 0, 0);
      final endTime = DateTime(date.year, date.month, date.day, 23, 59, 59);

      // ignore: avoid_print
      print('캘린더 조회: $startTime ~ $endTime (로컬 시간)');
      print('UTC 변환: ${startTime.toUtc()} ~ ${endTime.toUtc()}');

      // 기본 캘린더의 이벤트 가져오기
      final events = await _calendarApi!.events.list(
        'primary',
        timeMin: startTime.toUtc(),
        timeMax: endTime.toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
      );

      if (events.items == null || events.items!.isEmpty) {
        // ignore: avoid_print
        print('해당 날짜에 이벤트가 없습니다');
        return [];
      }

      // ignore: avoid_print
      print('구글 캘린더 이벤트 ${events.items!.length}개 가져옴');

      // Calendar API 이벤트를 우리 모델로 변환
      final calendarEvents = events.items!.map((event) {
        DateTime? start;
        DateTime? end;
        
        // dateTime이 있으면 UTC에서 로컬 시간대로 변환
        if (event.start?.dateTime != null) {
          start = event.start!.dateTime!.toLocal();
        } else if (event.start?.date != null) {
          // date만 있는 경우 (하루 종일 이벤트)
          start = DateTime(
            event.start!.date!.year,
            event.start!.date!.month,
            event.start!.date!.day,
          );
        }
        
        if (event.end?.dateTime != null) {
          end = event.end!.dateTime!.toLocal();
        } else if (event.end?.date != null) {
          // date만 있는 경우 (하루 종일 이벤트)
          end = DateTime(
            event.end!.date!.year,
            event.end!.date!.month,
            event.end!.date!.day,
          );
        }

        // ignore: avoid_print
        print('이벤트: ${event.summary}');
        print('  원본 시작: ${event.start?.dateTime ?? event.start?.date} (UTC: ${event.start?.dateTime != null})');
        print('  변환된 시작: $start (로컬 시간)');
        print('  원본 종료: ${event.end?.dateTime ?? event.end?.date} (UTC: ${event.end?.dateTime != null})');
        print('  변환된 종료: $end (로컬 시간)');

        return CalendarEvent(
          id: event.id ?? '',
          title: event.summary ?? '제목 없음',
          description: event.description,
          startTime: start ?? startTime,
          endTime: end ?? endTime,
          location: event.location,
          eventType: _inferEventType(event),
        );
      }).toList();

      return calendarEvents;
    } catch (e) {
      // ignore: avoid_print
      print('캘린더 이벤트 가져오기 오류: $e');
      // 오류 발생 시 샘플 데이터 반환
      return _getSampleEvents(date);
    }
  }

  /// 이벤트 타입 추론
  String _inferEventType(calendar.Event event) {
    final title = event.summary?.toLowerCase() ?? '';
    final description = event.description?.toLowerCase() ?? '';
    final combined = '$title $description';

    if (combined.contains('회의') ||
        combined.contains('미팅') ||
        combined.contains('meeting')) {
      return 'meeting';
    } else if (combined.contains('작업') ||
        combined.contains('개발') ||
        combined.contains('코딩') ||
        combined.contains('work') ||
        combined.contains('project')) {
      return 'work';
    } else if (combined.contains('공부') ||
        combined.contains('스터디') ||
        combined.contains('study')) {
      return 'study';
    } else if (combined.contains('운동') ||
        combined.contains('헬스') ||
        combined.contains('exercise') ||
        combined.contains('workout')) {
      return 'exercise';
    } else {
      return 'personal';
    }
  }

  /// 샘플 이벤트 (인증 실패 시 또는 데모용)
  List<CalendarEvent> _getSampleEvents(DateTime date) {
    return [
      CalendarEvent(
        id: 'demo-1',
        title: '아침 운동',
        description: '조깅 및 스트레칭',
        startTime: DateTime(date.year, date.month, date.day, 7, 0),
        endTime: DateTime(date.year, date.month, date.day, 8, 0),
        location: '공원',
        eventType: 'exercise',
      ),
      CalendarEvent(
        id: 'demo-2',
        title: '출근',
        startTime: DateTime(date.year, date.month, date.day, 9, 0),
        endTime: DateTime(date.year, date.month, date.day, 9, 30),
        location: '사무실',
        eventType: 'personal',
      ),
      CalendarEvent(
        id: 'demo-3',
        title: '팀 미팅',
        description: '주간 회의',
        startTime: DateTime(date.year, date.month, date.day, 10, 0),
        endTime: DateTime(date.year, date.month, date.day, 11, 30),
        location: '회의실 A',
        eventType: 'meeting',
      ),
      CalendarEvent(
        id: 'demo-4',
        title: '점심 식사',
        startTime: DateTime(date.year, date.month, date.day, 12, 0),
        endTime: DateTime(date.year, date.month, date.day, 13, 0),
        location: '구내식당',
        eventType: 'personal',
      ),
      CalendarEvent(
        id: 'demo-5',
        title: '프로젝트 작업',
        description: '코드 리뷰 및 개발',
        startTime: DateTime(date.year, date.month, date.day, 14, 0),
        endTime: DateTime(date.year, date.month, date.day, 17, 0),
        location: '개발실',
        eventType: 'work',
      ),
      CalendarEvent(
        id: 'demo-6',
        title: '저녁 약속',
        description: '친구와 저녁 식사',
        startTime: DateTime(date.year, date.month, date.day, 19, 0),
        endTime: DateTime(date.year, date.month, date.day, 21, 0),
        location: '강남역 레스토랑',
        eventType: 'personal',
      ),
    ];
  }

  /// 시간대별 캘린더 요약 가져오기
  Future<List<CalendarSummary>> getCalendarSummaryByTimeSlot(DateTime date) async {
    final events = await getEventsForDate(date);

    // ignore: avoid_print
    print('시간대별 그룹화 시작: 총 ${events.length}개 이벤트');

    // 1시간 단위로 그룹화
    final Map<int, List<CalendarEvent>> grouped = {};

    for (var event in events) {
      // 이벤트가 포함된 모든 시간대에 추가
      var currentHour = DateTime(
        event.startTime.year,
        event.startTime.month,
        event.startTime.day,
        event.startTime.hour,
      );

      final endHour = DateTime(
        event.endTime.year,
        event.endTime.month,
        event.endTime.day,
        event.endTime.hour,
      );

      while (currentHour.isBefore(endHour) || currentHour.isAtSameMomentAs(endHour)) {
        final hour = currentHour.hour;
        if (!grouped.containsKey(hour)) {
          grouped[hour] = [];
        }
        grouped[hour]!.add(event);
        // ignore: avoid_print
        print('  → ${hour}시에 이벤트 추가: ${event.title}');
        currentHour = currentHour.add(const Duration(hours: 1));
      }
    }

    // ignore: avoid_print
    print('그룹화 완료: ${grouped.keys.length}개 시간대에 이벤트 있음 (시간대: ${grouped.keys.toList()})');


    final List<CalendarSummary> summaries = [];

    // 24시간 모두 생성 (이벤트가 없는 시간대도 포함)
    for (int hour = 0; hour < 24; hour++) {
      final eventsInSlot = grouped[hour] ?? [];
      final primaryEventType = eventsInSlot.isNotEmpty
          ? eventsInSlot.first.eventType
          : null;

      summaries.add(
        CalendarSummary(
          timeSlot: DateTime(date.year, date.month, date.day, hour),
          events: eventsInSlot,
          hasEvent: eventsInSlot.isNotEmpty,
          primaryEventType: primaryEventType,
        ),
      );
    }

    return summaries;
  }

  /// 이벤트 타입에서 집중도 추정
  ///
  /// 'work', 'meeting' 등은 집중 상태로 간주
  /// 'personal', 'break' 등은 휴식 상태로 간주
  bool isFocusEventType(String? eventType) {
    if (eventType == null) return false;
    return ['work', 'meeting', 'study'].contains(eventType.toLowerCase());
  }
}

