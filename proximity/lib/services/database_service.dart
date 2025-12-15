import 'package:hive_flutter/hive_flutter.dart';
import '../models/reminder_model.dart';

class DatabaseService {
  static const String _boxname = "reminders";

  static Future<void> init() async{
    await Hive.initFlutter();

    Hive.registerAdapter(ReminderAdapter());

    await Hive.openBox<Reminder>(_boxname);
  }

  static Box<Reminder> getBox(){
    return Hive.box<Reminder>(_boxname);
  }

  static Future<void> addReminder(Reminder task) async {
    await getBox().add(task);
  }

  static List<Reminder> getAllReminders() {
    return getBox().values.toList();
  }
}