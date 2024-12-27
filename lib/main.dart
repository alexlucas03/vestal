import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:intl/intl.dart';
import 'moodlinechart.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  databaseFactory = databaseFactoryFfi;
  await DatabaseHelper.instance.initDb();

  // Check if a mood has been submitted for today
  String formattedDate = DateFormat('yyyyMMdd').format(DateTime.now());
  bool isMoodSubmittedToday = await DatabaseHelper.instance.hasMoodForToday(formattedDate);

  // Set the home page based on whether a mood has been submitted today
  runApp(MyApp(isMoodSubmittedToday: isMoodSubmittedToday));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.isMoodSubmittedToday});

  final bool isMoodSubmittedToday;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF7D9BFF), // Lighter blue for AppBar
          titleTextStyle: TextStyle(
            color: Colors.white, // White text in AppBar
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: isMoodSubmittedToday 
          ? const MyHomePage(title: 'Voyagers') 
          : const MoodSliderPage(fromPage: 'None'),
    );
  }
}

Widget _buildSection(BuildContext context, String title, Widget page) {
  return GestureDetector(
    onTap: () {
      // Navigate to the respective page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => page),
      );
    },
    child: Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0A205A), // Darkest blue for buttons
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // Centers the Row content horizontally
        crossAxisAlignment: CrossAxisAlignment.center, // Centers the Row content vertically
        children: [
          Expanded( // Makes the Text take available space and center it
            child: Center( // Centers the text horizontally and vertically inside the Expanded
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // White text color
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            textAlign: TextAlign.left,
            style: const TextStyle(
              color: Colors.white, // White text in AppBar
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Expanded(
              child: _buildSection(context, 'Mood Stats', const MoodStats()),
            ),
            Expanded(
              child: _buildSection(context, 'Section 2', const SectionTwoPage()),
            ),
            Expanded(
              child: _buildSection(context, 'Section 3', const SectionThreePage()),
            ),
            Expanded(
              child: _buildSection(context, 'Section 4', const SectionFourPage()),
            ),
          ],
        ),
      ),
    );
  }
}

class MoodStats extends StatefulWidget {
  const MoodStats({super.key});

  @override
  _MoodStatsState createState() => _MoodStatsState();
}

class _MoodStatsState extends State<MoodStats> {
  List<Map<String, dynamic>> _moods = [];
  String formattedDate = DateFormat('yyyyMMdd').format(DateTime.now());
  bool isMoodSubmittedToday = false;

  @override
  void initState() {
    super.initState();
    _checkMoodForToday();
  }

  void _checkMoodForToday() async {
    List<Map<String, dynamic>> moodsFromDb = await DatabaseHelper.instance.queryMoodsByDate(formattedDate);

    setState(() {
      isMoodSubmittedToday = moodsFromDb.isNotEmpty;
      _moods = moodsFromDb;
    });
  }

  // Method to load all moods from the database
  void _loadMoods() async {
    List<Map<String, dynamic>> moodsFromDb = await DatabaseHelper.instance.queryAllMoods();
    setState(() {
      _moods = moodsFromDb; // Store the complete map with both rating and date
    });
  }

  void _clearMoods() async {

    // Clear all moods from the database
    await DatabaseHelper.instance.clearDb();

    // Reload the moods list after clearing
    _loadMoods();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Stats'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isMoodSubmittedToday
                ? Column(
                    children: [
                      MoodLineChart(moodData: _moods),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => MoodSliderPage(fromPage: 'MoodStats'),),
                          );
                        },
                        child: const Text('Rate Your Mood'),
                      ),
                      ElevatedButton(
                        onPressed: _clearMoods,
                        child: const Text('Clear All Moods'),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'No mood recorded today.',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

class MoodSliderPage extends StatefulWidget {
  final String fromPage; // Added parameter to track the origin page

  const MoodSliderPage({super.key, required this.fromPage});

  @override
  _MoodSliderPageState createState() => _MoodSliderPageState();
}

class _MoodSliderPageState extends State<MoodSliderPage> {
  double _rating = 5.0;
  String _statusMessage = '';
  String formattedDate = DateFormat('yyyyMMdd').format(DateTime.now());

  void _submitMood() async {
    int rating = _rating.toInt();
    setState(() {
      _statusMessage = 'Submitting mood...';
    });

    // Add the mood to the database
    await DatabaseHelper.instance.addMood(rating, formattedDate);

    // Navigate back to the correct page based on 'fromPage' parameter
    if (widget.fromPage == 'MoodStats') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MoodStats()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MyHomePage(title: 'Voyagers')),
      );
    }
  }

  // Function to determine active track color based on slider value
  Color _getTrackColor(double rating) {
    if (rating >= 8) {
      return Colors.green; // Green for 8-10
    } else if (rating >= 6) {
      return Colors.yellow; // Yellow for 6-8
    } else if (rating >= 3) {
      return Colors.orange; // Blue for 3-5
    } else {
      return Colors.red; // Red for 0-2
    }
  }

  String _getRatingReaction(double rating) {
  if (rating == 0) {
    return 'Absolutely terrible! 😭';
  } else if (rating == 1) {
    return 'Very bad! 😞';
  } else if (rating == 2) {
    return 'Not good at all. 😔';
  } else if (rating == 3) {
    return 'Could be better. 😟';
  } else if (rating == 4) {
    return 'Somewhat disappointing. 😕';
  } else if (rating == 5) {
    return 'It’s okay. 😐';
  } else if (rating == 6) {
    return 'Not bad, but not great. 🙂';
  } else if (rating == 7) {
    return 'Pretty good! 😌';
  } else if (rating == 8) {
    return 'Very good! 😊';
  } else if (rating == 9) {
    return 'Excellent! 😍';
  } else if (rating == 10) {
    return 'Perfect! 😁';
  } else {
    return 'Unknown rating'; // Default case
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 50.0),
              child: Text(
                'How do you feel?', // The text you wanted above the slider
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            RotatedBox(
              quarterTurns: 3,
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 32.0, // Customize track height
                  activeTrackColor: _getTrackColor(_rating),
                  inactiveTrackColor: Colors.black, // Inactive track color (red)
                  thumbColor: Colors.white, // Thumb color
                  overlayColor: Colors.transparent, // No overlay
                  activeTickMarkColor: Colors.transparent,
                  inactiveTickMarkColor: Colors.transparent,
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 20.0), // Thumb size
                ),
                child: Container(
                  width: 500.0, // Make the track longer by adjusting the width
                  child: Slider(
                    value: _rating,
                    min: 0,
                    max: 10,
                    divisions: 10,
                    onChanged: (double newValue) {
                      setState(() {
                        _rating = newValue;
                      });
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            Text(
              '${_rating.toStringAsFixed(0)}! ${_getRatingReaction(_rating)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitMood,
              child: const Text('Submit Mood'),
            ),
            const SizedBox(height: 16),
            Text(
              _statusMessage,
              style: const TextStyle(color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}


class SectionTwoPage extends StatelessWidget {
  const SectionTwoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Section 2 Page'),
      ),
      body: const Center(
        child: Text('You are on Section 2 Page!', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class SectionThreePage extends StatelessWidget {
  const SectionThreePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Section 3 Page'),
      ),
      body: const Center(
        child: Text('You are on Section 3 Page!', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class SectionFourPage extends StatelessWidget {
  const SectionFourPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Section 4 Page'),
      ),
      body: const Center(
        child: Text('You are on Section 4 Page!', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
