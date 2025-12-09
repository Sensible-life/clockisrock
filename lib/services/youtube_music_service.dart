import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/analysis_result.dart';

/// YouTube Music 연동 서비스
///
/// YouTube Data API v3를 사용하여 음악 추천을 검색합니다.
/// API Key는 환경 변수나 설정에서 가져와야 합니다.
class YouTubeMusicService {
  final String apiKey;
  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3';

  YouTubeMusicService({required this.apiKey});

  /// 분석 결과 기반 음악 검색
  Future<List<MusicRecommendation>> searchMusicForAnalysis(
    TimeSlotAnalysis analysis,
  ) async {
    // 1. 분석 결과를 기반으로 검색 쿼리 생성
    final searchQuery = _buildSearchQuery(analysis);

    // 2. YouTube에서 음악 검색
    final searchResults = await _searchYouTubeMusic(searchQuery);

    // 3. 검색 결과를 MusicRecommendation으로 변환
    return _convertToRecommendations(searchResults, analysis);
  }

  /// 4분면 기반 음악 검색 (여러 장르/태그 조합)
  Future<List<MusicRecommendation>> searchMusicByQuadrant({
    required double focusScore,
    required double activityScore,
    required TimeSlotAnalysis analysis,
  }) async {
    final genres = _getGenresForQuadrant(focusScore, activityScore);
    final moods = _getMoodsForQuadrant(focusScore, activityScore);

    final allRecommendations = <MusicRecommendation>[];

    // 각 장르별로 검색 (최대 2개 장르)
    for (int i = 0; i < genres.length && i < 2; i++) {
      final genre = genres[i];
      final mood = moods.isNotEmpty ? moods[i % moods.length] : '';
      final query = '$genre $mood music';

      try {
        final results = await _searchYouTubeMusic(query, maxResults: 3);
        allRecommendations.addAll(
          _convertToRecommendations(results, analysis, genre: genre),
        );
      } catch (e) {
        print('Error searching for $query: $e');
      }
    }

    return allRecommendations;
  }

  /// 분석 결과를 기반으로 검색 쿼리 생성
  String _buildSearchQuery(TimeSlotAnalysis analysis) {
    final queryParts = <String>[];

    // 1. Mental state 기반
    switch (analysis.mentalState) {
      case MentalState.focused:
        queryParts.add('focus concentration study');
        break;
      case MentalState.relaxed:
        queryParts.add('relaxation chill ambient');
        break;
      case MentalState.neutral:
        queryParts.add('background music');
        break;
    }

    // 2. Physical state 기반
    switch (analysis.physicalState) {
      case PhysicalState.active:
        queryParts.add('workout energy upbeat');
        break;
      case PhysicalState.inactive:
        queryParts.add('calm peaceful');
        break;
      case PhysicalState.moderate:
        queryParts.add('moderate tempo');
        break;
    }

    // 3. 앱 카테고리 기반
    switch (analysis.appCategory) {
      case AppCategory.productivity:
        queryParts.add('productivity lofi');
        break;
      case AppCategory.creative:
        queryParts.add('creative inspiration');
        break;
      case AppCategory.entertainment:
        queryParts.add('entertainment playlist');
        break;
      default:
        break;
    }

    // 4. 시간대 기반
    switch (analysis.timeOfDay) {
      case TimeOfDay.morning:
        queryParts.add('morning');
        break;
      case TimeOfDay.evening:
        queryParts.add('evening');
        break;
      case TimeOfDay.night:
        queryParts.add('night sleep');
        break;
      default:
        break;
    }

    return '${queryParts.join(' ')} music';
  }

  /// 4분면 기반 장르 선택
  List<String> _getGenresForQuadrant(double focus, double activity) {
    // Focus High + Activity Low (집중/비활발) - Q1
    if (focus > 0.6 && activity < 0.4) {
      return ['lo-fi hip hop', 'classical piano', 'ambient electronic', 'study beats'];
    }

    // Focus High + Activity High (집중/활발) - Q2
    else if (focus > 0.6 && activity > 0.6) {
      return ['upbeat electronic', 'indie rock', 'pop rock', 'energetic instrumental'];
    }

    // Focus Low + Activity High (휴식/활발) - Q3
    else if (focus < 0.4 && activity > 0.6) {
      return ['workout mix', 'edm', 'pop hits', 'dance music'];
    }

    // Focus Low + Activity Low (휴식/비활발) - Q4
    else if (focus < 0.4 && activity < 0.4) {
      return ['ambient', 'nature sounds', 'meditation', 'soft jazz'];
    }

    // 중간 영역
    else {
      return ['indie', 'acoustic', 'chill', 'background music'];
    }
  }

  /// 4분면 기반 무드 선택
  List<String> _getMoodsForQuadrant(double focus, double activity) {
    if (focus > 0.6 && activity < 0.4) {
      return ['focused', 'concentrated', 'deep work'];
    } else if (focus > 0.6 && activity > 0.6) {
      return ['energetic', 'motivated', 'productive'];
    } else if (focus < 0.4 && activity > 0.6) {
      return ['active', 'dynamic', 'powerful'];
    } else if (focus < 0.4 && activity < 0.4) {
      return ['relaxed', 'peaceful', 'calm'];
    } else {
      return ['balanced', 'moderate'];
    }
  }

  /// YouTube Music 검색 (YouTube Data API v3 사용)
  /// 개별 음원만 검색하도록 최적화됨 (플레이리스트 제외)
  Future<List<Map<String, dynamic>>> _searchYouTubeMusic(
    String query, {
    int maxResults = 5,
  }) async {
    try {
      // 개별 음원 검색을 위한 쿼리 (플레이리스트 키워드 제외)
      final musicQuery = '$query song official audio';

      final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: {
        'part': 'snippet',
        'q': musicQuery,
        'type': 'video',
        'videoCategoryId': '10', // Music category (음악 카테고리)
        'videoEmbeddable': 'true', // 임베드 가능한 비디오만 (대부분 공식 음악)
        'videoDuration': 'medium', // 4-20분 영상만 (개별 음원 길이, 플레이리스트 제외)
        'order': 'viewCount', // 조회수 순 정렬 (인기 있는 노래 우선)
        'maxResults': (maxResults * 2).toString(), // 필터링 후 충분한 결과를 위해 2배 요청
        'key': apiKey,
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List<dynamic>? ?? [];

        // 개별 음원만 필터링 (플레이리스트, 컴필레이션 제외)
        final filteredItems = items.where((item) {
          final title = (item['snippet']['title'] as String).toLowerCase();
          final description = (item['snippet']['description'] as String? ?? '').toLowerCase();

          // 1. 플레이리스트/컴필레이션 키워드 제외
          final isNotPlaylist = !title.contains('playlist') &&
              !title.contains('compilation') &&
              !title.contains('mix') &&
              !title.contains('hours') &&
              !title.contains('hour') &&
              !title.contains('best of') &&
              !title.contains('top 10') &&
              !title.contains('top 20') &&
              !title.contains('collection') &&
              !title.contains('full album') &&
              !title.contains('full ep') &&
              !RegExp(r'\d+\s*hours?').hasMatch(title) && // "1 hour", "2 hours" 등
              !RegExp(r'\d+h').hasMatch(title); // "1h", "2h" 등

          // 2. 일반 동영상 제외 (음악 관련 아님)
          final isNotVlog = !title.contains('vlog') &&
              !title.contains('reaction') &&
              !title.contains('review') &&
              !title.contains('tutorial') &&
              !title.contains('unboxing') &&
              !title.contains('cover') && // 커버곡도 제외 (공식 음원 우선)
              !title.contains('behind') &&
              !title.contains('making');

          // 3. 음악 관련 키워드가 있는지 확인
          final hasMusicKeywords = title.contains('official') ||
              title.contains('audio') ||
              title.contains('music video') ||
              title.contains('mv') ||
              title.contains('lyrics') ||
              description.contains('official');

          return isNotPlaylist && isNotVlog && hasMusicKeywords;
        }).toList();

        // maxResults만큼만 반환
        return filteredItems.take(maxResults).map((item) => {
              'id': item['id']['videoId'] as String,
              'title': item['snippet']['title'] as String,
              'description': item['snippet']['description'] as String? ?? '',
              'thumbnailUrl': item['snippet']['thumbnails']['default']['url'] as String? ?? '',
              'channelTitle': item['snippet']['channelTitle'] as String? ?? '',
            }).toList();
      } else {
        print('YouTube API Error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error searching YouTube Music: $e');
      return [];
    }
  }

  /// 검색 결과를 MusicRecommendation으로 변환
  List<MusicRecommendation> _convertToRecommendations(
    List<Map<String, dynamic>> searchResults,
    TimeSlotAnalysis analysis, {
    String? genre,
  }) {
    final recommendations = <MusicRecommendation>[];

    for (int i = 0; i < searchResults.length; i++) {
      final result = searchResults[i];
      final title = result['title'] as String;
      final videoId = result['id'] as String;

      // 아티스트 추출 (우선순위: channelTitle > 타이틀에서 추출)
      String artist = 'Various Artists';

      // 1. YouTube 채널명 사용 (대부분 아티스트 공식 채널)
      final channelTitle = result['channelTitle'] as String?;
      if (channelTitle != null && channelTitle.isNotEmpty) {
        // "VEVO", "Official" 등 제거
        artist = channelTitle
            .replaceAll(' - Topic', '')
            .replaceAll('VEVO', '')
            .replaceAll('Official', '')
            .replaceAll('official', '')
            .trim();
      }

      // 2. 채널명이 없거나 부적절하면 타이틀에서 추출
      if (artist == 'Various Artists' || artist.isEmpty) {
        if (title.contains('-')) {
          final parts = title.split('-');
          if (parts.length >= 2) {
            artist = parts[0].trim();
          }
        }
      }

      // 장르 결정
      final detectedGenre = genre ?? _detectGenreFromTitle(title);

      // 추천 이유 생성
      final reasoning = _generateReasoning(analysis, detectedGenre);

      recommendations.add(
        MusicRecommendation(
          id: 'youtube-${analysis.timeSlot.hour}-$i',
          title: title,
          artist: artist,
          genre: detectedGenre,
          youtubeId: videoId,
          reasoning: reasoning,
          recommendedFor: analysis,
        ),
      );
    }

    return recommendations;
  }

  /// 타이틀에서 장르 감지
  String _detectGenreFromTitle(String title) {
    final lowerTitle = title.toLowerCase();

    if (lowerTitle.contains('lo-fi') || lowerTitle.contains('lofi')) {
      return 'Lo-Fi Hip Hop';
    } else if (lowerTitle.contains('classical')) {
      return 'Classical';
    } else if (lowerTitle.contains('jazz')) {
      return 'Jazz';
    } else if (lowerTitle.contains('ambient')) {
      return 'Ambient';
    } else if (lowerTitle.contains('electronic') || lowerTitle.contains('edm')) {
      return 'Electronic';
    } else if (lowerTitle.contains('rock')) {
      return 'Rock';
    } else if (lowerTitle.contains('pop')) {
      return 'Pop';
    } else if (lowerTitle.contains('meditation')) {
      return 'Meditation';
    } else if (lowerTitle.contains('workout')) {
      return 'Workout';
    } else {
      return 'Mixed';
    }
  }

  /// 추천 이유 생성
  String _generateReasoning(TimeSlotAnalysis analysis, String genre) {
    final reasons = <String>[];

    // 1. 상태 기반 이유
    if (analysis.mentalState == MentalState.focused) {
      reasons.add('집중이 필요한 시간입니다');
    } else if (analysis.mentalState == MentalState.relaxed) {
      reasons.add('휴식이 필요한 시간입니다');
    }

    if (analysis.physicalState == PhysicalState.active) {
      reasons.add('활발한 활동 중입니다');
    } else if (analysis.physicalState == PhysicalState.inactive) {
      reasons.add('조용히 쉬고 있습니다');
    }

    // 2. 시간대 기반 이유
    switch (analysis.timeOfDay) {
      case TimeOfDay.morning:
        reasons.add('아침 시간에 어울리는');
        break;
      case TimeOfDay.evening:
        reasons.add('저녁 시간에 적합한');
        break;
      case TimeOfDay.night:
        reasons.add('밤 시간 편안한');
        break;
      default:
        break;
    }

    // 3. 장르 설명
    reasons.add('$genre 음악을 추천합니다');

    return reasons.join(' ');
  }

  /// 폴백 추천 (API 실패 시)
  List<MusicRecommendation> getFallbackRecommendations(
    TimeSlotAnalysis analysis,
  ) {
    final fallbackPlaylists = [
      {
        'title': 'Focus Flow - Deep Work Mix',
        'artist': 'Lofi Girl',
        'genre': 'Lo-Fi Hip Hop',
        'youtubeId': 'jfKfPfyJRdk',
      },
      {
        'title': 'Peaceful Piano',
        'artist': 'Various Artists',
        'genre': 'Classical',
        'youtubeId': 'lTRiuFIWV54',
      },
      {
        'title': 'Chill Vibes',
        'artist': 'ChilledCow',
        'genre': 'Chill',
        'youtubeId': '5qap5aO4i9A',
      },
    ];

    return fallbackPlaylists
        .map((playlist) => MusicRecommendation(
              id: 'fallback-${analysis.timeSlot.hour}',
              title: playlist['title'] as String,
              artist: playlist['artist'] as String,
              genre: playlist['genre'] as String,
              youtubeId: playlist['youtubeId'] as String,
              reasoning: '추천 시스템이 선정한 음악입니다',
              recommendedFor: analysis,
            ))
        .toList();
  }
}
