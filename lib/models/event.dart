import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';
import 'time_slot.dart';
import 'participant.dart';
import 'location_option.dart';

class Event {
  final String id;
  final String title;
  final String? description;
  final List<LocationOption> locationOptions;
  final List<TimeSlot> timeSlots;
  final List<Participant> participants;
  final DateTime createdAt;
  final String? creatorId;
  final String? shareCode;
  final String? creator;
  final bool isFinalized;

  Event({
    String? id,
    required this.title,
    this.description,
    List<LocationOption>? locationOptions,
    required this.timeSlots,
    List<Participant>? participants,
    DateTime? createdAt,
    this.creatorId,
    String? shareCode,
    this.creator,
    this.isFinalized = false,
  }) : 
    id = id ?? const Uuid().v4(),
    locationOptions = locationOptions ?? [],
    participants = participants ?? [],
    createdAt = createdAt ?? DateTime.now(),
    shareCode = shareCode ?? _generateShareCode();
  
  // 生成分享鏈接
  String getShareLink() {
    return 'https://timesync.app/join/$shareCode';
  }
  
  bool get isPast {
    if (isFinalized && timeSlots.isEmpty) {
      // If finalized and has no time slots, consider it past if older than a threshold (e.g. 7 days)
      // This handles cases where an event might be created and finalized without specific times,
      // or old events that were finalized.
      return createdAt.isBefore(DateTime.now().subtract(const Duration(days: 7)));
    }
    if (timeSlots.isEmpty) {
      // If no time slots and not finalized, it's hard to determine if it's "past".
      // Let's assume it's not past unless explicitly finalized or very old without activity.
      // For a more robust check, one might need an explicit expiry date or rely on finalization.
      return false; 
    }
    // Event is past if all its time slots' end times are before now.
    return timeSlots.every((slot) => slot.endTime.isBefore(DateTime.now()));
  }

  bool get isHappeningSoon {
    if (timeSlots.isEmpty || isPast || isFinalized) {
      return false;
    }
    final now = DateTime.now();
    // Happening "soon" if the earliest start time is within the next 24 hours
    // and not in the past.
    // It should also not be finalized.
    return timeSlots.any((slot) =>
        slot.startTime.isAfter(now) &&
        slot.startTime.isBefore(now.add(const Duration(days: 1))));
  }
  
  // 獲取每個時間段的可用人數
  Map<String, int> getTimeSlotAvailability() {
    if (timeSlots.isEmpty || participants.isEmpty) {
      return {};
    }

    final Map<String, int> availability = {};
    for (final timeSlot in timeSlots) {
      availability[timeSlot.id] = 0;
    }

    for (final participant in participants) {
      for (final timeSlotId in participant.availableTimeSlots) {
        if (availability.containsKey(timeSlotId)) {
          availability[timeSlotId] = availability[timeSlotId]! + 1;
        }
      }
    }

    return availability;
  }
  
  // 獲取每個地點的投票數
  Map<String, int> getLocationVotes() {
    if (locationOptions.isEmpty || participants.isEmpty) {
      return {};
    }
    
    final Map<String, int> votes = {};
    for (final locOpt in locationOptions) {
      votes[locOpt.id] = 0;
    }
    
    for (final participant in participants) {
      for (final locationIdInVote in participant.preferredLocationIds) {
        if (votes.containsKey(locationIdInVote)) {
          votes[locationIdInVote] = votes[locationIdInVote]! + 1;
        }
      }
      
      if (participant.suggestedLocation != null && participant.suggestedLocation!.isNotEmpty) {
        final existingOption = locationOptions.firstWhere(
          (opt) => opt.name.toLowerCase() == participant.suggestedLocation!.toLowerCase(),
          orElse: () => LocationOption(id: 'temporary_nil_id', name: 'temporary_nil_name')
        );
        if (existingOption.id != 'temporary_nil_id' && votes.containsKey(existingOption.id)) {
           votes[existingOption.id] = votes[existingOption.id]! + 1;
        }
      }
    }
    
    return votes;
  }
  
  // 獲取根據投票數排序的地點列表
  List<MapEntry<LocationOption, int>> getSortedLocationVotesWithOptions() {
    final votesById = getLocationVotes();
    final List<MapEntry<LocationOption, int>> sortedEntries = [];

    for (final locOpt in locationOptions) {
      sortedEntries.add(MapEntry(locOpt, votesById[locOpt.id] ?? 0));
    }
    
    sortedEntries.sort((a, b) => b.value.compareTo(a.value));
    return sortedEntries;
  }
  
  // 獲取推薦的地點名稱和投票數
  List<LocationOption> getBestLocations() {
    return getSortedLocationVotesWithOptions().map((entry) => entry.key).toList();
  }
  
  // 獲取建議的時間和地點
  Map<String, List<String>> getSuggestedOptions() {
    final List<String> suggestedTimes = [];
    final List<String> suggestedLocations = [];
    
    for (final participant in participants) {
      if (participant.suggestedTime != null && 
          participant.suggestedTime!.isNotEmpty && 
          !suggestedTimes.contains(participant.suggestedTime)) {
        suggestedTimes.add(participant.suggestedTime!);
      }
      
      if (participant.suggestedLocation != null && 
          participant.suggestedLocation!.isNotEmpty && 
          !suggestedLocations.contains(participant.suggestedLocation)) {
        bool isExistingOption = locationOptions.any((opt) => opt.name.toLowerCase() == participant.suggestedLocation!.toLowerCase());
        if (!isExistingOption) {
            suggestedLocations.add(participant.suggestedLocation!);
        }
      }
    }
    
    return {
      'times': suggestedTimes,
      'locations': suggestedLocations,
    };
  }
  
  // 取得最佳時間段（根據參與者可用性排序）
  List<TimeSlot> getBestTimeSlots() {
    if (timeSlots.isEmpty) {
      return [];
    }

    final availability = getTimeSlotAvailability();
    final sortedTimeSlots = List<TimeSlot>.from(timeSlots);
    sortedTimeSlots.sort((a, b) {
      final aCount = availability[a.id] ?? 0;
      final bCount = availability[b.id] ?? 0;
      if (aCount != bCount) {
        return bCount.compareTo(aCount); // 先以參與人數排序（降序）
      }
      return a.startTime.compareTo(b.startTime); // 如果人數相同，則按時間排序
    });

    return sortedTimeSlots;
  }
  
  // ADDED: Get the finalized time slot (placeholder implementation)
  TimeSlot? getFinalizedTimeSlot() {
    if (isFinalized && timeSlots.isNotEmpty) {
      // Placeholder: returns the first time slot if finalized.
      // TODO: Implement proper logic to identify the actual chosen time slot if applicable,
      // e.g., based on a chosenTimeSlotId field or highest votes if that\'s how finalization works.
      return timeSlots.first;
    }
    return null;
  }
  
  // 獲取特定時間段的可用參與者
  List<Participant> getAvailableParticipants(String timeSlotId) {
    return participants.where(
      (participant) => participant.availableTimeSlots.contains(timeSlotId)
    ).toList();
  }
  
  // 添加參與者
  Event addParticipant(Participant participant) {
    return copyWith(
      participants: [...participants, participant],
    );
  }
  
  // 添加時間段
  Event addTimeSlot(TimeSlot timeSlot) {
    return copyWith(
      timeSlots: [...timeSlots, timeSlot],
    );
  }
  
  // 從 JSON 創建 Event
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      locationOptions: (json['locationOptions'] as List<dynamic>?)
          ?.map((loc) => LocationOption.fromJson(loc as Map<String, dynamic>))
          .toList() ?? [],
      timeSlots: (json['timeSlots'] as List<dynamic>?)
          ?.map((timeSlot) => TimeSlot.fromJson(timeSlot as Map<String, dynamic>))
          .toList() ?? [],
      participants: (json['participants'] as List<dynamic>?)
          ?.map((participant) => Participant.fromJson(participant as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      creatorId: json['creatorId'] as String?,
      shareCode: json['shareCode'] as String?,
      creator: json['creator'] as String?,
      isFinalized: json['isFinalized'] as bool? ?? false,
    );
  }
  
  // 轉換為 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'locationOptions': locationOptions.map((loc) => loc.toJson()).toList(),
      'timeSlots': timeSlots.map((timeSlot) => timeSlot.toJson()).toList(),
      'participants': participants.map((participant) => participant.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'creatorId': creatorId,
      'shareCode': shareCode,
      'creator': creator,
      'isFinalized': isFinalized,
    };
  }
  
  // 創建 Event 副本
  Event copyWith({
    String? id,
    String? title,
    String? description,
    List<LocationOption>? locationOptions,
    List<TimeSlot>? timeSlots,
    List<Participant>? participants,
    DateTime? createdAt,
    String? creatorId,
    String? shareCode,
    String? creator,
    bool? isFinalized,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      locationOptions: locationOptions ?? this.locationOptions,
      timeSlots: timeSlots ?? this.timeSlots,
      participants: participants ?? this.participants,
      createdAt: createdAt ?? this.createdAt,
      creatorId: creatorId ?? this.creatorId,
      shareCode: shareCode ?? this.shareCode,
      creator: creator ?? this.creator,
      isFinalized: isFinalized ?? this.isFinalized,
    );
  }
  
  // 生成分享代碼
  static String _generateShareCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final code = StringBuffer();
    
    for (var i = 0; i < 6; i++) {
      code.write(chars[random.nextInt(chars.length)]);
    }
    
    return code.toString();
  }
  
  // 為Hive提供TypeAdapter
  static TypeAdapter<Event> eventAdapter() {
    return _EventAdapter();
  }
}

class _EventAdapter extends TypeAdapter<Event> {
  @override
  final int typeId = 0;
  
  @override
  Event read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    return Event(
      id: fields[0] as String?,
      title: fields[1] as String,
      description: fields[2] as String?,
      locationOptions: (fields[3] as List?)?.cast<LocationOption>() ?? [],
      timeSlots: (fields[4] as List?)?.cast<TimeSlot>() ?? [],
      participants: (fields[5] as List?)?.cast<Participant>() ?? [],
      createdAt: fields[6] as DateTime?,
      creatorId: fields[7] as String?,
      shareCode: fields[8] as String?,
      creator: fields[9] as String?,
      isFinalized: fields[10] as bool? ?? false,
    );
  }
  
  @override
  void write(BinaryWriter writer, Event obj) {
    writer.writeByte(11);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.title);
    writer.writeByte(2);
    writer.write(obj.description);
    writer.writeByte(3);
    writer.write(obj.locationOptions);
    writer.writeByte(4);
    writer.write(obj.timeSlots);
    writer.writeByte(5);
    writer.write(obj.participants);
    writer.writeByte(6);
    writer.write(obj.createdAt);
    writer.writeByte(7);
    writer.write(obj.creatorId);
    writer.writeByte(8);
    writer.write(obj.shareCode);
    writer.writeByte(9);
    writer.write(obj.creator);
    writer.writeByte(10);
    writer.write(obj.isFinalized);
  }
} 