import 'package:flutter/material.dart';
import '../models/analysis_result.dart';
import 'package:intl/intl.dart';
import '../screens/youtube_player_screen.dart';

/// 음악 추천 카드 위젯
class MusicRecommendationCard extends StatelessWidget {
  final MusicRecommendation recommendation;

  const MusicRecommendationCard({
    super.key,
    required this.recommendation,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // YouTube 플레이어 화면으로 이동
          if (recommendation.youtubeId != null && recommendation.youtubeId!.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => YouTubePlayerScreen(
                  recommendation: recommendation,
                ),
              ),
            );
          } else {
            // YouTube ID가 없는 경우 (폴백 추천)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('음악 링크가 없습니다')),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _getGenreColor(recommendation.genre),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.music_note,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                recommendation.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (recommendation.youtubeId != null && recommendation.youtubeId!.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          recommendation.artist,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (recommendation.album != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            recommendation.album!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getGenreColor(recommendation.genre).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  recommendation.genre,
                  style: TextStyle(
                    fontSize: 12,
                    color: _getGenreColor(recommendation.genre),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (recommendation.reasoning.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 20,
                        color: Colors.amber[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          recommendation.reasoning,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (recommendation.recommendedFor != null) ...[
                const SizedBox(height: 8),
                Text(
                  '추천 시간: ${recommendation.recommendedFor!.timeSlot.hour}시',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getGenreColor(String genre) {
    final genreLower = genre.toLowerCase();
    if (genreLower.contains('lo-fi') || genreLower.contains('hip hop')) {
      return Colors.purple;
    } else if (genreLower.contains('electronic') || genreLower.contains('pop')) {
      return Colors.orange;
    } else if (genreLower.contains('ambient') || genreLower.contains('meditation')) {
      return Colors.teal;
    } else if (genreLower.contains('jazz')) {
      return Colors.brown;
    } else if (genreLower.contains('rock')) {
      return Colors.red;
    } else if (genreLower.contains('classical')) {
      return Colors.indigo;
    } else {
      return Colors.blue;
    }
  }
}

/// 음악 추천 리스트 위젯
class MusicRecommendationList extends StatelessWidget {
  final List<MusicRecommendation> recommendations;

  const MusicRecommendationList({
    super.key,
    required this.recommendations,
  });

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            '추천할 음악이 없습니다.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '음악 추천 (${recommendations.length}개)',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...recommendations.map(
          (rec) => MusicRecommendationCard(recommendation: rec),
        ),
      ],
    );
  }
}


