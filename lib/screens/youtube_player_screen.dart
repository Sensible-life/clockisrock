import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/analysis_result.dart';

/// YouTube 플레이어 화면
class YouTubePlayerScreen extends StatefulWidget {
  final MusicRecommendation recommendation;

  const YouTubePlayerScreen({
    super.key,
    required this.recommendation,
  });

  @override
  State<YouTubePlayerScreen> createState() => _YouTubePlayerScreenState();
}

class _YouTubePlayerScreenState extends State<YouTubePlayerScreen> {
  late YoutubePlayerController _controller;
  bool _isPlayerReady = false;

  @override
  void initState() {
    super.initState();

    // YouTube 컨트롤러 초기화
    final videoId = widget.recommendation.youtubeId ?? '';

    if (videoId.isEmpty) {
      // videoId가 없으면 에러 표시
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('YouTube ID가 없습니다')),
          );
          Navigator.pop(context);
        }
      });
      return;
    }

    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: false,
        hideThumbnail: false,
        hideControls: false,
        forceHD: false,
      ),
    )..addListener(_listener);
  }

  void _listener() {
    if (_isPlayerReady && mounted && !_controller.value.isFullScreen) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    if (widget.recommendation.youtubeId != null &&
        widget.recommendation.youtubeId!.isNotEmpty) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // videoId가 없으면 빈 화면 반환
    if (widget.recommendation.youtubeId == null ||
        widget.recommendation.youtubeId!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('음악 재생')),
        body: const Center(
          child: Text('YouTube ID가 없습니다'),
        ),
      );
    }

    return YoutubePlayerBuilder(
      onExitFullScreen: () {
        // 전체화면 종료 시 세로 모드로 복귀
        SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      },
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.red,
        progressColors: const ProgressBarColors(
          playedColor: Colors.red,
          handleColor: Colors.redAccent,
        ),
        onReady: () {
          _isPlayerReady = true;
          if (mounted) {
            setState(() {});
          }
        },
        onEnded: (data) {
          // 재생 완료 시
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('재생이 완료되었습니다')),
          );
        },
      ),
      builder: (context, player) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('음악 재생'),
            actions: [
              IconButton(
                icon: const Icon(Icons.fullscreen),
                onPressed: () {
                  _controller.toggleFullScreenMode();
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // YouTube 플레이어
              player,

              const SizedBox(height: 16),

              // 음악 정보
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 제목
                      Text(
                        widget.recommendation.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 아티스트
                      Row(
                        children: [
                          const Icon(Icons.person, size: 20, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.recommendation.artist,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 장르
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getGenreColor(widget.recommendation.genre)
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          widget.recommendation.genre,
                          style: TextStyle(
                            fontSize: 14,
                            color: _getGenreColor(widget.recommendation.genre),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // 추천 이유
                      if (widget.recommendation.reasoning.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text(
                          '추천 이유',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                size: 24,
                                color: Colors.amber[700],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.recommendation.reasoning,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // 추천 시간
                      if (widget.recommendation.recommendedFor != null) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(Icons.schedule, size: 20, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              '추천 시간: ${widget.recommendation.recommendedFor!.timeSlot.hour}시',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
