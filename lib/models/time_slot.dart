import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';

class TimeSlot {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  
  TimeSlot({
    String? id,
    required this.startTime,
    required this.endTime,
  }) : id = id ?? Uuid().v4();
  
  // 檢查兩個時間段是否重疊
  bool overlapsWith(TimeSlot other) {
    return (startTime.isBefore(other.endTime) || startTime.isAtSameMomentAs(other.endTime)) && 
           (endTime.isAfter(other.startTime) || endTime.isAtSameMomentAs(other.startTime));
  }
  
  // 返回格式化的日期，包括星期
  String getFormattedDate() {
    return DateFormat('EEEE, MMM d, yyyy').format(startTime);
  }
  
  // 返回格式化的時間範圍
  String getFormattedTimeRange() {
    final timeFormatter = DateFormat('HH:mm');
    return '${timeFormatter.format(startTime)} - ${timeFormatter.format(endTime)}';
  }
  
  // 返回相對日期（今天、明天等）
  String getRelativeDay() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dayAfterTomorrow = today.add(const Duration(days: 2));
    final slotDay = DateTime(startTime.year, startTime.month, startTime.day);
    
    if (slotDay.isAtSameMomentAs(today)) {
      return 'Today';
    } else if (slotDay.isAtSameMomentAs(tomorrow)) {
      return 'Tomorrow';
    } else if (slotDay.isAtSameMomentAs(dayAfterTomorrow)) {
      return 'Day after tomorrow';
    } else {
      final formatter = DateFormat('MMM d');
      return formatter.format(startTime);
    }
  }
  
  // 從JSON創建TimeSlot
  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      id: json['id'] as String?,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
    );
  }
  
  // 轉換為JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
    };
  }
  
  // 複製物件方法
  TimeSlot copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return TimeSlot(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeSlot && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}

class TimeSlotAdapter extends TypeAdapter<TimeSlot> {
  @override
  final int typeId = 1;
  
  @override
  TimeSlot read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    return TimeSlot(
      id: fields[0] as String?,
      startTime: fields[1] as DateTime,
      endTime: fields[2] as DateTime,
    );
  }
  
  @override
  void write(BinaryWriter writer, TimeSlot obj) {
    writer.writeByte(3);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.startTime);
    writer.writeByte(2);
    writer.write(obj.endTime);
  }
} 