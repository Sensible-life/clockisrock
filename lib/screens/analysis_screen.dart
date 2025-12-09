import 'package:flutter/material.dart';
import '../models/analysis_result.dart';
import '../widgets/analysis_chart.dart';
import '../widgets/music_recommendation_card.dart';
import 'package:intl/intl.dart';

/// 분석 결과 화면
class AnalysisScreen extends StatelessWidget {
  final DailyAnalysis analysis;

  const AnalysisScreen({
    super.key,
    required this.analysis,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          DateFormat('yyyy년 MM월 dd일').format(analysis.date),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 차트
            AnalysisChart(timeSlots: analysis.timeSlots),
            
            // 시간대별 상세 분석
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '시간대별 분석',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...analysis.timeSlots.map(
              (slot) => TimeSlotStatusWidget(analysis: slot),
            ),
            
            // 음악 추천
            if (analysis.recommendations.isNotEmpty) ...[
              const SizedBox(height: 16),
              MusicRecommendationList(
                recommendations: analysis.recommendations,
              ),
            ],
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}


