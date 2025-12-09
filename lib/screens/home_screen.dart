import 'package:flutter/material.dart';
import '../services/screen_data_service.dart';
import '../services/health_data_service.dart';
import '../services/calendar_service.dart';
import '../services/data_analyzer.dart';
import '../services/youtube_music_service.dart';
import '../services/music_recommendation_service.dart';
import '../screens/analysis_screen.dart';
import '../models/screen_data.dart';
import '../config/api_keys.dart';
import 'package:intl/intl.dart';

/// 홈 화면
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScreenDataService _screenDataService = ScreenDataService();
  final HealthDataService _healthDataService = HealthDataService();
  final CalendarService _calendarService = CalendarService();

  bool _isLoading = false;
  String? _errorMessage;
  bool _isCalendarAuthenticated = false;
  List<ScreenUsageSummary>? _todayScreenData;
  bool _isLoadingScreenData = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadTodayScreenData();
  }

  Future<void> _loadTodayScreenData() async {
    setState(() {
      _isLoadingScreenData = true;
    });

    try {
      final today = DateTime.now();
      final summaries = await _screenDataService.getScreenUsageByTimeSlot(today);
      setState(() {
        _todayScreenData = summaries;
      });
    } catch (e) {
      // ignore: avoid_print
      print('스크린타임 데이터 로드 오류: $e');
    } finally {
      setState(() {
        _isLoadingScreenData = false;
      });
    }
  }

  Future<void> _checkPermissions() async {
    // 권한 확인 및 요청
    final screenPermission = await _screenDataService.requestPermission();
    if (!screenPermission) {
      setState(() {
        _errorMessage = 'Usage Stats 권한이 필요합니다. 설정에서 권한을 허용해주세요.';
      });
    }

    // Health Connect 설치 확인
    final healthConnectAvailable = await _healthDataService.isHealthConnectAvailable();
    if (!healthConnectAvailable) {
      setState(() {
        _errorMessage = (_errorMessage ?? '') +
            '\n\nHealth Connect 앱이 설치되어 있지 않습니다.\n'
            'Play Store에서 "Health Connect" 앱을 설치해주세요.\n'
            '삼성 기기의 경우 삼성헬스와 연동이 필요합니다.';
      });
      return;
    }

    final healthPermission = await _healthDataService.requestPermission();
    if (!healthPermission) {
      setState(() {
        _errorMessage = (_errorMessage ?? '') +
            '\n\nHealth Connect 권한이 필요합니다.\n'
            '권한을 승인해주세요.';
      });
    }
  }

  Future<void> _analyzeToday() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final today = DateTime.now();

      // YouTube Music 서비스 초기화 (API 키가 설정되어 있으면)
      MusicRecommendationService? musicService;
      if (ApiKeys.useYoutubeApi && ApiKeys.youtubeApiKey != 'YOUR_YOUTUBE_API_KEY_HERE') {
        final youtubeService = YouTubeMusicService(
          apiKey: ApiKeys.youtubeApiKey,
        );
        musicService = MusicRecommendationService(
          youtubeService: youtubeService,
        );
      }

      final analyzer = DataAnalyzer(
        screenDataService: _screenDataService,
        healthDataService: _healthDataService,
        calendarService: _calendarService,
        musicService: musicService, // YouTube 서비스 전달
      );

      final analysis = await analyzer.analyzeDate(today);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AnalysisScreen(analysis: analysis),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = '분석 중 오류가 발생했습니다: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openUsageStatsSettings() async {
    await _screenDataService.openUsageStatsSettings();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await _calendarService.authenticate();
      setState(() {
        _isCalendarAuthenticated = success;
        if (!success) {
          _errorMessage = '구글 캘린더 로그인에 실패했습니다.';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = '구글 캘린더 로그인 오류: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOutFromGoogle() async {
    await _calendarService.signOut();
    setState(() {
      _isCalendarAuthenticated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ClockisRock'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              // 헤더
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.music_note,
                        size: 64,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '당신의 하루를 음악으로',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '스마트폰 사용, 건강 데이터, 캘린더를 분석하여\n최적의 음악을 추천해드립니다',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 분석 버튼
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _analyzeToday,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.analytics),
                label: Text(_isLoading ? '분석 중...' : '오늘 분석하기'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 권한 설정 버튼
              OutlinedButton.icon(
                onPressed: _openUsageStatsSettings,
                icon: const Icon(Icons.settings),
                label: const Text('Usage Stats 권한 설정'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),

              const SizedBox(height: 16),

              // 구글 캘린더 연동 버튼
              _isCalendarAuthenticated
                  ? OutlinedButton.icon(
                      onPressed: _signOutFromGoogle,
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      label: const Text('구글 캘린더 연동됨'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.green),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: _isLoading ? null : _signInWithGoogle,
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('구글 캘린더 연동하기'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 2,
                      ),
                    ),
              
              const SizedBox(height: 24),

              // 스크린타임 데이터 표시 (디버그용)
              _buildScreenTimeDebugCard(),

              const SizedBox(height: 16),

              // 오류 메시지
              if (_errorMessage != null)
                Card(
                  color: Colors.red[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red[700]),
                            const SizedBox(width: 8),
                            Text(
                              '권한 필요',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // 정보 카드
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text(
                            '분석 데이터',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoItem('스마트폰 사용 시간 및 앱'),
                      _buildInfoItem('삼성 헬스 / Health Connect 데이터'),
                      _buildInfoItem('구글 캘린더 이벤트'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildScreenTimeDebugCard() {
    return ExpansionTile(
      title: Row(
        children: [
          Icon(Icons.phone_android, color: Colors.purple[700]),
          const SizedBox(width: 8),
          const Text(
            '스크린타임 데이터 확인',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      subtitle: _isLoadingScreenData
          ? const Text('로딩 중...')
          : _todayScreenData != null
              ? Text('${_todayScreenData!.length}개 시간대 데이터 수집됨')
              : const Text('데이터 없음'),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: _isLoadingScreenData
              ? const Center(child: CircularProgressIndicator())
              : _todayScreenData == null || _todayScreenData!.isEmpty
                  ? Column(
                      children: [
                        const Text(
                          '스크린타임 데이터가 없습니다.\n권한을 확인하고 새로고침 해주세요.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadTodayScreenData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('새로고침'),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildScreenDataSummary(),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadTodayScreenData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('새로고침'),
                        ),
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _buildScreenDataSummary() {
    if (_todayScreenData == null || _todayScreenData!.isEmpty) {
      return const SizedBox.shrink();
    }

    // 전체 사용 시간 계산
    Duration totalUsage = Duration.zero;
    final allApps = <String, Duration>{};

    for (var summary in _todayScreenData!) {
      totalUsage += summary.totalUsage;
      for (var appData in summary.appUsages) {
        allApps[appData.appName] = (allApps[appData.appName] ?? Duration.zero) + appData.usageTime;
      }
    }

    // 사용 시간 순으로 정렬
    final sortedApps = allApps.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 총 사용 시간
        Card(
          color: Colors.purple[50],
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '총 스크린타임',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  _formatDuration(totalUsage),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[700],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 앱 개수
        Text(
          '사용한 앱: ${allApps.length}개',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),

        // 상위 5개 앱
        if (sortedApps.isNotEmpty) ...[
          const Text(
            '상위 앱 사용 시간:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...sortedApps.take(5).map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatDuration(entry.value),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple[700],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],

        const SizedBox(height: 12),

        // 시간대별 데이터
        Text(
          '시간대별 데이터: ${_todayScreenData!.length}개',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}시간 ${minutes}분';
    } else {
      return '${minutes}분';
    }
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.blue[700]),
            ),
          ),
        ],
      ),
    );
  }
}


