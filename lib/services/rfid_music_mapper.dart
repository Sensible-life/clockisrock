import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/analysis_result.dart';

/// RFID UID와 음악 추천을 매핑하는 서비스
class RfidMusicMapper {
  static const String _storageKey = 'rfid_music_mappings';

  /// RFID UID에 음악 추천 매핑
  Future<void> mapMusicToRfid(String uid, MusicRecommendation music) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mappings = await _getMappings();

      mappings[uid] = {
        'id': music.id,
        'title': music.title,
        'artist': music.artist,
        'genre': music.genre,
        'youtubeId': music.youtubeId,
        'album': music.album,
        'reasoning': music.reasoning,
      };

      await prefs.setString(_storageKey, json.encode(mappings));
      print('Mapped RFID $uid to ${music.title}');
    } catch (e) {
      print('Error mapping music to RFID: $e');
    }
  }

  /// RFID UID로 음악 추천 가져오기
  Future<MusicRecommendation?> getMusicForRfid(String uid) async {
    try {
      final mappings = await _getMappings();
      final musicData = mappings[uid];

      if (musicData == null) {
        print('No music mapped to RFID $uid');
        return null;
      }

      return MusicRecommendation(
        id: musicData['id'] as String? ?? uid,
        title: musicData['title'] as String,
        artist: musicData['artist'] as String,
        genre: musicData['genre'] as String,
        youtubeId: musicData['youtubeId'] as String?,
        album: musicData['album'] as String?,
        reasoning: musicData['reasoning'] as String? ?? '',
        recommendedFor: null,
      );
    } catch (e) {
      print('Error getting music for RFID: $e');
      return null;
    }
  }

  /// 모든 RFID 매핑 가져오기
  Future<Map<String, MusicRecommendation>> getAllMappings() async {
    try {
      final mappings = await _getMappings();
      final result = <String, MusicRecommendation>{};

      mappings.forEach((uid, musicData) {
        result[uid] = MusicRecommendation(
          id: musicData['id'] as String? ?? uid,
          title: musicData['title'] as String,
          artist: musicData['artist'] as String,
          genre: musicData['genre'] as String,
          youtubeId: musicData['youtubeId'] as String?,
          album: musicData['album'] as String?,
          reasoning: musicData['reasoning'] as String? ?? '',
          recommendedFor: null,
        );
      });

      return result;
    } catch (e) {
      print('Error getting all mappings: $e');
      return {};
    }
  }

  /// RFID 매핑 삭제
  Future<void> removeMappingForRfid(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mappings = await _getMappings();

      mappings.remove(uid);
      await prefs.setString(_storageKey, json.encode(mappings));
      print('Removed mapping for RFID $uid');
    } catch (e) {
      print('Error removing RFID mapping: $e');
    }
  }

  /// 모든 RFID 매핑 삭제
  Future<void> clearAllMappings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      print('Cleared all RFID mappings');
    } catch (e) {
      print('Error clearing RFID mappings: $e');
    }
  }

  /// 내부: SharedPreferences에서 매핑 데이터 가져오기
  Future<Map<String, dynamic>> _getMappings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString == null) {
        return {};
      }

      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('Error getting mappings from storage: $e');
      return {};
    }
  }

  /// 장르에 따른 LED 색상 계산
  Map<String, int> getLedColorForGenre(String genre) {
    final genreLower = genre.toLowerCase();

    // 장르별 LED 색상 매핑
    if (genreLower.contains('lo-fi') || genreLower.contains('hip hop')) {
      return {'r': 128, 'g': 0, 'b': 128}; // Purple
    } else if (genreLower.contains('electronic') || genreLower.contains('pop')) {
      return {'r': 255, 'g': 165, 'b': 0}; // Orange
    } else if (genreLower.contains('ambient') || genreLower.contains('meditation')) {
      return {'r': 0, 'g': 128, 'b': 128}; // Teal
    } else if (genreLower.contains('jazz')) {
      return {'r': 139, 'g': 69, 'b': 19}; // Brown
    } else if (genreLower.contains('rock')) {
      return {'r': 255, 'g': 0, 'b': 0}; // Red
    } else if (genreLower.contains('classical')) {
      return {'r': 75, 'g': 0, 'b': 130}; // Indigo
    } else {
      return {'r': 0, 'g': 100, 'b': 255}; // Blue (기본)
    }
  }
}
