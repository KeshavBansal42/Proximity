import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:alarm/alarm.dart';
import '../models/reminder_model.dart';
import 'database_service.dart';
import 'notification_service.dart';
import 'location_service.dart';

@pragma('vm:entry-point')
Future<void> callback() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.init();
  await NotificationService.init();
  await Alarm.init();

  Position? position;
  try {
    position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
  } catch (e) {
    return;
  }

  final box = DatabaseService.getBox();
  final keys = box.keys.toList();

  if (keys.isEmpty) return;

  final now = DateTime.now();

  for (var key in keys) {
    final reminder = box.get(key);

    if (reminder == null) continue;
    if (!reminder.isActive) continue;

    if (reminder.lastTriggeredDate != null) {
      final last = reminder.lastTriggeredDate!;
      if (last.day == now.day &&
          last.month == now.month &&
          last.year == now.year) {
        continue;
      }
    }

    final dayIndex = now.weekday;

    if ((dayIndex == 1 && reminder.isMonday == true) ||
        (dayIndex == 2 && reminder.isTuesday == true) ||
        (dayIndex == 3 && reminder.isWednesday == true) ||
        (dayIndex == 4 && reminder.isThursday == true) ||
        (dayIndex == 5 && reminder.isFriday == true) ||
        (dayIndex == 6 && reminder.isSaturday == true) ||
        (dayIndex == 7 && reminder.isSunday == true)) {
      final reminderTime = DateTime(
        now.year,
        now.month,
        now.day,
        reminder.hour,
        reminder.minute,
      );

      final difference = now.difference(reminderTime).inMinutes;

      if (difference < 0 || difference > 5) {
        continue;
      }

      double distance = LocationService.getDistance(
        lat1: position.latitude,
        lon1: position.longitude,
        lat2: reminder.latitude,
        lon2: reminder.longitude,
      );

      if (LocationService.isCloseEnough(distance, reminder.radius)) {
        await NotificationService.showNotification(
          "Proximity Alert!",
          "You have reached ${reminder.title}.",
        );
      } else {
        String distString = distance > 1000
            ? "${(distance / 1000).toStringAsFixed(1)} km"
            : "${distance.toInt()} meters";

        final alarmSettings = AlarmSettings(
          id: key,
          dateTime: DateTime.now(),
          assetAudioPath: 'assets/alarm.mp3',
          loopAudio: true,
          vibrate: true,
          volumeSettings: VolumeSettings.fade(
            volume: 1,
            fadeDuration: Duration(seconds: 3),
            volumeEnforced: false,
          ),
          notificationSettings: NotificationSettings(
            title: 'Proximity Alert',
            body: 'Time for ${reminder.title}, but you are $distString away!',
            stopButton: 'Stop the alarm',
            icon: 'notification_icon',
          ),
        );

        await Alarm.set(alarmSettings: alarmSettings);
      }

      final updatedReminder = Reminder(
        title: reminder.title,
        latitude: reminder.latitude,
        longitude: reminder.longitude,
        radius: reminder.radius,
        hour: reminder.hour,
        minute: reminder.minute,
        lastTriggeredDate: now,
        isActive: reminder.isActive,
        isMonday: reminder.isMonday,
        isTuesday: reminder.isTuesday,
        isWednesday: reminder.isWednesday,
        isThursday: reminder.isThursday,
        isFriday: reminder.isFriday,
        isSaturday: reminder.isSaturday,
        isSunday: reminder.isSunday,
      );

      await box.put(key, updatedReminder);
    }
  }
}
