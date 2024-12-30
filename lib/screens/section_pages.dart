import 'package:flutter/material.dart';

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