import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';

class Participant {
  final String id;
  final String name;
  final String? email;
  final List<String> availableTimeSlots;
  final List<String> preferredLocationIds;
  final String? comment;
  final String? suggestedTime;
  final String? suggestedLocation;
  final String? avatar;
  final DateTime responseTime;
  
  Participant({
    String? id,
    required this.name,
    this.email,
    List<String>? availableTimeSlots,
    List<String>? preferredLocationIds,
    this.comment,
    this.suggestedTime,
    this.suggestedLocation,
    this.avatar,
    DateTime? responseTime,
  }) : 
    id = id ?? const Uuid().v4(),
    availableTimeSlots = availableTimeSlots ?? [],
    preferredLocationIds = preferredLocationIds ?? [],
    responseTime = responseTime ?? DateTime.now();
  
  // 添加可用時間
  Participant addAvailableTimeSlot(String timeSlotId) {
    if (availableTimeSlots.contains(timeSlotId)) {
      return this;
    }
    return copyWith(
      availableTimeSlots: [...availableTimeSlots, timeSlotId],
    );
  }
  
  // 移除可用時間
  Participant removeAvailableTimeSlot(String timeSlotId) {
    if (!availableTimeSlots.contains(timeSlotId)) {
      return this;
    }
    return copyWith(
      availableTimeSlots: availableTimeSlots.where((id) => id != timeSlotId).toList(),
    );
  }
  
  // 添加偏好地點
  Participant addPreferredLocation(String locationId) {
    if (preferredLocationIds.contains(locationId)) {
      return this;
    }
    return copyWith(
      preferredLocationIds: [...preferredLocationIds, locationId],
    );
  }
  
  // 移除偏好地點
  Participant removePreferredLocation(String locationId) {
    if (!preferredLocationIds.contains(locationId)) {
      return this;
    }
    return copyWith(
      preferredLocationIds: preferredLocationIds.where((id) => id != locationId).toList(),
    );
  }
  
  // 從 JSON 創建 Participant
  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      availableTimeSlots: List<String>.from(json['availableTimeSlots'] ?? []),
      preferredLocationIds: List<String>.from(json['preferredLocationIds'] ?? []),
      comment: json['comment'],
      suggestedTime: json['suggestedTime'],
      suggestedLocation: json['suggestedLocation'],
      avatar: json['avatar'],
      responseTime: json['responseTime'] != null
          ? DateTime.parse(json['responseTime'])
          : DateTime.now(),
    );
  }
  
  // 轉換為 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'availableTimeSlots': availableTimeSlots,
      'preferredLocationIds': preferredLocationIds,
      'comment': comment,
      'suggestedTime': suggestedTime,
      'suggestedLocation': suggestedLocation,
      'avatar': avatar,
      'responseTime': responseTime.toIso8601String(),
    };
  }
  
  // 創建 Participant 副本
  Participant copyWith({
    String? id,
    String? name,
    String? email,
    List<String>? availableTimeSlots,
    List<String>? preferredLocationIds,
    String? comment,
    String? suggestedTime,
    String? suggestedLocation,
    String? avatar,
    DateTime? responseTime,
  }) {
    return Participant(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      availableTimeSlots: availableTimeSlots ?? this.availableTimeSlots,
      preferredLocationIds: preferredLocationIds ?? this.preferredLocationIds,
      comment: comment ?? this.comment,
      suggestedTime: suggestedTime ?? this.suggestedTime,
      suggestedLocation: suggestedLocation ?? this.suggestedLocation,
      avatar: avatar ?? this.avatar,
      responseTime: responseTime ?? this.responseTime,
    );
  }
  
  // 為Hive提供TypeAdapter
  static TypeAdapter<Participant> participantAdapter() {
    return _ParticipantAdapter();
  }
}

class _ParticipantAdapter extends TypeAdapter<Participant> {
  @override
  final int typeId = 2;
  
  @override
  Participant read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    return Participant(
      id: fields[0] as String,
      name: fields[1] as String,
      email: fields[2] as String?,
      availableTimeSlots: (fields[3] as List?)?.cast<String>() ?? [],
      preferredLocationIds: (fields[4] as List?)?.cast<String>() ?? [],
      comment: fields[5] as String?,
      suggestedTime: fields[6] as String?,
      suggestedLocation: fields[7] as String?,
      avatar: fields[8] as String?,
      responseTime: fields[9] as DateTime,
    );
  }
  
  @override
  void write(BinaryWriter writer, Participant obj) {
    writer.writeByte(10);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.name);
    writer.writeByte(2);
    writer.write(obj.email);
    writer.writeByte(3);
    writer.write(obj.availableTimeSlots);
    writer.writeByte(4);
    writer.write(obj.preferredLocationIds);
    writer.writeByte(5);
    writer.write(obj.comment);
    writer.writeByte(6);
    writer.write(obj.suggestedTime);
    writer.writeByte(7);
    writer.write(obj.suggestedLocation);
    writer.writeByte(8);
    writer.write(obj.avatar);
    writer.writeByte(9);
    writer.write(obj.responseTime);
  }
} 