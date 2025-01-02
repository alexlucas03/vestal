import 'package:flutter/material.dart';
import 'dart:math';
import '../widgets/starry_background.dart';
import 'mood_stats.dart';
import 'section_pages.dart';
import 'settings_page.dart';
import 'moments_page.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _angleAnimations;
  
  final List<String> sectionNames = ['Moods', 'Moments', 'Section 3', 'Section 4', 'Settings'];

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _angleAnimations = List.generate(5, (index) {
      final finalAngle = (index * (2 * pi / 5)) - (pi / 2);
      return Tween<double>(
        begin: -pi / 2,
        end: finalAngle,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOut,
        ),
      );
    });

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
                  ),
                  child: Image.asset(
                    'assets/images/voyagersicon.png',
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

            return Positioned(
              top: y - (buttonSize / 2),
              left: x - (buttonSize / 2),
              child: _buildSection(
                sectionNames[i],
                _getPageForIndex(i),
                buttonSize,
              ),
            );
          },
        ),
      );
    }

    return buttons;
  }

  Widget _buildSection(String title, Widget page, double buttonSize) {
    IconData iconData;
    switch (title) {
      case 'Moods':
        iconData = Icons.mood;
        break;
      case 'Moments':
        iconData = Icons.book;
        break;
      case 'Section 3':
        iconData = Icons.circle;
        break;
      case 'Section 4':
        iconData = Icons.circle;
        break;
      case 'Settings':
        iconData = Icons.settings;
        break;
      default:
        iconData = Icons.circle;
    }

    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF222D49),
      ),
      child: IconButton(
        icon: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              iconData,
              color: Colors.white,
              size: 48,
            ),
          ],
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
      ),
    );
  }

  Widget _getPageForIndex(int index) {
    switch (index) {
      case 0:
        return const MoodStats();
      case 1:
        return const MomentsPage();
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