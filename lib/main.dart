import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:intl/intl.dart';
import 'screens/mood_slider_page.dart';
import 'screens/home_page.dart';
import 'utils/code_generator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  databaseFactory = databaseFactoryFfi;
  await DatabaseHelper.instance.initDb();

  String? userCode = await DatabaseHelper.instance.getUserCode();
  if (userCode == null) {
    String newCode = generateRandomCode(6);
    await DatabaseHelper.instance.storeUserCode(newCode);
  }

  String formattedDate = DateFormat('yyyyMMdd').format(DateTime.now());
  bool isMoodSubmittedToday = await DatabaseHelper.instance.hasMoodForToday(formattedDate);

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
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF222D49)),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF222D49),
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