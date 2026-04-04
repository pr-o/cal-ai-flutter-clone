import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

const _channelId = 'meal_reminders';
const _channelName = 'Meal Reminders';

final _plugin = FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  tz.initializeTimeZones();
  final timezoneName = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timezoneName));

  const androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();
  const settings =
      InitializationSettings(android: androidSettings, iOS: iosSettings);
  await _plugin.initialize(settings);

  await _plugin
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(alert: true, badge: true, sound: true);

  await _plugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();

  const channel = AndroidNotificationChannel(
    _channelId,
    _channelName,
    importance: Importance.high,
  );
  await _plugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

Future<void> scheduleMealReminder(
    int id, int hour, int minute, String label) async {
  await _plugin.cancel(id);

  final now = tz.TZDateTime.now(tz.local);
  var scheduled =
      tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
  if (scheduled.isBefore(now)) {
    scheduled = scheduled.add(const Duration(days: 1));
  }

  await _plugin.zonedSchedule(
    id,
    'Cal AI',
    label,
    scheduled,
    NotificationDetails(
      android: const AndroidNotificationDetails(
        _channelId,
        _channelName,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    ),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.time,
  );
}

Future<void> cancelReminder(int id) => _plugin.cancel(id);
