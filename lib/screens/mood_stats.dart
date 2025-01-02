import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database_helper.dart';
import '../widgets/mood_line_chart.dart';
import 'mood_slider_page.dart';

class MoodStats extends StatefulWidget {
  const MoodStats({super.key});

  @override
  _MoodStatsState createState() => _MoodStatsState();
}

class _MoodStatsState extends State<MoodStats> {
  List<Map<String, dynamic>> _moods = [];
  List<Map<String, dynamic>> _partnerMoods = [];
  String formattedDate = DateFormat('yyyyMMdd').format(DateTime.now());
  bool isMoodSubmitted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMoodData();
  }

  Future<void> _loadMoodData() async {
    try {
      // Get all mood data from DatabaseHelper
      final allMoodData = await DatabaseHelper.instance.getAllMoodData();
      
      if (mounted) {
        setState(() {
          _moods = allMoodData['userMoods'] ?? [];
          _partnerMoods = allMoodData['partnerMoods'] ?? [];
          isMoodSubmitted = _moods.isNotEmpty;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Handle error state if needed
        });
      }
      print('Error loading mood data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(
            color: Colors.white,
          ),
          title: const Text('Mood Stats'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        title: const Text('Mood Stats'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isMoodSubmitted
                ? Column(
                    children: [
                      MoodLineChart(
                        moodData: _moods,
                        partnerMoodData: _partnerMoods.isNotEmpty ? _partnerMoods : null,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MoodSliderPage(fromPage: 'MoodStats'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Color(0xFF222D49),
                        ),
                        child: const Text('Rate Your Mood'),
                      ),
                    ],
                  )
                : ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MoodSliderPage(fromPage: 'MoodStats'),
                        ),
                      );
                    },
                    child: const Text('Rate Your Mood to see your stats'),
                  ),
          ],
        ),
      ),
    );
  }
}