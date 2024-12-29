import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:voyagers/database_helper.dart';

class MoodLineChart extends StatefulWidget {
  final List<Map<String, dynamic>> moodData;
  final List<Map<String, dynamic>>? partnerMoodData;

  const MoodLineChart({
    super.key,
    required this.moodData,
    this.partnerMoodData,
  });

  @override
  _MoodLineChartState createState() => _MoodLineChartState();
}

class _MoodLineChartState extends State<MoodLineChart> {
  List<Map<String, dynamic>> filteredData = [];
  List<Map<String, dynamic>> filteredPartnerData = [];
  String selectedFilter = 'all';
  bool showUserData = true;
  bool showPartnerData = true;
  bool isPinkPreference = false;

  @override
  void initState() {
    super.initState();
    filteredData = widget.moodData;
    filteredPartnerData = widget.partnerMoodData ?? [];
    _loadColorPreference();
  }

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
          filteredPartnerData = widget.partnerMoodData ?? [];
          return;
      }

      filteredData = widget.moodData.where((data) {
        DateTime date = DateTime.parse(data['date'].toString());
        return date.isAfter(startDate);
      }).toList();

      filteredPartnerData = (widget.partnerMoodData ?? []).where((data) {
        DateTime date = DateTime.parse(data['date'].toString());
        return date.isAfter(startDate);
      }).toList();
    });
  }

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

    double average = ratings.reduce((a, b) => a + b) / ratings.length;

    Map<double, int> frequencyMap = {};
    for (var rating in ratings) {
      frequencyMap[rating] = (frequencyMap[rating] ?? 0) + 1;
    }
    double mostCommon = frequencyMap.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    List<DateTime> dates = filteredData
        .map((data) => DateTime.parse(data['date'].toString()))
        .toList()
      ..sort();
    
    int currentStreak = 1;
    int longestStreak = 1;
    
    for (int i = 1; i < dates.length; i++) {
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

  Map<String, dynamic> _calculatePartnerStatistics() {
    if (filteredPartnerData.isEmpty) {
      return {
        'average': 0.0,
        'mostCommon': 0,
        'longestStreak': 0,
      };
    }

    List<double> ratings = filteredPartnerData
        .map((data) => (data['rating'] as num).toDouble())
        .toList();

    double average = ratings.reduce((a, b) => a + b) / ratings.length;

    Map<double, int> frequencyMap = {};
    for (var rating in ratings) {
      frequencyMap[rating] = (frequencyMap[rating] ?? 0) + 1;
    }
    double mostCommon = frequencyMap.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    List<DateTime> dates = filteredPartnerData
        .map((data) => DateTime.parse(data['date'].toString()))
        .toList()
      ..sort();
    
    int currentStreak = 1;
    int longestStreak = 1;
    
    for (int i = 1; i < dates.length; i++) {
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

  Future<void> _loadColorPreference() async {
    final pink = await DatabaseHelper.instance.getColorPreference();
    setState(() {
      isPinkPreference = pink;
    });
  }

  // Add these getter methods for colors
  Color get userColor => isPinkPreference ? Colors.pink : const Color(0xFF3A4C7A);
  Color get partnerColor => isPinkPreference ? const Color(0xFF3A4C7A) : Colors.pink;

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

    final sortedData = List<Map<String, dynamic>>.from(filteredData)
      ..sort((a, b) => a['date'].toString().compareTo(b['date'].toString()));
    
    final sortedPartnerData = List<Map<String, dynamic>>.from(filteredPartnerData)
      ..sort((a, b) => a['date'].toString().compareTo(b['date'].toString()));

    final allDates = {
      ...sortedData.map((e) => e['date'].toString()),
      ...sortedPartnerData.map((e) => e['date'].toString())
    }.toList()..sort();

    return Column(
      children: [
        Stack(
          children: [
            SizedBox(
              height: 210,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
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
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < allDates.length) {
                            final date = DateTime.parse(allDates[index]);
                            final monthKey = DateFormat('MMM').format(date).toLowerCase();
                            final dayText = date.day.toString();

                            bool showMonth = false;
                            if (index == 0) {
                              showMonth = true;
                            } else {
                              DateTime prevDate = DateTime.parse(allDates[index - 1]);
                              if (prevDate.month != date.month) {
                                showMonth = true;
                              }
                            }

                            bool showLabel = index % 5 == 0 || (index == allDates.length - 1);

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
                  ),
                  borderData: FlBorderData(show: true),
                  minX: 0,
                  maxX: (allDates.length - 1).toDouble(),
                  minY: 0,
                  maxY: 10,
                  lineBarsData: [
                    if (showUserData)
                      LineChartBarData(
                        spots: List.generate(
                          allDates.length,
                          (index) {
                            final date = allDates[index];
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
                        color: userColor,
                        barWidth: 3,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(show: false),
                      ),
                    if (sortedPartnerData.isNotEmpty && showPartnerData)
                      LineChartBarData(
                        spots: List.generate(
                          allDates.length,
                          (index) {
                            final date = allDates[index];
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
                        color: partnerColor,
                        barWidth: 3,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(show: false),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(
          height: 40,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(child: _buildFilterButton('week')),
                SizedBox(width: 8),
                Expanded(child: _buildFilterButton('month')),
                SizedBox(width: 8),
                Expanded(child: _buildFilterButton('year')),
                SizedBox(width: 8),
                Expanded(child: _buildFilterButton('all')),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        SizedBox(
          height: 40,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildDualFilterButton(
                    'You',
                    showUserData,
                    () {
                      setState(() {
                        showUserData = !showUserData;
                      });
                    },
                    userColor,
                    icon: showUserData ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
                SizedBox(width: 8), // Same gap as filter buttons
                Expanded(
                  child: _buildDualFilterButton(
                    'Partner',
                    showPartnerData,
                    () {
                      setState(() {
                        showPartnerData = !showPartnerData;
                      });
                    },
                    partnerColor,
                    icon: showPartnerData ? Icons.visibility : Icons.visibility_off,
                    iconColor: showPartnerData ? partnerColor : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        Padding(
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
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Average Mood:',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      if (showUserData)
                        Text(
                          '${_calculateStatistics()['average'].toStringAsFixed(1)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: userColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      if (showPartnerData)
                        Text(
                          '${_calculatePartnerStatistics()['average'].toStringAsFixed(1)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: partnerColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                  TableRow(
                    children: [
                      const Divider(color: Color(0xFF3A4C7A), thickness: 1),
                      if (showUserData)
                        const Divider(color: Color(0xFF3A4C7A), thickness: 1),
                      if (showPartnerData)
                        const Divider(color: Color(0xFF3A4C7A), thickness: 1),
                    ],
                  ),
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Most common:',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      if (showUserData)
                        Text(
                          '${_calculateStatistics()['average'].toStringAsFixed(1)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: userColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      if (showPartnerData)
                        Text(
                          '${_calculatePartnerStatistics()['average'].toStringAsFixed(1)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: partnerColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                  TableRow(
                    children: [
                      const Divider(color: Color(0xFF3A4C7A), thickness: 1),
                      if (showUserData)
                        const Divider(color: Color(0xFF3A4C7A), thickness: 1),
                      if (showPartnerData)
                        const Divider(color: Color(0xFF3A4C7A), thickness: 1),
                    ],
                  ),
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Longest streak:',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      if (showUserData)
                        Text(
                          '${_calculateStatistics()['longestStreak'].toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: userColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      if (showPartnerData)
                        Text(
                          '${_calculatePartnerStatistics()['longestStreak'].toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: partnerColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                  TableRow(
                    children: [
                      const Divider(color: Color(0xFF3A4C7A), thickness: 1),
                      if (showUserData)
                        const Divider(color: Color(0xFF3A4C7A), thickness: 1),
                      if (showPartnerData)
                        const Divider(color: Color(0xFF3A4C7A), thickness: 1),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDualFilterButton(String label, bool isSelected, VoidCallback onPressed, Color color, {IconData? icon, Color? iconColor}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.white : Colors.grey[200],
        foregroundColor: isSelected ? color : Colors.grey,
        side: BorderSide(
          color: isSelected ? color : Colors.transparent,
        ),
        padding: EdgeInsets.symmetric(horizontal: 4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) Icon(icon, size: 20, color: iconColor ?? (isSelected ? color : Colors.grey)),
          if (icon != null) SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String filter) {
    bool isSelected = selectedFilter == filter;
    return Expanded(
      child: ElevatedButton(
        onPressed: () => _filterData(filter),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.white : Color(0xFF3A4C7A),
          foregroundColor: isSelected ? Color(0xFF3A4C7A) : Colors.white,
          side: BorderSide(
            color: isSelected ? Color(0xFF3A4C7A) : Colors.transparent,
          ),
          padding: EdgeInsets.symmetric(horizontal: 4),
        ),
        child: Text(filter.toUpperCase()),
      ),
    );
  }
}