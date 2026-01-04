import 'package:hive/hive.dart';

part 'saved_location_model.g.dart';

@HiveType(typeId: 1)
class SavedLocation {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final double latitude;

  @HiveField(2)
  final double longitude;

  SavedLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}