// chart_widgets/chart_display.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chart_data.dart';
import '../../utils/chart_colors.dart';

class ChartDisplay extends StatelessWidget {
  final ChartData chartData;
  final bool showUserData;
  final bool showPartnerData;
  final bool isPinkPreference;

  const ChartDisplay({
    required this.chartData,
    required this.showUserData,
    required this.showPartnerData,
    required this.isPinkPreference,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: LineChart(
        LineChartData(
          gridData: _buildGridData(),
          titlesData: _buildTitlesData(),
          borderData: FlBorderData(show: true),
          minX: 0,
          maxX: (chartData.allDates.length - 1).toDouble(),
          minY: 0,
          maxY: 10,
          lineBarsData: _buildLineBarsData(),
          // Add these properties to disable animations
          lineTouchData: LineTouchData(enabled: true),
          showingTooltipIndicators: [],
        ),
        duration: Duration.zero, // Disable the animation duration
        curve: Curves.linear, // Use linear curve for instant transition
      ),
    );
  }

  FlGridData _buildGridData() {
    return FlGridData(
      show: true,
      drawHorizontalLine: true,
      drawVerticalLine: true,
      horizontalInterval: 2,
      verticalInterval: 5,
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: Colors.grey,
          strokeWidth: 1,
          dashArray: [5, 5],
        );
      },
      getDrawingVerticalLine: (value) {
        return FlLine(
          color: Colors.grey,
          strokeWidth: 1,
          dashArray: [5, 5],
        );
      },
    );
  }

  FlTitlesData _buildTitlesData() {
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index >= 0 && index < chartData.allDates.length) {
              final date = DateTime.parse(chartData.allDates[index]);
              final monthKey = DateFormat('MMM').format(date).toLowerCase();
              final dayText = date.day.toString();

              bool showMonth = false;
              if (index == 0) {
                showMonth = true;
              } else {
                DateTime prevDate = DateTime.parse(chartData.allDates[index - 1]);
                if (prevDate.month != date.month) {
                  showMonth = true;
                }
              }

              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(dayText, style: const TextStyle(fontSize: 12)),
                    if (showMonth)
                      Text(
                        monthKey.toUpperCase(),
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
          reservedSize: 50,
          interval: 1,
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 35,
          interval: 2,
        ),
      ),
      topTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      rightTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
    );
  }

  List<LineChartBarData> _buildLineBarsData() {
    final List<LineChartBarData> bars = [];
    final sortedData = List<Map<String, dynamic>>.from(chartData.filteredData)
      ..sort((a, b) => a['date'].toString().compareTo(b['date'].toString()));
    
    final sortedPartnerData = List<Map<String, dynamic>>.from(chartData.filteredPartnerData)
      ..sort((a, b) => a['date'].toString().compareTo(b['date'].toString()));

    if (showUserData) {
      bars.add(
        LineChartBarData(
          spots: List.generate(
            chartData.allDates.length,
            (index) {
              final date = chartData.allDates[index];
              final dataPoint = sortedData.firstWhere(
                (d) => d['date'].toString() == date,
                orElse: () => {'rating': null},
              );
              if (dataPoint['rating'] != null) {
                return FlSpot(
                  index.toDouble(),
                  (dataPoint['rating'] as num).toDouble(),
                );
              }
              return FlSpot.nullSpot;
            },
          ),
          isCurved: false,
          color: ChartColors.getUserColor(isPinkPreference),
          barWidth: 3,
          dotData: FlDotData(show: true),
          belowBarData: BarAreaData(show: false),
        ),
      );
    }

    if (sortedPartnerData.isNotEmpty && showPartnerData) {
      bars.add(
        LineChartBarData(
          spots: List.generate(
            chartData.allDates.length,
            (index) {
              final date = chartData.allDates[index];
              final dataPoint = sortedPartnerData.firstWhere(
                (d) => d['date'].toString() == date,
                orElse: () => {'rating': null},
              );
              if (dataPoint['rating'] != null) {
                return FlSpot(
                  index.toDouble(),
                  (dataPoint['rating'] as num).toDouble(),
                );
              }
              return FlSpot.nullSpot;
            },
          ),
          isCurved: false,
          color: ChartColors.getPartnerColor(isPinkPreference),
          barWidth: 3,
          dotData: FlDotData(show: true),
          belowBarData: BarAreaData(show: false),
        ),
      );
    }

    return bars;
  }
}