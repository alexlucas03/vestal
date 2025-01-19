import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:intl/intl.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'screens/mood_slider_page.dart';
import 'screens/home_page.dart';
import 'utils/code_generator.dart';
import 'utils/notification_service.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    databaseFactory = databaseFactoryFfi;
    await DatabaseHelper.instance.initDb();

    // Initialize OneSignal
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize('839fe5c4-93ca-4620-bf4b-adc6cfdf80e0');
    
    // Request notification permission
    await OneSignal.Notifications.requestPermission(true);

    // Get and store player ID
    String? playerId = await OneSignal.User.pushSubscription.id;
    if (playerId != null) {
      await DatabaseHelper.instance.storeOneSignalPlayerId(playerId);
    }

    // Listen for subscription changes
    OneSignal.User.pushSubscription.addObserver((state) async {
      if (state.current.id != null) {
        await DatabaseHelper.instance.storeOneSignalPlayerId(state.current.id!);
      }
    });

    // Handle notification opened
    OneSignal.Notifications.addClickListener((event) {
      print('Notification clicked: ${event.notification.additionalData}');
      // You can add navigation logic here when a notification is tapped
    });

    // Handle user code setup
    String? userCode = await DatabaseHelper.instance.getUserCode();
    if (userCode == null) {
      String newCode = generateRandomCode(6);
      await DatabaseHelper.instance.storeUserCode(newCode);
    }

    // Sync moments from cloud database
    await DatabaseHelper.instance.syncMomentsFromCloud();

    // Check if mood is submitted today
    String formattedDate = DateFormat('yyyyMMdd').format(DateTime.now());
    bool isMoodSubmittedToday = await DatabaseHelper.instance.hasMoodForToday(formattedDate);
    
    await NotificationService().initialize();

    runApp(MyApp(isMoodSubmittedToday: isMoodSubmittedToday));
  } catch (e) {
    print('Error in initialization: $e');
    // You might want to show an error screen here
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Error initializing app: $e'),
          ),
        ),
      ),
    );
  }
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
          ? const MyHomePage(title: 'vestal') 
          : const MoodSliderPage(fromPage: 'None'),
    );
  }
}