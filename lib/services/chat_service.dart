import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../models/chat_message.dart';

// 提供聊天服務的Provider
final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

// 特定事件聊天消息的Provider
final eventChatMessagesProvider = StateNotifierProvider.family<ChatMessagesNotifier, List<ChatMessage>, String>(
  (ref, eventId) => ChatMessagesNotifier(eventId),
);

/// 聊天服務類，用於管理聊天消息
class ChatService {
  // 目前使用內存中的消息存儲，後續會替換為Supabase
  final Map<String, List<ChatMessage>> _messagesByEvent = {};

  // 獲取事件的所有消息
  List<ChatMessage> getEventMessages(String eventId) {
    return _messagesByEvent[eventId] ?? [];
  }

  // 發送新消息
  Future<ChatMessage> sendMessage(ChatMessage message) async {
    // 模擬網絡延遲
    await Future.delayed(const Duration(milliseconds: 300));
    
    // 如果事件尚未有消息列表，創建一個新的
    if (!_messagesByEvent.containsKey(message.eventId)) {
      _messagesByEvent[message.eventId] = [];
    }
    
    // 添加消息到列表
    _messagesByEvent[message.eventId]!.add(message);
    
    // 返回已發送的消息
    return message;
    
    // TODO: 當整合Supabase時，將替換為實際的API調用
    // return supabase
    //   .from('messages')
    //   .insert(message.toJson())
    //   .select()
    //   .single()
    //   .then((data) => ChatMessage.fromJson(data));
  }

  // 標記消息為已讀
  Future<void> markAsRead(String messageId, String userId) async {
    // 模擬網絡延遲
    await Future.delayed(const Duration(milliseconds: 200));
    
    // 查找並更新消息
    for (final eventId in _messagesByEvent.keys) {
      final messages = _messagesByEvent[eventId]!;
      for (int i = 0; i < messages.length; i++) {
        if (messages[i].id == messageId) {
          messages[i] = messages[i].markAsRead(userId);
          break;
        }
      }
    }
    
    // TODO: 當整合Supabase時，將替換為實際的API調用
    // return supabase
    //   .from('messages')
    //   .update({'read_by': supabase.rpc('array_append', params: {'arr': message.readBy, 'item': userId})})
    //   .eq('id', messageId);
  }

  // 為後續Supabase整合，添加實時訂閱功能
  Stream<List<ChatMessage>> subscribeToEventMessages(String eventId) {
    // 目前返回一個模擬的流
    // 使用定時器每3秒返回一次當前事件的消息列表
    final controller = StreamController<List<ChatMessage>>();
    
    // 初始數據
    controller.add(getEventMessages(eventId));
    
    // 創建定時器模擬實時更新
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (controller.isClosed) {
        timer.cancel();
        return;
      }
      controller.add(getEventMessages(eventId));
    });
    
    // 關閉時取消定時器
    controller.onCancel = () {
      // 清理資源
    };
    
    return controller.stream;
    
    // TODO: 當整合Supabase時，將替換為實際的實時訂閱
    // return supabase
    //   .from('messages')
    //   .stream(primaryKey: ['id'])
    //   .eq('event_id', eventId)
    //   .order('timestamp')
    //   .map((data) => data.map((item) => ChatMessage.fromJson(item)).toList());
  }

  // 獲取特定消息
  Future<ChatMessage?> getMessage(String messageId) async {
    // 遍歷所有事件消息尋找特定ID的消息
    for (final eventId in _messagesByEvent.keys) {
      for (final message in _messagesByEvent[eventId]!) {
        if (message.id == messageId) {
          return message;
        }
      }
    }
    return null;
    
    // TODO: 當整合Supabase時，將替換為實際的API調用
    // return supabase
    //   .from('messages')
    //   .select()
    //   .eq('id', messageId)
    //   .maybeSingle()
    //   .then((data) => data != null ? ChatMessage.fromJson(data) : null);
  }

  // 刪除消息
  Future<void> deleteMessage(String messageId) async {
    // 遍歷所有事件消息刪除特定ID的消息
    for (final eventId in _messagesByEvent.keys) {
      _messagesByEvent[eventId] = _messagesByEvent[eventId]!
          .where((message) => message.id != messageId)
          .toList();
    }
    
    // TODO: 當整合Supabase時，將替換為實際的API調用
    // return supabase
    //   .from('messages')
    //   .delete()
    //   .eq('id', messageId);
  }

  // 添加刷新消息方法
  void refreshMessages() {
    // 這裡可以從本地或遠程數據來源重新加載消息
    // 對於演示目的，我們可以簡單地實現一個空方法
    
    // 如果使用 Supabase 或其他後端，可以在此處發起網絡請求
    // 例如:
    // final response = await _supabaseClient.from('messages').select().eq('event_id', eventId);
    // final messages = response.map((m) => ChatMessage.fromJson(m)).toList();
    // state = messages;
    
    // 臨時實現：不做任何改變，只是標記方法已實現
  }
}

/// 管理特定事件聊天消息的StateNotifier
class ChatMessagesNotifier extends StateNotifier<List<ChatMessage>> {
  final String eventId;
  
  ChatMessagesNotifier(this.eventId) : super([]) {
    // 載入初始數據，可以從本地或Mock數據開始
    _loadInitialMessages();
  }

  void _loadInitialMessages() {
    // 這裡我們設置一些示例消息
    // 在實際實現中，這將從Supabase獲取
    final now = DateTime.now();
    
    state = [
      ChatMessage(
        eventId: eventId,
        senderId: 'system',
        senderName: 'System',
        content: '歡迎來到活動聊天室！',
        timestamp: now.subtract(const Duration(days: 1)),
      ),
      ChatMessage(
        eventId: eventId,
        senderId: 'user1',
        senderName: '張小明',
        content: '大家好，我是張小明！',
        timestamp: now.subtract(const Duration(hours: 5)),
      ),
      ChatMessage(
        eventId: eventId,
        senderId: 'user2',
        senderName: '李小華',
        content: '你好啊，很高興認識大家！',
        timestamp: now.subtract(const Duration(hours: 4)),
      ),
      ChatMessage(
        eventId: eventId,
        senderId: 'user3',
        senderName: '王大明',
        content: '我們何時確定最終時間和地點？',
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
      ChatMessage(
        eventId: eventId,
        senderId: 'user1',
        senderName: '張小明',
        content: '我們先討論一下各自的偏好吧？',
        timestamp: now.subtract(const Duration(hours: 1)),
      ),
    ];
  }

  // 添加新消息
  void addMessage(ChatMessage message) {
    state = [...state, message];
  }
  
  // 當收到新消息時更新狀態
  void updateMessages(List<ChatMessage> messages) {
    state = messages;
  }
  
  // 標記消息為已讀
  void markAsRead(String messageId, String userId) {
    state = state.map((message) => 
      message.id == messageId ? message.markAsRead(userId) : message
    ).toList();
  }
} 