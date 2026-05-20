import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:musea/app.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
  const initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );
  await flutterLocalNotificationsPlugin.initialize(initSettings);
}

Future<bool> requestNotificationPermissions() async {
  var granted = false;

  try {
    final android = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      granted = await android.requestNotificationsPermission() ?? false;
    }
  } catch (_) {}

  try {
    final darwin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (darwin != null) {
      granted = await darwin.requestPermissions(
            alert: true,
            badge: false,
            sound: true,
          ) ??
          granted;
    }
  } catch (_) {}

  return granted;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize local notifications
  try {
    await initNotifications();
  } catch (e) {
    debugPrint('Failed to initialize notifications: $e');
  }

  runApp(
    const ProviderScope(
      child: MuseaApp(),
    ),
  );
}
