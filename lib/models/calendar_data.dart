/// 구글 캘린더 이벤트 데이터
class CalendarEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final String? eventType; // 'meeting', 'work', 'personal', etc.

  CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.location,
    this.eventType,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'location': location,
        'eventType': eventType,
      };

  factory CalendarEvent.fromJson(Map<String, dynamic> json) => CalendarEvent(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        startTime: DateTime.parse(json['startTime']),
        endTime: DateTime.parse(json['endTime']),
        location: json['location'],
        eventType: json['eventType'],
      );

  Duration get duration => endTime.difference(startTime);
}

/// 시간대별 캘린더 요약
class CalendarSummary {
  final DateTime timeSlot;
  final List<CalendarEvent> events;
  final bool hasEvent;
  final String? primaryEventType;

  CalendarSummary({
    required this.timeSlot,
    required this.events,
    required this.hasEvent,
    this.primaryEventType,
  });
}


