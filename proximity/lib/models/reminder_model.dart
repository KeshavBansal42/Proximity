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
  final bool isMonday;

  @HiveField(8)
  final bool isTuesday;

  @HiveField(9)
  final bool isWednesday;

  @HiveField(10)
  final bool isThursday;

  @HiveField(11)
  final bool isFriday;

  @HiveField(12)
  final bool isSaturday;

  @HiveField(13)
  final bool isSunday;

  Reminder({
    required this.title,
    required this.latitude,
    required this.longitude,
    required this.radius,
    this.isActive = true,
    required this.hour,
    required this.minute,
    this.isMonday=true,
    this.isTuesday=true,
    this.isWednesday=true,
    this.isThursday=true,
    this.isFriday=true,
    this.isSaturday=true,
    this.isSunday=true,
  });
}