import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:intl/intl.dart';
import 'moodlinechart.dart';
import 'dart:math';
import 'starry_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  databaseFactory = databaseFactoryFfi;
  await DatabaseHelper.instance.initDb();

  // Check if user code exists, if not generate and store it
  String? userCode = await DatabaseHelper.instance.getUserCode();
  if (userCode == null) {
    String newCode = generateRandomCode(6);
    await DatabaseHelper.instance.storeUserCode(newCode);
  }

  String formattedDate = DateFormat('yyyyMMdd').format(DateTime.now());
  bool isMoodSubmittedToday = await DatabaseHelper.instance.hasMoodForToday(formattedDate);

  runApp(MyApp(isMoodSubmittedToday: isMoodSubmittedToday));
}

String generateRandomCode(int length) {
  const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  Random random = Random();
  String code = '';

  for (int i = 0; i < length; i++) {
    int index = random.nextInt(chars.length);  // Random index in the chars string
    code += chars[index];  // Append the character at that index
  }

  return code;
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
          backgroundColor: Color(0xFF7D9BFF),
          titleTextStyle: TextStyle(
            color: Colors.white,
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

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _angleAnimations;

  @override
  void initState() {
    super.initState();
    
    // Create animation controller with 1 second duration
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Create animations for each button
    _angleAnimations = List.generate(5, (index) {
      // All buttons start at -pi/2 (top position) and rotate to their final positions
      final finalAngle = (index * (2 * pi / 5)) - (pi / 2);
      return Tween<double>(
        begin: -pi / 2, // Starting from top
        end: finalAngle,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOut,
        ),
      );
    });

    // Start the animation when the page loads
    Future.delayed(Duration(milliseconds: 500), () {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double containerSize = MediaQuery.sizeOf(context).width;

    return Scaffold(
      body: StarryBackground(
        child: Center(
          child: Container(
            width: containerSize,
            height: containerSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Center circle
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.black,
                      width: 10,
                    ),
                  ),
                ),
                
                // Animated buttons
                ..._buildButtonsAroundCircle(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildButtonsAroundCircle() {
    const double buttonSize = 75.0;
    const double radius = 150.0;
    double containerSize = MediaQuery.sizeOf(context).width;
    double centerPoint = containerSize / 2;

    List<Widget> buttons = [];

    for (int i = 0; i < 5; i++) {
      buttons.add(
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            double angle = _angleAnimations[i].value;
            double x = centerPoint + (radius * cos(angle));
            double y = centerPoint + (radius * sin(angle));

            // Adjust the button's position so it's correctly centered
            return Positioned(
              top: y - (buttonSize / 2),  // Ensure y-position is correctly offset by half the button size
              left: x - (buttonSize / 2), // Ensure x-position is correctly offset by half the button size
              child: Container(
                width: buttonSize,
                height: buttonSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(buttonSize / 2),
                  border: Border.all(
                    color: const Color(0xFF0A205A),
                    width: 2,
                  ),
                ),
                child: _buildSection(
                  'Section ${i + 1}',
                  _getPageForIndex(i),
                ),
              ),
            );
          },
        ),
      );
    }

    return buttons;
  }

  Widget _buildSection(String title, Widget page) {
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
        child: Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _getPageForIndex(int index) {
    switch (index) {
      case 0:
        return const MoodStats();
      case 1:
        return const SectionTwoPage();
      case 2:
        return const SectionThreePage();
      case 3:
        return const SectionFourPage();
      case 4:
        return const SettingsPage();
      default:
        return const SizedBox.shrink();
    }
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
  bool isMoodSubmitted = false;

  @override
  void initState() {
    super.initState();
    _checkMoodForToday();
  }

  void _checkMoodForToday() async {
    List<Map<String, dynamic>> moodsFromDb = await DatabaseHelper.instance.queryAllMoods();

    setState(() {
      isMoodSubmitted = moodsFromDb.isNotEmpty;
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
            isMoodSubmitted
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
                      // clear mood database button
                      // ElevatedButton(
                      //   onPressed: _clearMoods,
                      //   child: const Text('Clear All Moods'),
                      // ),
                    ],
                  )
                : ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MoodSliderPage(fromPage: 'MoodStats'),),
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

class MoodSliderPage extends StatefulWidget {
  final String fromPage; // Parameter to track the origin page

  const MoodSliderPage({super.key, required this.fromPage});

  @override
  _MoodSliderPageState createState() => _MoodSliderPageState();
}

class _MoodSliderPageState extends State<MoodSliderPage> with SingleTickerProviderStateMixin {
  double _rating = 5.0;
  String formattedDate = DateFormat('yyyyMMdd').format(DateTime.now());

  // Animation controller for the bouncing arrow
  late AnimationController _controller;
  late Animation<double> _bouncingAnimation;

  @override
  void initState() {
    super.initState();

    // Animation controller for the bouncing arrow
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    )..repeat(reverse: true); // Repeats the animation back and forth
    
    _bouncingAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Function to determine track color based on rating
  Color _getTrackColor(double rating) {
    if (rating >= 8) {
      return Colors.green; // Green for 8-10
    } else if (rating >= 6) {
      return Colors.yellow; // Yellow for 6-8
    } else if (rating >= 3) {
      return Colors.orange; // Orange for 3-5
    } else {
      return Colors.red; // Red for 0-2
    }
  }

  // Function to get rating reactions
  String _getRatingReaction(double rating) {
    if (rating == 0) {
      return 'Terrible! 😭';
    } else if (rating == 1) {
      return 'Very bad! 😞';
    } else if (rating == 2) {
      return 'Not good. 😔';
    } else if (rating == 3) {
      return 'Could be better. 😟';
    } else if (rating == 4) {
      return 'A little disappointing. 😕';
    } else if (rating == 5) {
      return 'Okay. 😐';
    } else if (rating == 6) {
      return 'Not bad, not great. 🙂';
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

  // Submit mood to the database
  void _submitMood() async {
    int rating = _rating.toInt();
    
    try {
      // Add the mood to the local SQLite database
      await DatabaseHelper.instance.addMood(rating, formattedDate);

      // Check if user has a partner code
      String? userCode = await DatabaseHelper.instance.getUserCode();
      String? partnerCode = await DatabaseHelper.instance.getPartnerCode();

      // If both user code and partner code exist, sync with cloud
      if (userCode != null && partnerCode != null) {
        try {
          await DatabaseHelper.instance.CloudAddMood(rating, formattedDate, userCode);
        } catch (cloudError) {
          print('Error syncing with cloud: $cloudError');
          // Consider showing a snackbar to user about cloud sync failure
          // but continue with local navigation
        }
      }

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
    } catch (error) {
      // Handle any errors that occurred during mood submission
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving mood: ${error.toString()}')),
        );
      }
    }
  }

  // No mood action (back to the previous screen)
  void _noMood() async {
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
                'How do you feel?',
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
                  trackHeight: 32.0,
                  activeTrackColor: _getTrackColor(_rating),
                  inactiveTrackColor: Colors.black,
                  thumbColor: Colors.white,
                  overlayColor: Colors.transparent,
                  activeTickMarkColor: Colors.transparent,
                  inactiveTickMarkColor: Colors.transparent,
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 20.0),
                ),
                child: Container(
                  width: 500.0,
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
            ElevatedButton(
              onPressed: _submitMood,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mood text with rating and reaction
                  Text(
                    '${_rating.toStringAsFixed(0)}! ${_getRatingReaction(_rating)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 10),
                  AnimatedBuilder(
                    animation: _bouncingAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_bouncingAnimation.value, 0), // Bounce left to right (X axis)
                        child: child,
                      );
                    },
                    child: Icon(
                      Icons.arrow_forward,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _noMood,
              child: const Text('No mood'),
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

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? userCode;
  String? partnerCode;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final code = await DatabaseHelper.instance.getUserCode();
      final pCode = await DatabaseHelper.instance.getPartnerCode();
      if (!mounted) return;
      setState(() {
        userCode = code;
        partnerCode = pCode;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createPartnerTable(String partnerCode, String userCode) async {
    await DatabaseHelper.instance.createPartnerTable(partnerCode, userCode);
  }

  void _showPartnerCodeDialog(BuildContext context) {
    // Create a StatefulBuilder to manage dialog state
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final TextEditingController dialogController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Enter Partner Code'),
              content: TextField(
                controller: dialogController,
                maxLength: 6,
                decoration: const InputDecoration(
                  hintText: 'Enter 6-digit code',
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final code = dialogController.text;
                    if (code.length == 6) {
                      try {
                        await DatabaseHelper.instance.storePartnerCode(code);
                        if (!mounted) return;
                        
                        // Get the current user code
                        final userCode = await DatabaseHelper.instance.getUserCode();
                        if (userCode != null) {
                          // Create partner table with the submitted code and user code
                          await _createPartnerTable(code, userCode);
                        }
                        
                        Navigator.of(dialogContext).pop();
                        // Use Future.microtask to avoid setState during build
                        Future.microtask(() => _loadData());
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${e.toString()}')),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid 6-digit code')),
                      );
                    }
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      // Ensure dialog controller is disposed when dialog is closed
      if (mounted) {
        setState(() {
          // Refresh state if needed after dialog closes
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Your Code: ${userCode ?? ''}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Partner Code: ${partnerCode ?? ''}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _showPartnerCodeDialog(context),
                  child: const Text(
                    'Add Partner',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    // Implement reset data logic
                    await DatabaseHelper.instance.clearDb();
                    if (mounted) {
                      _loadData();
                    }
                  },
                  child: const Text(
                    'Reset Data',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
