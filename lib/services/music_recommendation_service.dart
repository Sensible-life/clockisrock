import '../models/analysis_result.dart';
import 'youtube_music_service.dart';

/// 음악 추천 서비스
///
/// YouTube Music API를 사용하여 실제 음악을 추천합니다.
class MusicRecommendationService {
  final YouTubeMusicService? _youtubeService;

  MusicRecommendationService({YouTubeMusicService? youtubeService})
      : _youtubeService = youtubeService;

  /// 분석 결과를 바탕으로 음악 추천 생성 (향상됨)
  Future<List<MusicRecommendation>> generateRecommendations(
    List<TimeSlotAnalysis> timeSlots,
  ) async {
    final recommendations = <MusicRecommendation>[];

    // YouTube Music API가 있으면 실제 검색, 없으면 폴백
    if (_youtubeService != null) {
      // 주요 시간대만 추천 생성 (모든 시간대는 너무 많음)
      final importantSlots = _selectImportantTimeSlots(timeSlots);

      for (var slot in importantSlots) {
        try {
          // 4분면 기반 음악 검색
          final results = await _youtubeService!.searchMusicByQuadrant(
            focusScore: slot.focusScore,
            activityScore: slot.activityScore,
            analysis: slot,
          );
          recommendations.addAll(results);
        } catch (e) {
          print('Error getting YouTube recommendations: $e');
          // 에러 시 폴백 사용
          recommendations.add(_getFallbackRecommendation(slot));
        }
      }
    } else {
      // YouTube 서비스가 없으면 기존 방식 사용
      for (var slot in timeSlots) {
        final recommendation = _recommendForTimeSlot(slot);
        if (recommendation != null) {
          recommendations.add(recommendation);
        }
      }
    }

    return recommendations;
  }

  /// 중요한 시간대 선택 (추천을 생성할 시간대)
  List<TimeSlotAnalysis> _selectImportantTimeSlots(
    List<TimeSlotAnalysis> timeSlots,
  ) {
    final important = <TimeSlotAnalysis>[];

    for (var slot in timeSlots) {
      // 1. Focus나 Activity 점수가 높은 시간대
      if (slot.focusScore > 0.6 || slot.activityScore > 0.6) {
        important.add(slot);
      }
      // 2. 이벤트가 있는 시간대
      else if (slot.eventContext != EventContext.none) {
        important.add(slot);
      }
      // 3. 인지 부하나 에너지 레벨이 극단적인 시간대
      else if (slot.cognitiveLoad > 0.7 || slot.energyLevel < 0.3) {
        important.add(slot);
      }
    }

    // 최소 3개, 최대 8개 시간대 선택
    if (important.length < 3 && timeSlots.length >= 3) {
      // 점수가 높은 순으로 정렬해서 상위 3개 선택
      final sorted = [...timeSlots]
        ..sort((a, b) =>
            (b.focusScore + b.activityScore).compareTo(a.focusScore + a.activityScore));
      important.addAll(sorted.take(3).where((slot) => !important.contains(slot)));
    } else if (important.length > 8) {
      // 너무 많으면 상위 8개만
      important.sort((a, b) =>
          (b.focusScore + b.activityScore).compareTo(a.focusScore + a.activityScore));
      return important.take(8).toList();
    }

    return important;
  }

  /// 폴백 추천 생성
  MusicRecommendation _getFallbackRecommendation(TimeSlotAnalysis slot) {
    if (slot.mentalState == MentalState.focused &&
        slot.physicalState == PhysicalState.inactive) {
      return _getFocusMusic(slot);
    } else if (slot.physicalState == PhysicalState.active) {
      return _getActiveMusic(slot);
    } else if (slot.mentalState == MentalState.relaxed) {
      return _getRelaxMusic(slot);
    } else {
      return _getNeutralMusic(slot);
    }
  }

  /// 시간대별 음악 추천
  MusicRecommendation? _recommendForTimeSlot(TimeSlotAnalysis slot) {
    // 집중 + 비활발 = 집중 음악
    if (slot.mentalState == MentalState.focused && 
        slot.physicalState == PhysicalState.inactive) {
      return _getFocusMusic(slot);
    }
    
    // 활발 = 에너지 음악
    if (slot.physicalState == PhysicalState.active) {
      return _getActiveMusic(slot);
    }
    
    // 휴식 = 편안한 음악
    if (slot.mentalState == MentalState.relaxed) {
      return _getRelaxMusic(slot);
    }
    
    // 중립 상태 = 일반 음악
    if (slot.mentalState == MentalState.neutral && 
        slot.physicalState == PhysicalState.moderate) {
      return _getNeutralMusic(slot);
    }

    return null;
  }

  /// 집중 음악 추천
  MusicRecommendation _getFocusMusic(TimeSlotAnalysis slot) {
    final focusPlaylist = [
      {
        'title': 'Deep Focus',
        'artist': 'Spotify',
        'genre': 'Lo-Fi Hip Hop',
        'reasoning': '집중이 필요한 시간입니다. 산만함을 줄이고 집중력을 높이는 Lo-Fi 음악을 추천합니다.',
      },
      {
        'title': 'Peaceful Piano',
        'artist': 'Ambient Piano',
        'genre': 'Classical',
        'reasoning': '조용한 피아노 음악이 집중에 도움이 됩니다.',
      },
      {
        'title': 'Study Beats',
        'artist': 'Chill Beats',
        'genre': 'Instrumental',
        'reasoning': '공부와 작업에 최적화된 비트 음악입니다.',
      },
    ];

    final selected = focusPlaylist[slot.timeSlot.hour % focusPlaylist.length];
    
    return MusicRecommendation(
      id: 'focus-${slot.timeSlot.hour}',
      title: selected['title'] as String,
      artist: selected['artist'] as String,
      genre: selected['genre'] as String,
      reasoning: selected['reasoning'] as String,
      recommendedFor: slot,
    );
  }

  /// 활발한 활동 음악 추천
  MusicRecommendation _getActiveMusic(TimeSlotAnalysis slot) {
    final activePlaylist = [
      {
        'title': 'Workout Mix',
        'artist': 'Energy Boost',
        'genre': 'Electronic',
        'reasoning': '활발한 활동에 맞는 고에너지 음악입니다.',
      },
      {
        'title': 'Running Beats',
        'artist': 'Cardio Mix',
        'genre': 'Pop',
        'reasoning': '운동과 활동에 최적화된 리듬감 있는 음악입니다.',
      },
      {
        'title': 'Power Up',
        'artist': 'Motivation',
        'genre': 'Rock',
        'reasoning': '에너지를 높이고 동기부여를 주는 음악입니다.',
      },
    ];

    final selected = activePlaylist[slot.timeSlot.hour % activePlaylist.length];
    
    return MusicRecommendation(
      id: 'active-${slot.timeSlot.hour}',
      title: selected['title'] as String,
      artist: selected['artist'] as String,
      genre: selected['genre'] as String,
      reasoning: selected['reasoning'] as String,
      recommendedFor: slot,
    );
  }

  /// 휴식 음악 추천
  MusicRecommendation _getRelaxMusic(TimeSlotAnalysis slot) {
    final relaxPlaylist = [
      {
        'title': 'Peaceful Sleep',
        'artist': 'Nature Sounds',
        'genre': 'Ambient',
        'reasoning': '마음을 진정시키고 휴식을 돕는 자연 소리입니다.',
      },
      {
        'title': 'Calm Meditation',
        'artist': 'Zen Music',
        'genre': 'Meditation',
        'reasoning': '명상과 휴식에 최적화된 차분한 음악입니다.',
      },
      {
        'title': 'Soft Jazz',
        'artist': 'Smooth Jazz',
        'genre': 'Jazz',
        'reasoning': '편안한 재즈 음악으로 휴식을 즐기세요.',
      },
    ];

    final selected = relaxPlaylist[slot.timeSlot.hour % relaxPlaylist.length];
    
    return MusicRecommendation(
      id: 'relax-${slot.timeSlot.hour}',
      title: selected['title'] as String,
      artist: selected['artist'] as String,
      genre: selected['genre'] as String,
      reasoning: selected['reasoning'] as String,
      recommendedFor: slot,
    );
  }

  /// 중립 상태 음악 추천
  MusicRecommendation _getNeutralMusic(TimeSlotAnalysis slot) {
    return MusicRecommendation(
      id: 'neutral-${slot.timeSlot.hour}',
      title: 'Daily Mix',
      artist: 'Personalized',
      genre: 'Mixed',
      reasoning: '일상적인 활동에 어울리는 다양한 장르의 음악입니다.',
      recommendedFor: slot,
    );
  }

  /// 시간대별 추천 음악 요약
  Map<String, List<MusicRecommendation>> groupByTimeOfDay(
    List<MusicRecommendation> recommendations,
  ) {
    final grouped = <String, List<MusicRecommendation>>{
      'morning': [],
      'afternoon': [],
      'evening': [],
      'night': [],
    };

    for (var rec in recommendations) {
      final hour = rec.recommendedFor?.timeSlot.hour ?? 12;
      
      if (hour >= 6 && hour < 12) {
        grouped['morning']!.add(rec);
      } else if (hour >= 12 && hour < 18) {
        grouped['afternoon']!.add(rec);
      } else if (hour >= 18 && hour < 22) {
        grouped['evening']!.add(rec);
      } else {
        grouped['night']!.add(rec);
      }
    }

    return grouped;
  }
}


