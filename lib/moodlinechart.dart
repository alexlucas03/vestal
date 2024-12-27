import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MoodLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> moodData;

  const MoodLineChart({
    super.key,
    required this.moodData,
  });

  @override
  Widget build(BuildContext context) {
    if (moodData.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('No mood data available'),
        ),
      );
    }

    // Sort the data by date
    final sortedData = List<Map<String, dynamic>>.from(moodData)
      ..sort((a, b) => a['date'].toString().compareTo(b['date'].toString()));

    // Group indices by month
    Map<String, List<int>> monthIndices = {};
    for (int i = 0; i < sortedData.length; i++) {
      final date = DateTime.parse(sortedData[i]['date'].toString());
      final monthKey = DateFormat('MMM').format(date).toLowerCase();
      monthIndices.putIfAbsent(monthKey, () => []).add(i);
    }

    // Calculate center indices for each month
    Map<String, int> monthCenterIndices = {};
    for (var entry in monthIndices.entries) {
      if (entry.value.isNotEmpty) {
        monthCenterIndices[entry.key] = entry.value[(entry.value.length - 1) ~/ 2];
      }
    }

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            drawVerticalLine: true,
            horizontalInterval: 2, // Show grid lines every 2 units on Y-axis
            verticalInterval: 5,   // Show grid lines every 5 units on X-axis
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
                dashArray: [5, 5], // Optional: makes the lines dashed
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
                dashArray: [5, 5], // Optional: makes the lines dashed
              );
            },
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < sortedData.length) {
                    final dateStr = sortedData[index]['date'].toString();
                    final date = DateTime.parse(dateStr);
                    final monthKey = DateFormat('MMM').format(date).toLowerCase();
                    final dayText = date.day.toString();
                    final isMonthCenter = monthCenterIndices[monthKey] == index;
                    
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(dayText, style: const TextStyle(fontSize: 12)),
                        if (isMonthCenter)
                          Text(
                            monthKey.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        if (!isMonthCenter)
                          const SizedBox(height: 14),
                      ],
                    );
                  }
                  return const Text('');
                },
                reservedSize: 40,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 2,
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: true),
          minX: 0,
          maxX: (sortedData.length - 1).toDouble(),
          minY: 0,
          maxY: 10,
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                sortedData.length,
                (index) => FlSpot(
                  index.toDouble(),
                  (sortedData[index]['rating'] as num).toDouble(),
                ),
              ),
              isCurved: true,
              color: const Color(0xFF3A4C7A),
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF3A4C7A).withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}