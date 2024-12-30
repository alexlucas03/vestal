import 'package:flutter/material.dart';
import 'package:voyagers/database_helper.dart';
import 'chart_widgets/chart_display.dart';
import 'chart_widgets/mood_statistics.dart';
import 'chart_widgets/filter_buttons.dart';
import 'models/chart_data.dart';

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
  late ChartData chartData;
  bool showUserData = true;
  bool showPartnerData = true;
  bool isPinkPreference = false;

  @override
  void initState() {
    super.initState();
    chartData = ChartData(widget.moodData, widget.partnerMoodData ?? []);
    _loadColorPreference();
  }

  Future<void> _loadColorPreference() async {
    final pink = await DatabaseHelper.instance.getColorPreference();
    setState(() {
      isPinkPreference = pink;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (chartData.filteredData.isEmpty) {
      return const SizedBox(
        height: 210,
        child: Center(child: Text('No mood data available')),
      );
    }

    return Column(
      children: [
        ChartDisplay(
          chartData: chartData,
          showUserData: showUserData,
          showPartnerData: showPartnerData,
          isPinkPreference: isPinkPreference,
        ),
        FilterButtons(
          selectedFilter: chartData.selectedFilter,
          onFilterChanged: (filter) {
            setState(() {
              chartData.filterData(filter);
            });
          },
          showUserData: showUserData,
          showPartnerData: showPartnerData,
          onUserDataToggled: () => setState(() => showUserData = !showUserData),
          onPartnerDataToggled: () => setState(() => showPartnerData = !showPartnerData),
          isPinkPreference: isPinkPreference,
        ),
        MoodStatistics(
          chartData: chartData,
          showUserData: showUserData,
          showPartnerData: showPartnerData,
          isPinkPreference: isPinkPreference,
        ),
      ],
    );
  }
}