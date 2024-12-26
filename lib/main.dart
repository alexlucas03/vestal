import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // Import the ffi library
// Import the sqflite package

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  databaseFactory = databaseFactoryFfi;
  await DatabaseHelper.instance.initDb();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
        buttonTheme: const ButtonThemeData(
          buttonColor: Color(0xFF3A4C7A), // Darkest blue for buttons
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3A4C7A), // Darkest blue for Elevated buttons
          ),
        ),
      ),
      home: const MyHomePage(title: 'Voyagers'),
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
  double _rating = 5.0;  // Default rating is 5, which could represent a neutral mood.
  String _statusMessage = '';
  List<int> _moods = []; // List to store all mood ratings

  // Method to submit a mood to the database
  void _submitMood() async {
    // Convert the rating to an integer (if necessary)
    int rating = _rating.toInt();
    setState(() {
      _statusMessage = 'Submitting mood...';
    });

    // Add the mood to the database
    await DatabaseHelper.instance.addMood(rating);

    // After submitting, reload the list of moods
    _loadMoods();

    setState(() {
      _statusMessage = 'Mood submitted successfully!';
    });
  }

  // Method to load all moods from the database
  void _loadMoods() async {
    List<Map<String, dynamic>> moodsFromDb = await DatabaseHelper.instance.queryAllMoods();

    // Extract the ratings from the query results
    List<int> moodsList = moodsFromDb.map((mood) => mood['rating'] as int).toList();

    setState(() {
      _moods = moodsList; // Update the moods list with the fetched data
    });
  }

  // Method to clear all moods from the database
  void _clearMoods() async {
    setState(() {
      _statusMessage = 'Clearing moods...';
    });

    // Clear all moods from the database
    await DatabaseHelper.instance.clearDb();

    // Reload the moods list after clearing
    _loadMoods();

    setState(() {
      _statusMessage = 'All moods cleared!';
    });
  }

  @override
  void initState() {
    super.initState();
    // Load moods from the database when the widget is first created
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
            // Vertical Slider for Mood Rating
            RotatedBox(
              quarterTurns: 3,
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
            const SizedBox(height: 16),
            Text(
              'Mood Rating: ${_rating.toStringAsFixed(1)}',
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
            const SizedBox(height: 16),
            
            // Display the submitted moods separated by commas
            if (_moods.isNotEmpty)
              Text(
                'Submitted Moods: ${_moods.join(', ')}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            if (_moods.isEmpty)
              const Text(
                'No moods submitted yet.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            
            const SizedBox(height: 16),

            // Clear Moods button
            ElevatedButton(
              onPressed: _clearMoods,
              child: const Text('Clear All Moods'),
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
