import 'package:geolocator/geolocator.dart';
import '../models/reminder_model.dart';
import 'database_service.dart';
import 'notification_service.dart';
import 'location_service.dart';
import 'package:alarm/alarm.dart';

@pragma('vm:entry-point')
Future<void> callback() async {
  print("Background Service: Waking up...");

  await DatabaseService.init();
  await NotificationService.init();
  await Alarm.init();

  Position? position;
  try {
    position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );
  } catch (e) {
    print("Background Error: Could not get location ($e)");
    return;
  }

  final box = DatabaseService.getBox();
  final keys = box.keys.toList();

  if (keys.isEmpty) return;

  for (var key in keys) {
    final reminder = box.get(key);

    if (reminder == null) continue;
    if (!reminder.isActive) continue;

    final now = DateTime.now();

    bool isHourMatch = now.hour == reminder.hour;
    bool isMinuteInRange =
        (now.minute >= reminder.minute) && (now.minute <= reminder.minute + 15);

    if (!isHourMatch || !isMinuteInRange) {
      continue;
    }

    double distance = LocationService.getDistance(
      lat1: position.latitude,
      lon1: position.longitude,
      lat2: reminder.latitude,
      lon2: reminder.longitude,
    );

    print("Checking '${reminder.title}': Distance is $distance meters");

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
          volumeEnforced: true,
        ),
        notificationSettings: NotificationSettings(
          title: 'Proximity Alert',
          body: 'Time for ${reminder.title}, but you are $distString away!',
          stopButton: 'Stop the alarm',
          icon: 'notification_icon',
          // iconColor: Color(0xff862778),
        ),
      );

      await Alarm.set(alarmSettings: alarmSettings);
    }

    final disabledReminder = Reminder(
      title: reminder.title,
      latitude: reminder.latitude,
      longitude: reminder.longitude,
      radius: reminder.radius,
      hour: reminder.hour,
      minute: reminder.minute,
      isActive: false,
    );

    await box.put(key, disabledReminder);
  }
}
