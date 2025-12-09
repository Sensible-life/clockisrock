import '../models/analysis_result.dart';

/// RFID UID와 시간대를 자동 매핑하는 서비스
class RfidTimeMapper {
  // 고정된 RFID UID → 시간대 매핑
  static const Map<String, int> _uidToHour = {
    '1A953A7F': 6,   // 아침 6시
    '6335D513': 12,  // 점심 12시
    '40C5B91E': 18,  // 저녁 18시
    'D2654819': 0,   // 밤 0시 (자정)
  };

  /// RFID UID로 시간대(hour) 가져오기
  int? getHourForUid(String uid) {
    return _uidToHour[uid.toUpperCase()];
  }

  /// 분석 결과에서 특정 시간대의 음악 추천 찾기
  MusicRecommendation? getMusicForHour(
    DailyAnalysis analysis,
    int targetHour,
  ) {
    try {
      // 1. 해당 시간대의 음악 추천 찾기
      final musicForHour = analysis.recommendations.where((music) {
        if (music.recommendedFor == null) return false;
        return music.recommendedFor!.timeSlot.hour == targetHour;
      }).toList();

      if (musicForHour.isNotEmpty) {
        return musicForHour.first;
      }

      // 2. 해당 시간대가 없으면 가장 가까운 시간대 찾기
      MusicRecommendation? closestMusic;
      int minDiff = 24;

      for (final music in analysis.recommendations) {
        if (music.recommendedFor == null) continue;

        final hour = music.recommendedFor!.timeSlot.hour;
        final diff = (hour - targetHour).abs();

        if (diff < minDiff) {
          minDiff = diff;
          closestMusic = music;
        }
      }

      return closestMusic;
    } catch (e) {
      print('Error finding music for hour $targetHour: $e');
      return null;
    }
  }

  /// 모든 RFID UID 목록 가져오기
  List<String> getAllUids() {
    return _uidToHour.keys.toList();
  }

  /// UID의 시간대 이름 가져오기 (한국어)
  String getTimeLabel(String uid) {
    final hour = getHourForUid(uid);
    if (hour == null) return '알 수 없음';

    switch (hour) {
      case 6:
        return '아침 (6시)';
      case 12:
        return '점심 (12시)';
      case 18:
        return '저녁 (18시)';
      case 0:
        return '밤 (자정)';
      default:
        return '$hour시';
    }
  }

  /// 모든 시간대 정보 가져오기
  Map<String, String> getAllTimeMappings() {
    final result = <String, String>{};
    for (final uid in _uidToHour.keys) {
      result[uid] = getTimeLabel(uid);
    }
    return result;
  }
}
