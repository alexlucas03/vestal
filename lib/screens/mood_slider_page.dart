import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vestal/screens/home_page.dart';
import '../database_helper.dart';

class MoodSliderPage extends StatefulWidget {
  final String fromPage;

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

      if (mounted) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context, true);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MyHomePage(title: 'vestal'),
            ),
          );  // Navigate to homepage
        }
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
    if (mounted) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MyHomePage(title: 'vestal'),
          ),
        );  // Navigate to homepage
      }
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