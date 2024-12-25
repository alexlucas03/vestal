import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';

void main() {
  runApp(const MyApp());
}

Future<void> addMood(String mood) async {
  try {
    final conn = await Connection.open(Endpoint(
      host: 'ep-yellow-truth-a5ebo559.us-east-2.aws.neon.tech',
      database: 'voyagersdb',
      username: 'voyageruser',
      password: 'Sk3l3ton!sk3l3ton',
    ));
    await conn.execute(
      r'INSERT INTO moods VALUES ($1)',
      parameters: [mood],
    );
  } catch (e) {
    print('Error: ${e.toString()}');
  }
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
            primary: const Color(0xFF3A4C7A), // Darkest blue for Elevated buttons
            onPrimary: Colors.white, // White text on buttons
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
  final TextEditingController _moodController = TextEditingController();
  String _statusMessage = '';

  void _submitMood() async {
    String mood = _moodController.text.trim();
    if (mood.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter a mood.';
      });
      return;
    }

    setState(() {
      _statusMessage = 'Submitting mood...';
    });

    await addMood(mood);

    setState(() {
      _statusMessage = 'Mood submitted successfully!';
    });

    _moodController.clear();
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
            TextField(
              controller: _moodController,
              decoration: const InputDecoration(
                labelText: 'Enter your mood',
                labelStyle: TextStyle(color: Colors.black),
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(color: Colors.black),
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
