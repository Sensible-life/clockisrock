import 'package:flutter/material.dart';
import 'dart:async';
import '../services/bluetooth_service.dart';
import '../services/rfid_music_mapper.dart';
import '../services/rfid_time_mapper.dart';
import '../services/data_analyzer.dart';
import '../services/screen_data_service.dart';
import '../services/health_data_service.dart';
import '../services/calendar_service.dart';
import '../services/youtube_music_service.dart';
import '../services/music_recommendation_service.dart';
import '../models/analysis_result.dart';
import '../config/api_keys.dart';
import 'youtube_player_screen.dart';

/// RFID 태그 자동 재생 화면
class RfidManagerScreen extends StatefulWidget {
  final BluetoothService bluetoothService;
  final RfidMusicMapper rfidMapper;

  const RfidManagerScreen({
    super.key,
    required this.bluetoothService,
    required this.rfidMapper,
  });

  @override
  State<RfidManagerScreen> createState() => _RfidManagerScreenState();
}

class _RfidManagerScreenState extends State<RfidManagerScreen> {
  StreamSubscription? _messageSubscription;
  String? _lastTaggedUid;
  bool _isAnalyzing = false;
  DailyAnalysis? _currentAnalysis;

  final RfidTimeMapper _timeMapper = RfidTimeMapper();
  final ScreenDataService _screenDataService = ScreenDataService();
  final HealthDataService _healthDataService = HealthDataService();
  final CalendarService _calendarService = CalendarService();

  @override
  void initState() {
    super.initState();
    _listenToArduino();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  void _listenToArduino() {
    _messageSubscription =
        widget.bluetoothService.messageStream.listen((message) {
      print('[Arduino] $message');

      // 버튼 눌림 감지 → 데이터 분석 시작
      if (message == 'BUTTON:PRESSED') {
        _handleButtonPress();
        return;
      }

      // RFID 태그 감지
      if (message.startsWith('TAG:')) {
        final uid = message.substring(4).trim();
        _handleRfidTag(uid);
        return;
      }
    });
  }

  Future<void> _handleButtonPress() async {
    if (_isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🔍 데이터 분석 시작...')),
    );

    try {
      final today = DateTime.now();

      // YouTube Music 서비스 초기화
      MusicRecommendationService? musicService;
      if (ApiKeys.useYoutubeApi &&
          ApiKeys.youtubeApiKey != 'YOUR_YOUTUBE_API_KEY_HERE') {
        final youtubeService = YouTubeMusicService(
          apiKey: ApiKeys.youtubeApiKey,
        );
        musicService = MusicRecommendationService(
          youtubeService: youtubeService,
        );
      }

      // 데이터 분석
      final analyzer = DataAnalyzer(
        screenDataService: _screenDataService,
        healthDataService: _healthDataService,
        calendarService: _calendarService,
        musicService: musicService,
      );

      final analysis = await analyzer.analyzeDate(today);

      setState(() {
        _currentAnalysis = analysis;
        _isAnalyzing = false;
      });

      // 분석 완료 - LED 3번 깜빡임
      await widget.bluetoothService.sendCommand('BLINK:3');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ 분석 완료! 음악 ${analysis.recommendations.length}개 추천',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 분석 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleRfidTag(String uid) async {
    setState(() {
      _lastTaggedUid = uid;
    });

    // UID로 시간대 가져오기
    final hour = _timeMapper.getHourForUid(uid);
    final timeLabel = _timeMapper.getTimeLabel(uid);

    if (hour == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ 알 수 없는 RFID: $uid')),
        );
      }
      return;
    }

    // 분석이 완료되지 않았으면 경고
    if (_currentAnalysis == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ $timeLabel - 먼저 버튼을 눌러 분석을 실행하세요'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // 해당 시간대의 음악 찾기
    final music = _timeMapper.getMusicForHour(_currentAnalysis!, hour);

    if (music == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $timeLabel에 추천할 음악이 없습니다')),
        );
      }
      return;
    }

    // 음악 재생
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎵 $timeLabel 음악 재생: ${music.title}'),
          backgroundColor: Colors.blue,
        ),
      );
    }

    _playMusic(music);
  }

  void _playMusic(MusicRecommendation music) {
    // LED 색상 전송
    final ledColor = widget.rfidMapper.getLedColorForGenre(music.genre);
    widget.bluetoothService.sendLedColor(
      ledColor['r']!,
      ledColor['g']!,
      ledColor['b']!,
    );

    // YouTube 플레이어 화면으로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => YouTubePlayerScreen(
          recommendation: music,
        ),
      ),
    ).then((_) {
      // 플레이어 닫힌 후 LED 끄기
      widget.bluetoothService.clearLed();
    });
  }

  @override
  Widget build(BuildContext context) {
    final timeMappings = _timeMapper.getAllTimeMappings();

    return Scaffold(
      appBar: AppBar(
        title: const Text('RFID 자동 재생'),
        actions: [
          if (_isAnalyzing)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // 연결 상태
          Container(
            padding: const EdgeInsets.all(16),
            color: widget.bluetoothService.isConnected
                ? Colors.green[50]
                : Colors.red[50],
            child: Row(
              children: [
                Icon(
                  widget.bluetoothService.isConnected
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth_disabled,
                  color: widget.bluetoothService.isConnected
                      ? Colors.green
                      : Colors.red,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.bluetoothService.isConnected
                        ? '✅ 아두이노 연결됨'
                        : '❌ 아두이노 연결 안 됨',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: widget.bluetoothService.isConnected
                          ? Colors.green[700]
                          : Colors.red[700],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 분석 상태
          if (_currentAnalysis != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue[50],
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '분석 완료 - 음악 ${_currentAnalysis!.recommendations.length}개 추천됨',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 마지막 태그
          if (_lastTaggedUid != null)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.purple[50],
              child: Row(
                children: [
                  const Icon(Icons.nfc, color: Colors.purple, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '마지막 태그: $_lastTaggedUid (${_timeMapper.getTimeLabel(_lastTaggedUid!)})',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.purple[700],
                    ),
                  ),
                ],
              ),
            ),

          const Divider(),

          // 사용 방법
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 안내 카드
                Card(
                  color: Colors.amber[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.amber[700]),
                            const SizedBox(width: 8),
                            Text(
                              '사용 방법',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[900],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildStep('1', '아두이노 버튼을 누르세요', '데이터 분석이 시작됩니다'),
                        _buildStep('2', 'LED가 3번 깜빡이면 분석 완료', ''),
                        _buildStep('3', 'RFID 카드를 태그하세요', '해당 시간대의 음악이 자동 재생됩니다'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // RFID 매핑 정보
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.nfc, color: Colors.purple),
                            const SizedBox(width: 8),
                            const Text(
                              'RFID 카드 매핑',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...timeMappings.entries.map((entry) {
                          final uid = entry.key;
                          final timeLabel = entry.value;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _lastTaggedUid == uid
                                  ? Colors.purple[50]
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _lastTaggedUid == uid
                                    ? Colors.purple
                                    : Colors.grey[300]!,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.purple,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.nfc,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        timeLabel,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'UID: $uid',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_lastTaggedUid == uid)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.purple,
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.amber[700],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
