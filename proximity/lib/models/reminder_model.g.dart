// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReminderAdapter extends TypeAdapter<Reminder> {
  @override
  final int typeId = 0;

  @override
  Reminder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Reminder(
      title: fields[0] as String,
      latitude: fields[1] as double,
      longitude: fields[2] as double,
      radius: fields[3] as double,
      isActive: fields[4] as bool,
      hour: fields[5] as int,
      minute: fields[6] as int,
      isMonday: fields[7] as bool,
      isTuesday: fields[8] as bool,
      isWednesday: fields[9] as bool,
      isThursday: fields[10] as bool,
      isFriday: fields[11] as bool,
      isSaturday: fields[12] as bool,
      isSunday: fields[13] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Reminder obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.latitude)
      ..writeByte(2)
      ..write(obj.longitude)
      ..writeByte(3)
      ..write(obj.radius)
      ..writeByte(4)
      ..write(obj.isActive)
      ..writeByte(5)
      ..write(obj.hour)
      ..writeByte(6)
      ..write(obj.minute)
      ..writeByte(7)
      ..write(obj.isMonday)
      ..writeByte(8)
      ..write(obj.isTuesday)
      ..writeByte(9)
      ..write(obj.isWednesday)
      ..writeByte(10)
      ..write(obj.isThursday)
      ..writeByte(11)
      ..write(obj.isFriday)
      ..writeByte(12)
      ..write(obj.isSaturday)
      ..writeByte(13)
      ..write(obj.isSunday);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
