import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

// part 'location_option.g.dart'; // For Hive generator if used, otherwise manual adapter

// @HiveType(typeId: 3) // Not strictly needed for manual adapter if not using generator
class LocationOption /* extends HiveObject */ { // Removed HiveObject
  // @HiveField(0) // Not strictly needed for manual adapter
  final String id;

  // @HiveField(1) // Not strictly needed for manual adapter
  final String name;

  LocationOption({
    String? id,
    required this.name,
  }) : id = id ?? const Uuid().v4();

  LocationOption copyWith({
    String? id,
    String? name,
  }) {
    return LocationOption(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  factory LocationOption.fromJson(Map<String, dynamic> json) {
    return LocationOption(
      id: json['id'] as String?,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationOption &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;

  @override
  String toString() {
    return 'LocationOption{id: $id, name: $name}';
  }
}

// Manual TypeAdapter implementation (if not using build_runner for .g.dart)
class LocationOptionAdapter extends TypeAdapter<LocationOption> {
  @override
  final int typeId = 3;

  @override
  LocationOption read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocationOption(
      id: fields[0] as String,
      name: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, LocationOption obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name);
  }
} 