import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:add_2_calendar/add_2_calendar.dart' as add2calendar;

import '../models/event.dart';
import '../models/participant.dart';
import '../models/time_slot.dart';
import '../models/location_option.dart';
import '../services/event_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/pull_to_refresh.dart';
import 'response_screen.dart';
import '../main.dart';
import '../models/contact.dart';
import '../services/contact_service.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../providers/auth_provider.dart';

class EventDetailsScreen extends ConsumerStatefulWidget {
  final String eventId;

  const EventDetailsScreen({
    Key? key,
    required this.eventId,
  }) : super(key: key);

  @override
  ConsumerState<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends ConsumerState<EventDetailsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  bool _isRefreshing = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _chatScrollController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    
    try {
      // 在此處重新加載事件數據
      await ref.read(eventsProvider.notifier).refreshEvent(widget.eventId);
      
      // 刷新聊天訊息 - 改為調用聊天服務直接刷新
      final chatService = ref.read(chatServiceProvider);
      chatService.refreshMessages();
      
      _refreshController.refreshCompleted();
    } catch (e) {
      _refreshController.refreshFailed();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('刷新失敗: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsState = ref.watch(eventsProvider);
    final asyncLocalUserId = ref.watch(localUserIdProvider);

    return asyncLocalUserId.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Event Details')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        appBar: AppBar(title: const Text('Event Details')),
        body: Center(child: Text('Error loading user data: $err')),
      ),
      data: (localUserId) {
        // 獲取事件數據
        Event? eventFromState; 
        if (eventsState.events.isNotEmpty) {
          try {
            eventFromState = eventsState.events.firstWhere((e) => e.id == widget.eventId);
          } catch (e) {
            // Event not found
          }
        }

        if (eventFromState == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Event Details')),
            body: const Center(child: Text('Event not found')),
          );
        }
    
        final Event event = eventFromState;
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final bool isCreator = (event.creatorId != null && localUserId == event.creatorId);
        
        // 獲取最佳時間和地點選項
        final bestTimeSlots = event.getBestTimeSlots();
        final bestLocations = event.getSortedLocationVotesWithOptions();
        final hasTimeSlots = bestTimeSlots.isNotEmpty;
        final hasLocations = bestLocations.isNotEmpty;
        final finalizedOrHasTopChoices = event.isFinalized || hasTimeSlots || hasLocations;
        
        // 首選時間和地點
        final topTimeSlot = hasTimeSlots ? bestTimeSlots.first : null;
        final topLocation = hasLocations && bestLocations.isNotEmpty ? bestLocations.first.key : null;
        
        return Scaffold(
          backgroundColor: isDark ? theme.colorScheme.background : Colors.grey.shade50,
          body: PullToRefreshWidget(
            controller: _refreshController,
            onRefresh: _onRefresh,
            child: CustomScrollView(
              slivers: [
                // 應用欄
                SliverAppBar(
                  expandedHeight: 160.0,
                  floating: false,
                  pinned: true,
                  stretch: true,
                  elevation: 0,
                  backgroundColor: isDark ? theme.colorScheme.surface : theme.colorScheme.primary,
                  leading: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_back_ios, size: 18, color: Colors.white),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.share_rounded, size: 18, color: Colors.white),
                      ),
                      onPressed: () => _shareViaSystem(event),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(left: 16, bottom: 16, right: 16),
                    title: Text(
                      event.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(0, 1),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Text('Event: ${event.title}', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),
                ),
                
                // 事件摘要卡片
                if (finalizedOrHasTopChoices)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? theme.colorScheme.surface : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  event.isFinalized ? Icons.event_available : Icons.event_note,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  event.isFinalized ? '已確認活動' : '活動摘要',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                if (event.isPast)
                                  _buildStatusChip('已結束', Colors.grey)
                                else if (event.isHappeningSoon)
                                  _buildStatusChip('即將開始', theme.colorScheme.primary)
                                else if (event.isFinalized)
                                  _buildStatusChip('已確認', Colors.green)
                                else
                                  _buildStatusChip('規劃中', Colors.orange),
                              ],
                            ),
                            const Divider(height: 24),
                            
                            // 活動描述
                            if (event.description != null && event.description!.isNotEmpty) ...[
                              Text(
                                '描述',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                event.description!,
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 16),
                            ],
                            
                            // 活動時間
                            if (topTimeSlot != null) ...[
                              Text(
                                '時間',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _formatTimeSlot(topTimeSlot),
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                  if (event.isFinalized)
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.calendar_today, size: 16),
                                      label: const Text('添加到日曆'),
                                      onPressed: () => _addToCalendar(event, topTimeSlot, topLocation),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                        minimumSize: const Size(0, 36),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                            
                            // 活動地點
                            if (topLocation != null) ...[
                              Text(
                                '地點',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      topLocation.name,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.map, size: 16),
                                    label: const Text('查看地圖'),
                                    onPressed: () => _openGoogleSearch(topLocation.name),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                      minimumSize: const Size(0, 36),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                            
                            // 主辦人
                            if (event.creator != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.person, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    '主辦人: ${event.creator}',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ],
                            
                            // 分享按鈕
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.share),
                                label: const Text('分享活動'),
                                onPressed: () => _shareViaSystem(event),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                
                // 标签页标题
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TabBar(
                          controller: _tabController,
                          tabs: const [
                            Tab(text: 'Time Options'),
                            Tab(text: 'Participants'),
                            Tab(text: 'Chat'),
                          ],
                          labelStyle: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                          unselectedLabelStyle: theme.textTheme.titleSmall,
                          indicatorColor: theme.colorScheme.primary,
                          indicatorWeight: 3,
                          labelColor: theme.colorScheme.primary,
                          unselectedLabelColor: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                          indicatorSize: TabBarIndicatorSize.label,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // 标签页内容
                SliverFillRemaining(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // 時間選項標籤
                        _buildTimeOptionsTab(context, event, theme, isDark),
                        // 參與者標籤
                        _buildParticipantsTab(context, event, theme, isDark, localUserId, isCreator),
                        // 聊天標籤
                        _buildChatTab(context, event, theme, isDark, localUserId),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? theme.colorScheme.surface : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ResponseScreen(eventId: event.id),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.check_circle_outline, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Respond to Event',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  // 通過系統分享對話框分享活動
  Future<void> _shareViaSystem(Event event) async {
    final String shareMessage = 
      'I invite you to join: ${event.title}!\n\n'
      'Click this link to join: ${event.getShareLink()}\n'
      'Or use event code: ${event.shareCode}';
    
    try {
      await Share.share(shareMessage);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to open share dialog: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // 將事件添加到日曆中
  Future<void> _addToCalendar(Event event, TimeSlot timeSlot, LocationOption? locationOption) async {
    try {
      final calendarEvent = add2calendar.Event(
        title: event.title,
        description: event.description ?? 'No description provided',
        location: locationOption?.name ?? 'No location specified',
        startDate: timeSlot.startTime,
        endDate: timeSlot.endTime,
        allDay: false,
      );
      
      final result = await add2calendar.Add2Calendar.addEvent2Cal(calendarEvent);
      
      if (result && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event added to calendar'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add event to calendar: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  // 在Google中搜索位置
  Future<void> _openGoogleSearch(String query) async {
    final url = Uri.parse('https://www.google.com/search?q=${Uri.encodeComponent(query)}');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open browser')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening browser: $e')),
        );
      }
    }
  }

  // Helper methods for the event details screen
  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
  
  String _formatTimeSlot(TimeSlot timeSlot) {
    final startDate = DateFormat('yyyy年MM月dd日').format(timeSlot.startTime);
    final startTime = DateFormat('HH:mm').format(timeSlot.startTime);
    final endTime = DateFormat('HH:mm').format(timeSlot.endTime);
    
    // 檢查是否為同一天
    if (timeSlot.startTime.year == timeSlot.endTime.year &&
        timeSlot.startTime.month == timeSlot.endTime.month &&
        timeSlot.startTime.day == timeSlot.endTime.day) {
      return '$startDate $startTime - $endTime';
    } else {
      final endDate = DateFormat('yyyy年MM月dd日').format(timeSlot.endTime);
      return '$startDate $startTime - $endDate $endTime';
    }
  }

  // 時間選項標籤
  Widget _buildTimeOptionsTab(BuildContext context, Event event, ThemeData theme, bool isDark) {
    final availability = event.getTimeSlotAvailability();
    
    if (event.timeSlots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              '尚未設定時間選項',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            if (event.creatorId != null && event.creatorId == ref.read(localUserIdProvider).value)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('添加時間選項'),
                  onPressed: () {
                    // TODO: 實現添加時間選項邏輯
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('此功能正在開發中')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      );
    }
    
    // 依照可用性排序時間選項
    final sortedTimeSlots = event.getBestTimeSlots();
    
    // 獲取用戶選擇
    final localUserId = ref.read(localUserIdProvider).value;
    final currentParticipant = event.participants.firstWhere(
      (p) => p.id == localUserId,
      orElse: () => Participant(id: '', name: ''),
    );
    final selectedTimeSlotIds = currentParticipant.availableTimeSlots;
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedTimeSlots.length,
      itemBuilder: (context, index) {
        final timeSlot = sortedTimeSlots[index];
        final isSelected = selectedTimeSlotIds.contains(timeSlot.id);
        final availableCount = availability[timeSlot.id] ?? 0;
        final participants = event.getAvailableParticipants(timeSlot.id);
        final double percentAvailable = event.participants.isEmpty 
            ? 0.0 
            : (availableCount / event.participants.length);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isSelected 
                ? theme.colorScheme.primary.withOpacity(0.1) 
                : (isDark ? theme.colorScheme.surface : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected 
                  ? theme.colorScheme.primary 
                  : Colors.grey.withOpacity(0.2),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  color: isSelected 
                      ? theme.colorScheme.primary.withOpacity(0.2)
                      : Colors.transparent,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('yyyy年MM月dd日 (E)', 'zh_TW').format(timeSlot.startTime),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (index == 0 && !event.isFinalized)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.amber),
                              ),
                              child: Text(
                                '熱門選擇',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.amber[800],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 18,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${DateFormat('HH:mm').format(timeSlot.startTime)} - ${DateFormat('HH:mm').format(timeSlot.endTime)}',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Icon(
                                Icons.people,
                                size: 16,
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$availableCount 人可參加',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // 可用性進度條
                LinearProgressIndicator(
                  value: percentAvailable,
                  backgroundColor: Colors.grey.withOpacity(0.1),
                  color: _getAvailabilityColor(percentAvailable, theme),
                  minHeight: 4,
                ),
                // 參與者頭像
                if (participants.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '可參加的人:',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 32,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: participants.length > 5 ? 5 : participants.length,
                            itemBuilder: (context, index) {
                              final participant = participants[index];
                              return Container(
                                margin: const EdgeInsets.only(right: 8),
                                height: 32,
                                width: 32,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.colorScheme.primary.withOpacity(0.5),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    participant.name.isNotEmpty 
                                        ? participant.name[0].toUpperCase() 
                                        : '?',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (participants.length > 5)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '還有 ${participants.length - 5} 人',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                      ],
                    ),
                  ),
                // 投票按鈕
                if (!event.isFinalized)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            // TODO: 實現投票邏輯
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('投票功能正在開發中')),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isSelected ? theme.colorScheme.error : theme.colorScheme.primary,
                            side: BorderSide(
                              color: isSelected ? theme.colorScheme.error : theme.colorScheme.primary,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                            minimumSize: const Size(0, 36),
                          ),
                          child: Text(isSelected ? '取消選擇' : '選擇此時間'),
                        ),
                        if (isSelected && event.isFinalized)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.calendar_today, size: 16),
                              label: const Text('添加到日曆'),
                              onPressed: () => _addToCalendar(
                                event, 
                                timeSlot, 
                                event.getBestLocations().isNotEmpty ? event.getBestLocations().first : null,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                minimumSize: const Size(0, 36),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 根據參與百分比獲取顏色
  Color _getAvailabilityColor(double percent, ThemeData theme) {
    if (percent >= 0.7) {
      return Colors.green;
    } else if (percent >= 0.4) {
      return Colors.amber;
    } else {
      return Colors.redAccent;
    }
  }

  // 參與者標籤
  Widget _buildParticipantsTab(BuildContext context, Event event, ThemeData theme, 
      bool isDark, String localUserId, bool isCreator) {
    
    if (event.participants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              '尚無參與者',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            if (isCreator || !event.participants.any((p) => p.id == localUserId))
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: const Text('邀請朋友'),
                  onPressed: () => _shareViaSystem(event),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      );
    }
    
    // 對參與者排序 - 已回應的排在前面
    final respondedParticipants = <Participant>[];
    final pendingParticipants = <Participant>[];
    
    for (final participant in event.participants) {
      if (participant.availableTimeSlots.isNotEmpty || 
          participant.preferredLocationIds.isNotEmpty) {
        respondedParticipants.add(participant);
      } else {
        pendingParticipants.add(participant);
      }
    }
    
    // 最終排序 - 已回應的在前，待定的在後
    final sortedParticipants = [...respondedParticipants, ...pendingParticipants];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 摘要信息
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? theme.colorScheme.surface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildStatCard(
                      theme, 
                      Icons.people, 
                      '參與者',
                      '${event.participants.length}',
                    ),
                    _buildStatCard(
                      theme, 
                      Icons.check_circle_outline, 
                      '已回應',
                      '${respondedParticipants.length}',
                    ),
                    _buildStatCard(
                      theme, 
                      Icons.pending_actions, 
                      '待定',
                      '${pendingParticipants.length}',
                    ),
                  ],
                ),
                if (isCreator && pendingParticipants.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.send, size: 16),
                            label: const Text('發送提醒'),
                            onPressed: () {
                              // TODO: 實現發送提醒邏輯
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('提醒功能正在開發中')),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          // 參與者標題
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 24, 8, 16),
            child: Row(
              children: [
                Text(
                  '全部參與者',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (isCreator)
                  IconButton(
                    icon: Icon(
                      Icons.person_add_alt,
                      color: theme.colorScheme.primary,
                    ),
                    onPressed: () => _shareViaSystem(event),
                    tooltip: '邀請更多人',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
          
          // 參與者列表
          Expanded(
            child: ListView.builder(
              itemCount: sortedParticipants.length,
              itemBuilder: (context, index) {
                final participant = sortedParticipants[index];
                final isCurrentUser = participant.id == localUserId;
                final hasResponded = participant.availableTimeSlots.isNotEmpty || 
                    participant.preferredLocationIds.isNotEmpty;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isCurrentUser
                        ? theme.colorScheme.primary.withOpacity(0.05)
                        : (isDark ? theme.colorScheme.surface : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: isCurrentUser
                        ? Border.all(color: theme.colorScheme.primary.withOpacity(0.3))
                        : null,
                    boxShadow: isCurrentUser
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // 參與者頭像
                        Container(
                          height: 44,
                          width: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasResponded
                                ? theme.colorScheme.primary.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            border: Border.all(
                              color: hasResponded
                                  ? theme.colorScheme.primary.withOpacity(0.5)
                                  : Colors.grey.withOpacity(0.3),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              participant.name.isNotEmpty
                                  ? participant.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: hasResponded
                                    ? theme.colorScheme.primary
                                    : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // 參與者信息
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    participant.name,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (isCurrentUser)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '你',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  if (event.creatorId == participant.id)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '創建者',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.amber[800],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                hasResponded
                                    ? _getParticipantStatusText(participant, event)
                                    : '尚未回應',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: hasResponded
                                      ? theme.colorScheme.onSurface.withOpacity(0.7)
                                      : Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // 狀態圖標
                        Container(
                          height: 32,
                          width: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasResponded
                                ? Colors.green.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                          ),
                          child: Icon(
                            hasResponded ? Icons.check : Icons.schedule,
                            color: hasResponded ? Colors.green : Colors.grey,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  // 參與者狀態卡片
  Widget _buildStatCard(ThemeData theme, IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  // 獲取參與者狀態文本
  String _getParticipantStatusText(Participant participant, Event event) {
    final availableTimes = participant.availableTimeSlots.length;
    final preferredLocations = participant.preferredLocationIds.length;
    
    final List<String> statusParts = [];
    
    if (availableTimes > 0) {
      statusParts.add('可參加 $availableTimes 個時間選項');
    }
    
    if (preferredLocations > 0) {
      statusParts.add('選擇了 $preferredLocations 個地點');
    }
    
    if (statusParts.isEmpty) {
      return '已回應但未選擇時間或地點';
    }
    
    return statusParts.join('、');
  }

  // 聊天標籤
  Widget _buildChatTab(BuildContext context, Event event, ThemeData theme, 
      bool isDark, String localUserId) {
    
    // 使用eventChatMessagesProvider來替代chatMessagesProvider
    final chatMessages = ref.watch(eventChatMessagesProvider(event.id));
    
    return Column(
      children: [
        // 聊天訊息列表
        Expanded(
          child: chatMessages.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '尚無訊息',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '發送第一條訊息開始討論吧！',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _chatScrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: chatMessages.length,
                  itemBuilder: (context, index) {
                    final message = chatMessages[index];
                    final isCurrentUser = message.senderId == localUserId;
                    final userName = isCurrentUser 
                        ? ref.read(currentUserNameProvider) ?? '我'
                        : (message.senderName);
                    
                    // 決定是否顯示日期分隔線
                    final bool showDateDivider = index == 0 || 
                        !_isSameDay(chatMessages[index - 1].timestamp, message.timestamp);
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 日期分隔線
                        if (showDateDivider)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: _buildDateDivider(message.timestamp, theme),
                          ),
                        
                        // 訊息氣泡
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            mainAxisAlignment: isCurrentUser 
                                ? MainAxisAlignment.end 
                                : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 非當前用戶的頭像
                              if (!isCurrentUser)
                                Container(
                                  height: 36,
                                  width: 36,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: theme.colorScheme.primary.withOpacity(0.1),
                                    border: Border.all(
                                      color: theme.colorScheme.primary.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              
                              // 訊息內容
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: isCurrentUser 
                                      ? CrossAxisAlignment.end 
                                      : CrossAxisAlignment.start,
                                  children: [
                                    // 發送者名稱
                                    if (!isCurrentUser)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 12, bottom: 4),
                                        child: Text(
                                          userName,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                                          ),
                                        ),
                                      ),
                                    
                                    // 訊息氣泡 - 使用content而非text
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isCurrentUser
                                            ? theme.colorScheme.primary
                                            : (isDark 
                                                ? theme.colorScheme.surface 
                                                : Colors.grey.shade100),
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(16),
                                          topRight: const Radius.circular(16),
                                          bottomLeft: Radius.circular(isCurrentUser ? 16 : 4),
                                          bottomRight: Radius.circular(isCurrentUser ? 4 : 16),
                                        ),
                                      ),
                                      child: Text(
                                        message.content,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: isCurrentUser 
                                              ? Colors.white 
                                              : theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    
                                    // 時間戳
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4, left: 12, right: 12),
                                      child: Text(
                                        DateFormat('HH:mm').format(message.timestamp),
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontSize: 10,
                                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // 當前用戶的頭像（放在右側）
                              if (isCurrentUser)
                                Container(
                                  height: 36,
                                  width: 36,
                                  margin: const EdgeInsets.only(left: 12),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: theme.colorScheme.primary.withOpacity(0.3),
                                  ),
                                  child: Center(
                                    child: Text(
                                      userName.isNotEmpty ? userName[0].toUpperCase() : '我',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
        
        // 訊息輸入區
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? theme.colorScheme.surface : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 表情按鈕
                IconButton(
                  icon: const Icon(Icons.emoji_emotions_outlined),
                  onPressed: () {
                    // TODO: 實現表情選擇器
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('表情功能正在開發中')),
                    );
                  },
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                
                // 訊息輸入框
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: '輸入訊息...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark 
                          ? theme.colorScheme.surface.withOpacity(0.5)
                          : Colors.grey.shade200,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: 12),
                
                // 發送按鈕 - 修正sendMessage的使用
                InkWell(
                  onTap: () {
                    final messageText = _messageController.text.trim();
                    if (messageText.isNotEmpty) {
                      // 發送訊息 - 使用正確的方法創建並發送訊息
                      final chatService = ref.read(chatServiceProvider);
                      final userName = ref.read(currentUserNameProvider) ?? '我';
                      final userId = ref.read(currentUserIdProvider) ?? '';
                      
                      final newMessage = ChatMessage(
                        eventId: event.id,
                        senderId: userId,
                        senderName: userName,
                        content: messageText,
                      );
                      
                      chatService.sendMessage(newMessage).then((_) {
                        // 通知消息已發送
                        ref.read(eventChatMessagesProvider(event.id).notifier).addMessage(newMessage);
                      });
                      
                      // 清空輸入框
                      _messageController.clear();
                      
                      // 滾動到底部
                      Future.delayed(const Duration(milliseconds: 100), () {
                        if (_chatScrollController.hasClients) {
                          _chatScrollController.animateTo(
                            _chatScrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        }
                      });
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary,
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  // 構建日期分隔線
  Widget _buildDateDivider(DateTime date, ThemeData theme) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    
    String dateText;
    if (_isSameDay(date, now)) {
      dateText = '今天';
    } else if (_isSameDay(date, yesterday)) {
      dateText = '昨天';
    } else {
      dateText = DateFormat('yyyy年MM月dd日').format(date);
    }
    
    return Row(
      children: [
        Expanded(child: Divider(color: theme.colorScheme.onSurface.withOpacity(0.1))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            dateText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
        Expanded(child: Divider(color: theme.colorScheme.onSurface.withOpacity(0.1))),
      ],
    );
  }
  
  // 判斷兩個日期是否為同一天
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
} 