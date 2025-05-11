import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/event.dart';
import '../models/time_slot.dart';
import '../models/participant.dart';

const String _eventsBoxName = 'eventsBox';

// 事件狀態
class EventsState {
  final List<Event> events;
  final bool isLoading;
  final String? error;

  EventsState({
    this.events = const [],
    this.isLoading = false,
    this.error,
  });

  EventsState copyWith({
    List<Event>? events,
    bool? isLoading,
    String? error,
  }) {
    return EventsState(
      events: events ?? this.events,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// 事件管理服務
class EventsNotifier extends StateNotifier<EventsState> {
  late Box<Event> _eventsBox;

  EventsNotifier() : super(EventsState(isLoading: true)) {
    _eventsBox = Hive.box<Event>(_eventsBoxName);
    _loadEvents();
  }

  // 公共方法：重新加載事件
  Future<void> loadEvents() async {
    await _loadEvents();
  }

  Future<void> _loadEvents() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final eventsList = _eventsBox.values.toList();
      state = EventsState(
        events: List<Event>.from(eventsList),
        isLoading: false,
      );
    } catch (e) {
      print('Error loading events from Hive: $e');
      state = EventsState(
        isLoading: false,
        error: '加載事件時出錯: $e',
      );
    }
  }

  // 創建事件
  Future<void> createEvent(Event event) async {
    state = state.copyWith(isLoading: true);
    try {
      await _eventsBox.put(event.id, event);
      final updatedEventsList = _eventsBox.values.toList();
      state = state.copyWith(events: List<Event>.from(updatedEventsList), isLoading: false);
    } catch (e) {
      print('創建事件時出錯 (Hive): $e');
      state = state.copyWith(isLoading: false, error: '創建事件失敗: $e');
      throw Exception('創建事件失敗: $e');
    }
  }
  
  // 添加事件（別名方法）
  Future<void> addEvent(Event event) async {
    return createEvent(event);
  }

  // 更新事件
  Future<void> updateEvent(Event updatedEvent) async {
    state = state.copyWith(isLoading: true);
    try {
      if (!_eventsBox.containsKey(updatedEvent.id)) {
        throw Exception('嘗試更新不存在的事件');
      }
      await _eventsBox.put(updatedEvent.id, updatedEvent);
      final updatedEventsList = _eventsBox.values.toList();
      state = state.copyWith(events: List<Event>.from(updatedEventsList), isLoading: false);
    } catch (e) {
      print('更新事件時出錯 (Hive): $e');
      state = state.copyWith(isLoading: false, error: '更新事件失敗: $e');
      throw Exception('更新事件失敗: $e');
    }
  }

  // 刪除事件
  Future<void> deleteEvent(String eventId) async {
    state = state.copyWith(isLoading: true);
    try {
      if (!_eventsBox.containsKey(eventId)) {
        print('嘗試刪除不存在的事件: $eventId');
        final currentEvents = List<Event>.from(state.events).where((e) => e.id != eventId).toList();
        state = state.copyWith(events: currentEvents, isLoading: false);
        return;
      }
      await _eventsBox.delete(eventId);
      final updatedEventsList = _eventsBox.values.toList();
      state = state.copyWith(events: List<Event>.from(updatedEventsList), isLoading: false);
    } catch (e) {
      print('刪除事件時出錯 (Hive): $e');
      state = state.copyWith(isLoading: false, error: '刪除事件失敗: $e');
      throw Exception('刪除事件失敗: $e');
    }
  }

  // 添加參與者
  Future<void> addParticipant({
    required String eventId,
    required Participant participant,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final event = _eventsBox.get(eventId);
      if (event == null) {
        throw Exception('添加參與者失敗：找不到指定的事件');
      }
      
      final updatedParticipants = List<Participant>.from(event.participants)..add(participant);
      final updatedEvent = event.copyWith(
        participants: updatedParticipants,
      );
      
      await _eventsBox.put(eventId, updatedEvent);
      final updatedEventsList = _eventsBox.values.toList();
      state = state.copyWith(events: List<Event>.from(updatedEventsList), isLoading: false);
    } catch (e) {
      print('添加參與者時出錯 (Hive): $e');
      state = state.copyWith(isLoading: false, error: '添加參與者失敗: $e');
      throw Exception('添加參與者失敗: $e');
    }
  }

  // 移除參與者
  Future<void> removeParticipant({
    required String eventId,
    required String participantName,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final event = _eventsBox.get(eventId);
      if (event == null) {
        throw Exception('移除參與者失敗：找不到指定的事件');
      }
      
      final updatedParticipants = event.participants
          .where((p) => p.name.toLowerCase() != participantName.toLowerCase())
          .toList();
          
      final updatedEvent = event.copyWith(
        participants: updatedParticipants,
      );
      
      await _eventsBox.put(eventId, updatedEvent);
      final updatedEventsList = _eventsBox.values.toList();
      state = state.copyWith(events: List<Event>.from(updatedEventsList), isLoading: false);
    } catch (e) {
      print('移除參與者時出錯 (Hive): $e');
      state = state.copyWith(isLoading: false, error: '移除參與者失敗: $e');
      throw Exception('移除參與者失敗: $e');
    }
  }

  // 通過ID獲取事件
  Event? getEventById(String eventId) {
    final event = _eventsBox.get(eventId);
    if (event == null) {
      return null;
    }
    return event;
  }

  // 通過共享代碼查找事件
  Event? findEventByShareCode(String shareCode) {
    try {
      return _eventsBox.values.firstWhere((e) => e.shareCode == shareCode);
    } catch (e) {
      return null;
    }
  }

  // 添加刷新事件方法
  Future<void> refreshEvent(String eventId) async {
    // 這裡可以從本地或遠程數據來源重新加載特定的事件
    // 對於演示目的，我們可以簡單地實現一個重新載入事件數據的函數
    
    try {
      // 如果使用 Supabase 或其他後端
      // final response = await _supabaseClient.from('events').select().eq('id', eventId).single();
      // final refreshedEvent = Event.fromJson(response);
      // 更新本地狀態
      
      // 臨時實現：只做標記刷新
      state = state.copyWith(isLoading: false, error: null);
      
      // 稍等片刻，模擬加載時間
      await Future.delayed(const Duration(milliseconds: 500));
      
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

// 事件服務提供者
final eventsProvider = StateNotifierProvider<EventsNotifier, EventsState>((ref) {
  return EventsNotifier();
});

// 獲取單個事件的提供者
final eventProvider = Provider.family<Event?, String>((ref, eventId) {
  final notifier = ref.watch(eventsProvider.notifier);
  final eventFromBox = notifier.getEventById(eventId);
  
  if (eventFromBox != null) return eventFromBox;

  final eventsFromState = ref.watch(eventsProvider).events;
  try {
    return eventsFromState.firstWhere((e) => e.id == eventId);
  } catch (e) {
    return null;
  }
}); 