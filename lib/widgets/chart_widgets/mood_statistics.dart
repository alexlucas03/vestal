// chart_widgets/mood_statistics.dart
import 'package:flutter/material.dart';
import '../models/chart_data.dart';
import '../../utils/chart_colors.dart';
import '../../utils/statistics_calculator.dart';

class MoodStatistics extends StatelessWidget {
  final ChartData chartData;
  final bool showUserData;
  final bool showPartnerData;
  final bool isPinkPreference;

  const MoodStatistics({
    required this.chartData,
    required this.showUserData,
    required this.showPartnerData,
    required this.isPinkPreference,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: Color(0xFF3A4C7A), thickness: 1),
          Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: {
              0: const FlexColumnWidth(2),  // Label column
              if (showUserData) 1: const FlexColumnWidth(1),  // User stats
              if (showPartnerData) 2: const FlexColumnWidth(1),  // Partner stats
            },
            children: [
              _buildStatRow(
                'Average Mood:',
                StatisticsCalculator.calculate(chartData.filteredData)['average'],
                StatisticsCalculator.calculate(chartData.filteredPartnerData)['average'],
                format: (value) => value.toStringAsFixed(1),
              ),
              _buildDividerRow(),
              _buildStatRow(
                'Most common:',
                StatisticsCalculator.calculate(chartData.filteredData)['mostCommon'],
                StatisticsCalculator.calculate(chartData.filteredPartnerData)['mostCommon'],
                format: (value) => value.toStringAsFixed(0),
              ),
              _buildDividerRow(),
              _buildStatRow(
                'Longest streak:',
                StatisticsCalculator.calculate(chartData.filteredData)['longestStreak'],
                StatisticsCalculator.calculate(chartData.filteredPartnerData)['longestStreak'],
                format: (value) => value.toStringAsFixed(0),
              ),
              _buildDividerRow(),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _buildStatRow(
    String label,
    dynamic userValue,
    dynamic partnerValue, {
    required String Function(double) format,
  }) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        if (showUserData)
          Text(
            format(userValue.toDouble()),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: ChartColors.getUserColor(isPinkPreference),
            ),
            textAlign: TextAlign.center,
          ),
        if (showPartnerData)
          Text(
            format(partnerValue.toDouble()),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: ChartColors.getPartnerColor(isPinkPreference),
            ),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }

  TableRow _buildDividerRow() {
    return TableRow(
      children: [
        const Divider(color: Color(0xFF3A4C7A), thickness: 1),
        if (showUserData)
          const Divider(color: Color(0xFF3A4C7A), thickness: 1),
        if (showPartnerData)
          const Divider(color: Color(0xFF3A4C7A), thickness: 1),
      ],
    );
  }
}