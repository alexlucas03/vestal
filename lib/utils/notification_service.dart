import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../database_helper.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String oneSignalAppId = '839fe5c4-93ca-4620-bf4b-adc6cfdf80e0';

  Future<void> initialize() async {
    // Initialize OneSignal
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize(oneSignalAppId);
    
    // Request notification permission
    await OneSignal.Notifications.requestPermission(true);

    // Handle notification opened - just launch the app
    OneSignal.Notifications.addClickListener((event) {
      // The default behavior will just open the app
      print('Notification clicked');
    });

    // Get player ID (device token) and store it
    String? playerId = await OneSignal.User.pushSubscription.id;
    if (playerId != null) {
      await DatabaseHelper.instance.storeOneSignalPlayerId(playerId);
      // Schedule daily notification for this device
      await scheduleDailyNotification(playerId);
    }

    // Listen for subscription changes
    OneSignal.User.pushSubscription.addObserver((state) async {
      if (state.current.id != null) {
        await DatabaseHelper.instance.storeOneSignalPlayerId(state.current.id!);
        // Re-schedule notification when player ID changes
        await scheduleDailyNotification(state.current.id!);
      }
    });
  }

  Future<void> scheduleDailyNotification(String playerId) async {
    try {
      // Calculate next 8 PM time
      final now = DateTime.now();
      var nextNotificationTime = DateTime(
        now.year,
        now.month,
        now.day,
        1, // 8 PM
        11,  // 0 minutes
      );
      
      // If it's already past 8 PM, schedule for tomorrow
      if (now.isAfter(nextNotificationTime)) {
        nextNotificationTime = nextNotificationTime.add(const Duration(days: 1));
      }

      final response = await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic 7wagzl4rvupu5lgqcjpdgocd2'
        },
        body: json.encode({
          'app_id': oneSignalAppId,
          'include_player_ids': [playerId],
          'headings': {'en': 'Daily Check-in'},
          'contents': {'en': 'Time to record your moments for today!'},
          'send_after': nextNotificationTime.toUtc().toIso8601String(),
          'delayed_option': 'timezone',
          'delivery_time_of_day': '20:00',
          'ios_badgeType': 'Increase',
          'ios_badgeCount': 1
        }),
      );

      if (response.statusCode != 200) {
        print('Failed to schedule notification: ${response.body}');
      } else {
        print('Daily notification scheduled successfully');
      }
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  Future<void> sendNotificationToPartner({
    required String partnerPlayerId,
    required String title,
    required String message,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic 7wagzl4rvupu5lgqcjpdgocd2'
        },
        body: json.encode({
          'app_id': oneSignalAppId,
          'include_player_ids': [partnerPlayerId],
          'headings': {'en': title},
          'contents': {'en': message},
          'data': additionalData,
          'ios_badgeType': 'Increase',
          'ios_badgeCount': 1
        }),
      );

      if (response.statusCode != 200) {
        print('Failed to send notification: ${response.body}');
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }
}