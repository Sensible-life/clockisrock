import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/analysis_result.dart';
import '../models/health_data.dart';
import '../models/screen_data.dart';
import '../models/calendar_data.dart';
import 'package:intl/intl.dart';

/// 시간대별 분석 결과 차트
class AnalysisChart extends StatelessWidget {
  final List<TimeSlotAnalysis> timeSlots;

  const AnalysisChart({
    super.key,
    required this.timeSlots,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '하루 분석 결과',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                _buildChartData(),
              ),
            ),
            const SizedBox(height: 20),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  LineChartData _buildChartData() {
    final focusSpots = <FlSpot>[];
    final activitySpots = <FlSpot>[];

    for (int i = 0; i < timeSlots.length; i++) {
      final slot = timeSlots[i];
      focusSpots.add(FlSpot(i.toDouble(), slot.focusScore));
      activitySpots.add(FlSpot(i.toDouble(), slot.activityScore));
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 0.2,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.withOpacity(0.2),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 4,
            getTitlesWidget: (value, meta) {
              if (value.toInt() % 4 == 0 && value.toInt() < 24) {
                return Text(
                  '${value.toInt()}시',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: 0.2,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      minX: 0,
      maxX: 23,
      minY: 0,
      maxY: 1,
      lineBarsData: [
        LineChartBarData(
          spots: focusSpots,
          isCurved: true,
          color: Colors.blue,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.blue.withOpacity(0.1),
          ),
        ),
        LineChartBarData(
          spots: activitySpots,
          isCurved: true,
          color: Colors.orange,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.orange.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(Colors.blue, '집중도'),
        const SizedBox(width: 20),
        _buildLegendItem(Colors.orange, '활동량'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

/// 시간대별 상태 표시 위젯
class TimeSlotStatusWidget extends StatelessWidget {
  final TimeSlotAnalysis analysis;

  const TimeSlotStatusWidget({
    super.key,
    required this.analysis,
  });

  void _showDetailDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => TimeSlotDetailDialog(analysis: analysis),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showDetailDialog(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${analysis.timeSlot.hour}시',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    _buildStateChip(
                      _getMentalStateText(analysis.mentalState),
                      _getMentalStateColor(analysis.mentalState),
                    ),
                    const SizedBox(width: 8),
                    _buildStateChip(
                      _getPhysicalStateText(analysis.physicalState),
                      _getPhysicalStateColor(analysis.physicalState),
                    ),
                    // 수면 시간이 있으면 수면 표시
                    if (analysis.healthSummary?.isSleeping == true ||
                        (analysis.healthSummary?.totalSleepMinutes ?? 0) > 0) ...[
                      const SizedBox(width: 8),
                      _buildStateChip(
                        '수면',
                        Colors.purple,
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildScoreBar('집중', analysis.focusScore, Colors.blue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildScoreBar('활동', analysis.activityScore, Colors.orange),
                ),
              ],
            ),
            if (analysis.reasoning != null) ...[
              const SizedBox(height: 8),
              Text(
                analysis.reasoning!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildStateChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildScoreBar(String label, double score, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              (score * 100).toInt().toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  String _getMentalStateText(MentalState state) {
    switch (state) {
      case MentalState.focused:
        return '집중';
      case MentalState.relaxed:
        return '휴식';
      case MentalState.neutral:
        return '중립';
    }
  }

  Color _getMentalStateColor(MentalState state) {
    switch (state) {
      case MentalState.focused:
        return Colors.blue;
      case MentalState.relaxed:
        return Colors.green;
      case MentalState.neutral:
        return Colors.grey;
    }
  }

  String _getPhysicalStateText(PhysicalState state) {
    switch (state) {
      case PhysicalState.active:
        return '활발';
      case PhysicalState.inactive:
        return '비활발';
      case PhysicalState.moderate:
        return '보통';
    }
  }

  Color _getPhysicalStateColor(PhysicalState state) {
    switch (state) {
      case PhysicalState.active:
        return Colors.orange;
      case PhysicalState.inactive:
        return Colors.grey;
      case PhysicalState.moderate:
        return Colors.blueGrey;
    }
  }
}

/// 시간대별 상세 정보 다이얼로그
class TimeSlotDetailDialog extends StatelessWidget {
  final TimeSlotAnalysis analysis;

  const TimeSlotDetailDialog({
    super.key,
    required this.analysis,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('HH:mm');

    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${analysis.timeSlot.hour}시 상세 정보',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 20),

              // 상태 정보
              _buildSection(
                '상태',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildStateChip(
                          _getMentalStateText(analysis.mentalState),
                          _getMentalStateColor(analysis.mentalState),
                        ),
                        const SizedBox(width: 8),
                        _buildStateChip(
                          _getPhysicalStateText(analysis.physicalState),
                          _getPhysicalStateColor(analysis.physicalState),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildScoreRow('집중도', analysis.focusScore, Colors.blue),
                    const SizedBox(height: 8),
                    _buildScoreRow('활동량', analysis.activityScore, Colors.orange),
                  ],
                ),
              ),

              // 헬스 데이터
              if (analysis.healthSummary != null) ...[
                const SizedBox(height: 16),
                _buildSection(
                  '건강 데이터',
                  _buildHealthSection(analysis.healthSummary!),
                ),
              ],

              // 스크린타임 데이터
              if (analysis.screenUsage != null) ...[
                const SizedBox(height: 16),
                _buildSection(
                  '스크린 타임',
                  _buildScreenTimeSection(analysis.screenUsage!),
                ),
              ],

              // 캘린더 이벤트
              if (analysis.calendarSummary != null && analysis.calendarSummary!.hasEvent) ...[
                const SizedBox(height: 16),
                _buildSection(
                  '일정',
                  _buildCalendarSection(analysis.calendarSummary!, dateFormat),
                ),
              ],

              // 분석 근거
              if (analysis.reasoning != null) ...[
                const SizedBox(height: 16),
                _buildSection(
                  '분석 근거',
                  Text(
                    analysis.reasoning!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }

  Widget _buildStateChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildScoreRow(String label, double score, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${(score * 100).toInt()}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildHealthSection(HealthSummary health) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDataRow(Icons.directions_walk, '걸음 수', '${health.totalSteps.toInt()} 걸음'),
        if (health.avgHeartRate != null)
          _buildDataRow(Icons.favorite, '평균 심박수', '${health.avgHeartRate!.toInt()} bpm'),
        _buildDataRow(Icons.local_fire_department, '칼로리', '${health.totalCalories.toInt()} kcal'),
        if (health.totalDistance > 0)
          _buildDataRow(Icons.route, '이동 거리', '${(health.totalDistance / 1000).toStringAsFixed(2)} km'),
        if (health.totalSleepMinutes > 0)
          _buildDataRow(Icons.bedtime, '수면 시간', '${(health.totalSleepMinutes).toInt()}분'),
        const SizedBox(height: 8),
        Row(
          children: [
            if (health.isActive)
              Chip(
                label: const Text('활발', style: TextStyle(fontSize: 12)),
                backgroundColor: Colors.orange.withOpacity(0.2),
                side: BorderSide(color: Colors.orange),
              ),
            if (health.isSleeping) ...[
              if (health.isActive) const SizedBox(width: 8),
              Chip(
                label: const Text('수면중', style: TextStyle(fontSize: 12)),
                backgroundColor: Colors.purple.withOpacity(0.2),
                side: BorderSide(color: Colors.purple),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildScreenTimeSection(ScreenUsageSummary screenUsage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDataRow(
          Icons.phone_android,
          '총 사용 시간',
          _formatDuration(screenUsage.totalUsage),
        ),
        if (screenUsage.dominantApp != null)
          _buildDataRow(
            Icons.star,
            '주요 앱',
            screenUsage.dominantApp!,
          ),
        if (screenUsage.appUsages.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text(
            '앱별 사용 시간',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          ...screenUsage.appUsages.take(5).map((app) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        app.appName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _formatDuration(app.usageTime),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildCalendarSection(CalendarSummary calendar, DateFormat dateFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: calendar.events.map((event) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.event, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${dateFormat.format(event.startTime)} - ${dateFormat.format(event.endTime)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              if (event.location != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.location!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (event.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  event.description!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDataRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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

  String _getMentalStateText(MentalState state) {
    switch (state) {
      case MentalState.focused:
        return '집중';
      case MentalState.relaxed:
        return '휴식';
      case MentalState.neutral:
        return '중립';
    }
  }

  Color _getMentalStateColor(MentalState state) {
    switch (state) {
      case MentalState.focused:
        return Colors.blue;
      case MentalState.relaxed:
        return Colors.green;
      case MentalState.neutral:
        return Colors.grey;
    }
  }

  String _getPhysicalStateText(PhysicalState state) {
    switch (state) {
      case PhysicalState.active:
        return '활발';
      case PhysicalState.inactive:
        return '비활발';
      case PhysicalState.moderate:
        return '보통';
    }
  }

  Color _getPhysicalStateColor(PhysicalState state) {
    switch (state) {
      case PhysicalState.active:
        return Colors.orange;
      case PhysicalState.inactive:
        return Colors.grey;
      case PhysicalState.moderate:
        return Colors.blueGrey;
    }
  }
}


