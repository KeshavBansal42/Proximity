import 'package:hive_flutter/hive_flutter.dart';
import '../models/reminder_model.dart';
import '../models/saved_location_model.dart';

class DatabaseService {
  static const String _boxname = "reminders";
  static const String _locationBoxName = "saved_locations";

  static Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ReminderAdapter());
    }

    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(SavedLocationAdapter());
    }

    if (!Hive.isBoxOpen(_boxname)) {
      await Hive.openBox<Reminder>(_boxname);
    }
    if (!Hive.isBoxOpen(_locationBoxName)) {
      await Hive.openBox<SavedLocation>(_locationBoxName);
    }
  }

  static Box<Reminder> getBox() {
    return Hive.box<Reminder>(_boxname);
  }

  static Box<SavedLocation> getLocationBox() {
    return Hive.box<SavedLocation>(_locationBoxName);
  }

  static Future<void> addLocation(SavedLocation location) async {
    final box = getLocationBox();
    await box.add(location);
  }

  static Future<void> addReminder(Reminder task) async {
    await getBox().add(task);
  }

  static List<Reminder> getAllReminders() {
    return getBox().values.toList();
  }
}
