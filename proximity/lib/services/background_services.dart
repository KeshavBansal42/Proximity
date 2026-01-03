import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:alarm/alarm.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:audio_session/audio_session.dart';
import '../models/reminder_model.dart';
import 'database_service.dart';
import 'notification_service.dart';
import 'location_service.dart';

@pragma('vm:entry-point')
Future<void> callback() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await DatabaseService.init();
    await NotificationService.init();
    await Alarm.init();
  } catch (e) {
    print("Error initializing background services: $e");
    return;
  }

  bool upcomingAlarmDetected = false;
  Position? position;

  try {
    position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 5),
      ),
    );
  } catch (e) {
    print("Error getting location in background: $e");
  }

  final box = DatabaseService.getBox();
  final keys = box.keys.toList();

  if (keys.isNotEmpty) {
    final now = DateTime.now();
    final nowInMinutes = now.hour * 60 + now.minute;

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

      final currentDayBit = now.weekday % 7;

      bool isToday = (reminder.activeDays >> currentDayBit) & 1 == 1;
      if (!isToday) continue;

      int reminderInMinutes = reminder.hour * 60 + reminder.minute;
      int diff = nowInMinutes - reminderInMinutes;

      if (diff < -1000) diff += 1440;
      if (diff > 1000) diff -= 1440;

      if (diff >= -30 && diff <= 5) {
        upcomingAlarmDetected = true;
      }

      if (diff < 0 || diff > 2) {
        continue;
      }

      bool userIsClose = false;
      String distString = "Unknown Location";

      if (position != null) {
        double distance = LocationService.getDistance(
          lat1: position.latitude,
          lon1: position.longitude,
          lat2: reminder.latitude,
          lon2: reminder.longitude,
        );
        userIsClose = LocationService.isCloseEnough(distance, reminder.radius);
        distString = distance > 1000
            ? "${(distance / 1000).toStringAsFixed(1)} km"
            : "${distance.toInt()} meters";
      } else {
        userIsClose = false;
      }

      if (userIsClose) {
        await NotificationService.showNotification(
          "Proximity Alert!",
          "You have reached ${reminder.title}.",
        );
      } else {
        try {
          final session = await AudioSession.instance;
          await session.configure(const AudioSessionConfiguration(
            avAudioSessionCategory: AVAudioSessionCategory.playback,
            avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.none,
            androidAudioAttributes: AndroidAudioAttributes(
              contentType: AndroidAudioContentType.speech,
              usage: AndroidAudioUsage.assistanceNavigationGuidance,
            ),
            androidAudioFocusGainType:
                AndroidAudioFocusGainType.gainTransientExclusive,
          ));
          await session.setActive(true);
        } catch (e) {
          print("Error configuring audio session: $e");
        }

        await Alarm.stop(key + 1);

        final alarmSettings = AlarmSettings(
          id: key + 1,
          dateTime: DateTime.now(),
          assetAudioPath: reminder.audioPath ?? 'assets/alarm.mp3',
          loopAudio: true,
          vibrate: true,
          volumeSettings: VolumeSettings.fixed(
            volume: 1.0,
            volumeEnforced: false,
          ),
          notificationSettings: NotificationSettings(
            title: 'Proximity Alert',
            body: 'Time for ${reminder.title}. Distance: $distString',
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
        activeDays: reminder.activeDays,
        audioPath: reminder.audioPath,
      );

      await box.put(key, updatedReminder);
      await box.flush();
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  await box.close();

  int nextInterval = upcomingAlarmDetected ? 1 : 15;

  await AndroidAlarmManager.oneShot(
    Duration(minutes: nextInterval),
    0,
    callback,
    wakeup: true,
    exact: true,
    rescheduleOnReboot: true,
  );
}