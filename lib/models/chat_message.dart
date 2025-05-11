import 'package:uuid/uuid.dart';

/// 聊天訊息模型
class ChatMessage {
  final String id;
  final String eventId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final List<String> readBy;
  final String? senderAvatar; // 可選的發送者頭像URL

  ChatMessage({
    String? id,
    required this.eventId,
    required this.senderId,
    required this.senderName,
    required this.content,
    DateTime? timestamp,
    List<String>? readBy,
    this.senderAvatar,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.timestamp = timestamp ?? DateTime.now(),
    this.readBy = readBy ?? [];

  // 複製帶有更新的ChatMessage實例
  ChatMessage copyWith({
    String? id,
    String? eventId,
    String? senderId,
    String? senderName,
    String? content,
    DateTime? timestamp,
    List<String>? readBy,
    String? senderAvatar,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      readBy: readBy ?? this.readBy,
      senderAvatar: senderAvatar ?? this.senderAvatar,
    );
  }

  // 從JSON創建ChatMessage
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      eventId: json['event_id'],
      senderId: json['sender_id'],
      senderName: json['sender_name'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      readBy: List<String>.from(json['read_by'] ?? []),
      senderAvatar: json['sender_avatar'],
    );
  }

  // 轉換為JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'sender_id': senderId,
      'sender_name': senderName,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'read_by': readBy,
      'sender_avatar': senderAvatar,
    };
  }

  // 檢查是否被特定用戶閱讀
  bool isReadBy(String userId) {
    return readBy.contains(userId);
  }

  // 標記為已讀
  ChatMessage markAsRead(String userId) {
    if (isReadBy(userId)) {
      return this;
    }
    final newReadBy = List<String>.from(readBy)..add(userId);
    return copyWith(readBy: newReadBy);
  }
} 