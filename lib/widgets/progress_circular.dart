import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProgressCircular extends StatelessWidget {
  final double percentage; // 0.0 to 1.0

  const ProgressCircular({
    super.key,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      width: 200,
      child: Stack(
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 0,
              centerSpaceRadius: 70,
              startDegreeOffset: -90,
              sections: [
                PieChartSectionData(
                  color: AppTheme.navy,
                  value: percentage * 100,
                  title: '',
                  radius: 20,
                  showTitle: false,
                ),
                PieChartSectionData(
                  color: AppTheme.mintGreen.withValues(alpha: 0.2),
                  value: (1.0 - percentage) * 100,
                  title: '',
                  radius: 20,
                  showTitle: false,
                ),
              ],
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '学習進捗',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${(percentage * 100).toInt()}%',
                  style: const TextStyle(
                    color: AppTheme.navy,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
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
