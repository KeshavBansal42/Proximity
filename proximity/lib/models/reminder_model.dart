import 'package:hive/hive.dart';

part 'reminder_model.g.dart';

@HiveType(typeId: 0)
class Reminder{
  @HiveField(0)
  final String title;

  @HiveField(1)
  final double latitude;

  @HiveField(2)
  final double longitude;

  @HiveField(3)
  final double radius;

  @HiveField(4)
  final bool isActive;

  @HiveField(5)
  final int hour;
  
  @HiveField(6)
  final int minute;

  @HiveField(7)
  final int activeDays;

  @HiveField(8)
  final DateTime? lastTriggeredDate;

  @HiveField(9)
  final String? audioPath;

  Reminder({
    required this.title,
    required this.latitude,
    required this.longitude,
    required this.radius,
    this.isActive = true,
    required this.hour,
    required this.minute,
    required this.activeDays,
    this.lastTriggeredDate,
    this.audioPath,
  });
}