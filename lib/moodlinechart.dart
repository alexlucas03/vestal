import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MoodLineChart extends StatefulWidget {
  final List<Map<String, dynamic>> moodData;

  const MoodLineChart({
    super.key,
    required this.moodData,
  });

  @override
  _MoodLineChartState createState() => _MoodLineChartState();
}

class _MoodLineChartState extends State<MoodLineChart> {
  List<Map<String, dynamic>> filteredData = [];
  String selectedFilter = 'all'; // Default filter: 'all'

  @override
  void initState() {
    super.initState();
    filteredData = widget.moodData; // Initially display all data
  }

  // Function to filter data by selected range
  void _filterData(String filter) {
    setState(() {
      selectedFilter = filter;

      DateTime now = DateTime.now();
      DateTime startDate;

      switch (filter) {
        case 'week':
          startDate = now.subtract(Duration(days: 7));
          break;
        case 'month':
          startDate = DateTime(now.year, now.month - 1, now.day);
          break;
        case 'year':
          startDate = DateTime(now.year - 1, now.month, now.day);
          break;
        case 'all':
        default:
          filteredData = widget.moodData;
          return;
      }

      filteredData = widget.moodData.where((data) {
        DateTime date = DateTime.parse(data['date'].toString());
        return date.isAfter(startDate);
      }).toList();
    });
  }

  // Method to calculate the statistics
  Map<String, dynamic> _calculateStatistics() {
    if (filteredData.isEmpty) {
      return {
        'average': 0.0,
        'mostCommon': 0,
        'longestStreak': 0,
      };
    }

    List<double> ratings = filteredData
        .map((data) => (data['rating'] as num).toDouble())
        .toList();

    // Calculate average
    double average = ratings.reduce((a, b) => a + b) / ratings.length;

    // Calculate most common rating
    Map<double, int> frequencyMap = {};
    for (var rating in ratings) {
      frequencyMap[rating] = (frequencyMap[rating] ?? 0) + 1;
    }
    double mostCommon = frequencyMap.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    // Calculate longest streak
    List<DateTime> dates = filteredData
        .map((data) => DateTime.parse(data['date'].toString()))
        .toList()
      ..sort();
    
    int currentStreak = 1;
    int longestStreak = 1;
    
    for (int i = 1; i < dates.length; i++) {
      // Check if dates are consecutive
      if (dates[i].difference(dates[i - 1]).inDays == 1) {
        currentStreak++;
        longestStreak = currentStreak > longestStreak ? currentStreak : longestStreak;
      } else {
        currentStreak = 1;
      }
    }

    return {
      'average': average,
      'mostCommon': mostCommon,
      'longestStreak': longestStreak,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (filteredData.isEmpty) {
      return const SizedBox(
        height: 210,
        child: Center(
          child: Text('No mood data available'),
        ),
      );
    }

    // Sort the filtered data by date
    final sortedData = List<Map<String, dynamic>>.from(filteredData)
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

    // Calculate the statistics
    final stats = _calculateStatistics();

    return Column(
      children: [
        SizedBox(
          height: 210,
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
                    color: Colors.grey,
                    strokeWidth: 1,
                    dashArray: [5, 5], // Optional: makes the lines dashed
                  );
                },
                getDrawingVerticalLine: (value) {
                  return FlLine(
                    color: Colors.grey,
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

                        // Show the month abbreviation (MMM) only for the first data point of each month
                        bool showMonth = false;
                        if (index == 0) {
                          showMonth = true;  // Always show for the first item
                        } else {
                          DateTime prevDate = DateTime.parse(sortedData[index - 1]['date'].toString());
                          if (prevDate.month != date.month) {
                            showMonth = true;  // Show month abbreviation when the month changes
                          }
                        }

                        // Show labels only for some selected points (e.g., every 5th data point or at the start of a new month)
                        bool showLabel = index % 5 == 0 || (index == sortedData.length - 1);

                        if (showLabel) {
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
                      }
                      return const SizedBox.shrink();
                    },
                    reservedSize: 50, // Adjust this value to provide more space for bottom titles
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
                  sideTitles: SideTitles(showTitles: false), // Disable titles on the top
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false), // Disable titles on the right
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
                    color: const Color(0xFF3A4C7A),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFilterButton('week'),
              _buildFilterButton('month'),
              _buildFilterButton('year'),
              _buildFilterButton('all'),
            ],
          ),
        ),
        // Statistics Column
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'In this timeframe:',
              ),
              SizedBox(height: 10),
              Text(
                'Average Mood: ${stats['average'].toStringAsFixed(1)}',
              ),
              Text(
                'Most common: ${stats['mostCommon'].toStringAsFixed(0)}',
              ),
              Text(
                'Longest streak: ${stats['longestStreak'].toStringAsFixed(0)}',
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to build each button
  Widget _buildFilterButton(String filter) {
    // Inverse color logic: if the button is selected, make it light, else dark
    bool isSelected = selectedFilter == filter;
    return ElevatedButton(
      onPressed: () => _filterData(filter),
      child: Text(filter.toUpperCase()),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.white : Color(0xFF3A4C7A), // Inverse colors
        foregroundColor: isSelected ? Color(0xFF3A4C7A) : Colors.white, // Inverse colors
        side: BorderSide(
          color: isSelected ? Color(0xFF3A4C7A) : Colors.transparent, // Border for selected button
        ),
      ),
    );
  }
}
