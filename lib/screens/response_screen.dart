import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

import '../models/event.dart';
import '../models/participant.dart';
import '../models/time_slot.dart';
import '../models/location_option.dart';
import '../services/event_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/input_field.dart';
import '../widgets/time_slot_card.dart';

class ResponseScreen extends ConsumerStatefulWidget {
  final String eventId;
  final List<String>? preSelectedTimeSlots;
  
  const ResponseScreen({
    Key? key,
    required this.eventId,
    this.preSelectedTimeSlots,
  }) : super(key: key);

  @override
  ConsumerState<ResponseScreen> createState() => _ResponseScreenState();
}

class _ResponseScreenState extends ConsumerState<ResponseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _commentController = TextEditingController();
  final _suggestedLocationController = TextEditingController();
  
  Set<String> _selectedTimeSlots = {};
  Set<String> _selectedLocationIds = {};
  bool _isSubmitting = false;
  bool _showSuggestTimeField = false;
  bool _showSuggestLocationField = false;
  
  // 用於建議的時間
  DateTime? _suggestedDate;
  TimeOfDay? _suggestedTime;
  
  // 用於保存用戶名
  String _savedName = '';
  
  // 用於標記用戶是否改變主意
  bool _isChangingMind = false;
  
  @override
  void initState() {
    super.initState();
    if (widget.preSelectedTimeSlots != null) {
      _selectedTimeSlots = Set<String>.from(widget.preSelectedTimeSlots!);
    }
    
    // 從本地存儲獲取用戶名
    _loadUserData();
  }
  
  // 讀取用戶上次使用的名稱，以便檢查是否已投票
  void _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedName = prefs.getString('user_name') ?? '';
    });
  }
  
  // 保存用戶名到本地存儲
  void _saveUserData() async {
    if (_nameController.text.trim().isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', _nameController.text.trim());
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _commentController.dispose();
    _suggestedLocationController.dispose();
    super.dispose();
  }
  
  // 格式化建議的時間為字符串
  String? get formattedSuggestedTime {
    if (_suggestedDate == null || _suggestedTime == null) return null;
    
    final dateTime = DateTime(
      _suggestedDate!.year,
      _suggestedDate!.month,
      _suggestedDate!.day,
      _suggestedTime!.hour,
      _suggestedTime!.minute,
    );
    
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');
    
    return '${dateFormat.format(_suggestedDate!)} ${timeFormat.format(dateTime)}';
  }
  
  @override
  Widget build(BuildContext context) {
    final eventsState = ref.watch(eventsProvider);
    final Event? event = eventsState.events.isEmpty
        ? null
        : eventsState.events.firstWhere(
            (e) => e.id == widget.eventId,
            orElse: () => Event(
              title: '',
              timeSlots: [],
              id: widget.eventId,
            ),
          );
    
    if (event == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('回應活動'),
        ),
        body: const Center(
          child: Text('找不到此活動'),
        ),
      );
    }
    
    // 檢查用戶是否已經提交過回應
    final String userName = _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : _savedName;
    final bool hasVoted = event.participants.any((p) => p.name.toLowerCase() == userName.toLowerCase());
    
    // 如果已投票，獲取用戶的回應
    Participant? currentUserResponse;
    if (hasVoted && userName.isNotEmpty) {
      currentUserResponse = event.participants.firstWhere(
        (p) => p.name.toLowerCase() == userName.toLowerCase(),
        orElse: () => Participant(name: '')
      );
      
      // 如果用戶已投票，填充表單數據
      if (currentUserResponse.name.isNotEmpty && _nameController.text.isEmpty) {
        _nameController.text = currentUserResponse.name;
        _commentController.text = currentUserResponse.comment ?? '';
        _selectedTimeSlots = Set<String>.from(currentUserResponse.availableTimeSlots);
        _selectedLocationIds = Set<String>.from(currentUserResponse.preferredLocationIds);
        if (currentUserResponse.suggestedLocation != null) {
          _suggestedLocationController.text = currentUserResponse.suggestedLocation!;
        }
      }
    }
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Generate card background color
    final List<Color> cardColors = [
      Colors.blue.shade200,
      Colors.purple.shade200,
      Colors.pink.shade200,
      Colors.orange.shade200,
      Colors.teal.shade200,
    ];
    final cardColor = cardColors[event.id.hashCode % cardColors.length];
    
    return Scaffold(
      appBar: AppBar(
        title: Text(hasVoted ? '您的活動回應' : '回應活動'),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: theme.scaffoldBackgroundColor,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(), // 點擊空白處收起鍵盤
          child: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildEventHeader(event, cardColor),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 如果用戶已投票，顯示已投票界面
                        if (hasVoted && currentUserResponse != null) ...[
                          _buildVotedView(event, currentUserResponse),
                        ] else ...[
                          // 否則顯示投票表單
                          _buildVotingForm(event),
                        ],
                            ],
                          ),
                        ),
                              ],
                            ),
                          ),
                        ),
        ),
      ),
    );
  }
  
  // 選擇建議的日期
  void _selectSuggestedDate() async {
    final initialDate = _suggestedDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        _suggestedDate = picked;
      });
    }
  }
  
  // 選擇建議的時間
  void _selectSuggestedTime() async {
    final initialTime = _suggestedTime ?? TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    
    if (picked != null) {
      setState(() {
        _suggestedTime = picked;
      });
    }
  }
  
  Widget _buildEventHeader(Event event, Color cardColor) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? theme.colorScheme.surfaceVariant : theme.scaffoldBackgroundColor,
            // boxShadow: AppTheme.lightShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                // style: TextStyle(
                //   fontSize: 22,
                //   fontWeight: FontWeight.bold,
                //   color: isDark ? Colors.white : AppTheme.textColor,
                // ),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: isDark ? Colors.white : AppTheme.textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (event.description != null && event.description!.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spaceXS),
                Text(
                  event.description!,
                  // style: TextStyle(
                  //   fontSize: 15,
                  //   color: isDark ? Colors.white70 : AppTheme.textSecondaryColor,
                  //   height: 1.4,
                  // ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white70 : AppTheme.textSecondaryColor,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
        // Divider(),
      ],
    );
  }
  
  Widget _buildSectionHeader(String title, IconData icon) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Row(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 22,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }
  
  Widget _buildTimeGrid(Event event) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Calculate availability
    final availability = event.getTimeSlotAvailability();
    
    return Column(
      children: [
        // 時間選擇新設計
        Card(
          elevation: 0,
          color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '時間選項',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '已選擇 ${_selectedTimeSlots.length}/${event.timeSlots.length}',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: event.timeSlots.length,
          itemBuilder: (context, index) {
            final timeSlot = event.timeSlots[index];
                  final availableCount = availability[timeSlot.id] ?? 0;
                  final totalCount = event.participants.length;
            final isSelected = _selectedTimeSlots.contains(timeSlot.id);
                  final isPopular = availableCount > 0 && totalCount > 0 && (availableCount / totalCount) >= 0.5;
                  
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withOpacity(0.15)
                          : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  if (isSelected) {
                    _selectedTimeSlots.remove(timeSlot.id);
                  } else {
                    _selectedTimeSlots.add(timeSlot.id);
                  }
                });
              },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 24,
                                height: 24,
                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                    color: isSelected 
                        ? theme.colorScheme.primary 
                                      : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                                  border: isSelected
                                      ? null
                                      : Border.all(
                                          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                                          width: 1,
                                        ),
                                ),
                                child: isSelected
                                    ? Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            timeSlot.getFormattedDate(),
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.white : Colors.black,
                                            ),
                                          ),
                                        ),
                                        if (isPopular)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.secondary.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.star,
                                                  size: 12,
                                                  color: theme.colorScheme.secondary,
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  '熱門',
                                                  style: TextStyle(
                                                    color: theme.colorScheme.secondary,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      timeSlot.getFormattedTimeRange(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                                      ),
                                    ),
                                    if (totalCount > 0) ...[
                                      const SizedBox(height: 8),
                                      Stack(
                                        children: [
                                          Container(
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          ),
                                          Container(
                                            height: 4,
                                            width: MediaQuery.of(context).size.width * 0.6 * (totalCount > 0 ? availableCount / totalCount : 0),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  theme.colorScheme.primary,
                                                  theme.colorScheme.secondary,
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$availableCount/$totalCount 人選擇了這個時間',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        
        // Suggest Another Time Option
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _showSuggestTimeField = !_showSuggestTimeField;
            });
          },
          icon: Icon(
            _showSuggestTimeField ? Icons.remove_circle_outline : Icons.add_circle_outline,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          label: Text(
            _showSuggestTimeField ? 'Cancel Suggestion' : 'Suggest Another Time',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        
        // Suggestion Time Field
        if (_showSuggestTimeField) ...[
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: isDark ? const Color(0xFF252525) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Padding(
                padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Suggest a Different Time',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Date and Time Selector
                  Row(
                    children: [
                      // Date Picker
                      Expanded(
                        child: InkWell(
                          onTap: _selectSuggestedDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _suggestedDate == null
                                        ? 'Select Date'
                                        : DateFormat('MMM dd, yyyy').format(_suggestedDate!),
                                    style: TextStyle(
                                      color: _suggestedDate == null
                                          ? (isDark ? Colors.grey.shade400 : Colors.grey.shade600)
                                          : (isDark ? Colors.white : Colors.black87),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      // Time Picker
                      Expanded(
                        child: InkWell(
                          onTap: _selectSuggestedTime,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _suggestedTime == null
                                        ? 'Select Time'
                                        : '${_suggestedTime!.hour.toString().padLeft(2, '0')}:${_suggestedTime!.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      color: _suggestedTime == null
                                          ? (isDark ? Colors.grey.shade400 : Colors.grey.shade600)
                                          : (isDark ? Colors.white : Colors.black87),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildLocationsGrid(Event event) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (event.locationOptions.isEmpty) {
      return const SizedBox.shrink();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: event.locationOptions.length,
      itemBuilder: (context, index) {
        final locationOpt = event.locationOptions[index];
        final isSelected = _selectedLocationIds.contains(locationOpt.id);

        return InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedLocationIds.remove(locationOpt.id);
              } else {
                _selectedLocationIds.add(locationOpt.id);
              }
            });
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? theme.colorScheme.primary.withOpacity(0.15) : theme.cardColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              border: Border.all(
                color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected ? AppTheme.lightShadow : [],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSelected ? theme.colorScheme.primary : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    locationOpt.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? theme.colorScheme.primary : (isDark ? Colors.white70 : Colors.black87),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Open Google Search
  Future<void> _openGoogleSearch(String query) async {
    final url = Uri.parse('https://www.google.com/search?q=${Uri.encodeComponent(query)}');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('無法開啟瀏覽器')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('開啟瀏覽器時出錯: $e')),
        );
      }
    }
  }
  
  // 新方法：處理已投票的用戶界面
  Widget _buildVotedView(Event event, Participant userResponse) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '您已完成投票',
                    style: TextStyle(
                      fontSize: 18,
                              fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '感謝您的參與！以下是您的選擇：',
                style: TextStyle(
                              fontSize: 16,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // 顯示用戶選擇的時間
        _buildResponseSection(
          title: '選擇的時間',
          icon: Icons.access_time,
          color: theme.colorScheme.primary,
          child: Column(
            children: userResponse.availableTimeSlots.isEmpty
                ? [
                          Text(
                      '您沒有選擇任何時間',
                            style: TextStyle(
                              fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                      ),
                    ),
                  ]
                : event.timeSlots
                    .where((ts) => userResponse.availableTimeSlots.contains(ts.id))
                    .map((ts) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.event,
                                  color: theme.colorScheme.primary,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ts.getFormattedDate(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      ts.getFormattedTimeRange(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                        ))
                    .toList(),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // 顯示用戶選擇的地點
        if (userResponse.preferredLocationIds.isNotEmpty) ...[
          _buildResponseSection(
            title: '您選擇的地點',
            icon: Icons.place,
            color: Colors.green,
            child: Text(
              userResponse.preferredLocationIds.map((locId) {
                try {
                  final foundLocationOption = event.locationOptions.firstWhere((opt) => opt.id == locId);
                  return foundLocationOption.name;
                } catch (e) {
                  return 'Location ID: $locId (Not found)';
                }
              }).join(', '),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
        ],
        
        // 顯示用戶的建議時間和地點
        if (userResponse.suggestedTime != null || userResponse.suggestedLocation != null) ...[
          _buildResponseSection(
            title: '您的建議',
            icon: Icons.lightbulb_outline,
            color: Colors.amber,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (userResponse.suggestedTime != null) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.access_time,
                          color: theme.colorScheme.primary,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '建議時間',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : Colors.grey.shade700,
                              ),
                            ),
                            Text(
                              userResponse.suggestedTime!,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                
                if (userResponse.suggestedLocation != null) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.place,
                          color: theme.colorScheme.secondary,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '建議地點',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : Colors.grey.shade700,
                              ),
                            ),
                            Text(
                              userResponse.suggestedLocation!,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.open_in_new,
                          size: 16,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                        onPressed: () => _openGoogleSearch(userResponse.suggestedLocation!),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 24),
        ],
        
        // 如果用戶有留言，顯示留言
        if (userResponse.comment != null && userResponse.comment!.isNotEmpty) ...[
          _buildResponseSection(
            title: '您的留言',
            icon: Icons.comment,
            color: Colors.deepPurple,
            child: Text(
              userResponse.comment!,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
        ],
        
        // 改變主意按鈕
        Center(
          child: GradientButton(
            text: '改變我的想法',
            icon: Icons.edit,
            onPressed: () {
              // 確認對話框
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('重新投票'),
                  content: const Text('您確定要重新投票嗎？這將會覆蓋您之前的選擇。'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          // 重置用戶界面為投票模式
                          _isChangingMind = true;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('確定'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 新方法：構建投票表單
  Widget _buildVotingForm(Event event) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Your Information', Icons.person_outline),
        const SizedBox(height: AppTheme.spaceXS),
        
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade900 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade300,
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              InputField(
                label: 'Name',
                placeholder: 'Enter your name',
                controller: _nameController,
                required: true,
                prefix: Icon(Icons.person_outline),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: AppTheme.spaceLG),
              
              InputField(
                label: 'Comment',
                placeholder: 'Anything you want to say? (Optional)',
                controller: _commentController,
                minLines: 3,
                maxLines: 5,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: AppTheme.spaceLG),
        
        // Time slots selection
        _buildSectionHeader('Select Available Times', Icons.schedule),
        const SizedBox(height: AppTheme.spaceSM),
        
        _buildTimeGrid(event),
        
        const SizedBox(height: AppTheme.spaceLG),
        
        // Location preference
        if (event.locationOptions.isNotEmpty) ...[
          _buildSectionHeader('Select Preferred Location(s)', Icons.place),
          const SizedBox(height: AppTheme.spaceSM),
          
          _buildLocationsGrid(event),
          const SizedBox(height: AppTheme.spaceLG),

          // Suggest Another Location Option
          TextButton.icon(
            onPressed: () {
              setState(() {
                _showSuggestLocationField = !_showSuggestLocationField;
              });
            },
            icon: Icon(
              _showSuggestLocationField ? Icons.remove_circle_outline : Icons.add_circle_outline,
              size: 18,
              color: theme.colorScheme.secondary,
            ),
            label: Text(
              _showSuggestLocationField ? 'Cancel Location Suggestion' : 'Suggest Another Location',
              style: TextStyle(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          if (_showSuggestLocationField) ...[
            const SizedBox(height: AppTheme.spaceSM),
            Card(
              elevation: 0,
              color: isDark ? const Color(0xFF252525) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: InputField(
                  label: 'Suggested Location Name',
                  placeholder: 'e.g., Conference Room B',
                  controller: _suggestedLocationController,
                  prefix: Icon(Icons.edit_location_outlined, color: theme.colorScheme.secondary),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppTheme.spaceLG),
        ],
        
        if (_selectedTimeSlots.isNotEmpty || (_suggestedDate != null && _suggestedTime != null) || _selectedLocationIds.isNotEmpty || (_showSuggestLocationField && _suggestedLocationController.text.isNotEmpty))
          Container(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMD, horizontal: AppTheme.spaceMD),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppTheme.spaceSM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_selectedTimeSlots.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppTheme.spaceXXS), // Add padding if multiple items
                          child: Text(
                            'Selected ${_selectedTimeSlots.length} time option(s)',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w500),
                          ),
                        ),
                      
                      if (_suggestedDate != null && _suggestedTime != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppTheme.spaceXXS),
                          child: Text(
                            'Suggested New Time: $formattedSuggestedTime',
                             style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w500),
                          ),
                        ),
                        
                      if (_selectedLocationIds.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppTheme.spaceXXS),
                          child: Text(
                            'Selected ${_selectedLocationIds.length} location option(s)',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w500),
                          ),
                        ),
                        
                      if (_showSuggestLocationField && _suggestedLocationController.text.isNotEmpty)
                        Text(
                          'Suggested New Location: ${_suggestedLocationController.text}',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w500),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
        const SizedBox(height: AppTheme.spaceXL), // Increased space before submit button
        
        GradientButton(
          text: _isChangingMind ? '更新我的回應' : '提交回應',
          icon: Icons.check_circle_outlined,
          onPressed: () {
            HapticFeedback.lightImpact();
            _submitResponse(event);
          },
          isLoading: _isSubmitting,
          height: 56,
        ),
      ],
    );
  }

  // 響應部分的通用構建方法
  Widget _buildResponseSection({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceSM),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppTheme.spaceMD),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(isDark ? 0.5 : 1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            border: Border.all(
              color: theme.dividerColor.withOpacity(isDark ? 0.5 : 1),
              width: 1,
            ),
          ),
          child: child,
        ),
      ],
    );
  }
  
  Future<void> _submitResponse(Event event) async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please check the information you filled in'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    
    // 檢查是否選擇了時間或建議了時間
    if (_selectedTimeSlots.isEmpty && (_suggestedDate == null || _suggestedTime == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one time option or suggest a new time'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      // preferredLocationIds now directly comes from _selectedLocationIds which stores LocationOption.id
      List<String> preferredLocationIds = _selectedLocationIds.toList(); 
      
      final participant = Participant(
        name: _nameController.text.trim(),
        availableTimeSlots: _selectedTimeSlots.toList(),
        preferredLocationIds: preferredLocationIds, // Directly use the collected LocationOption IDs
        comment: _commentController.text.trim().isNotEmpty ? _commentController.text.trim() : null,
        suggestedTime: formattedSuggestedTime,
        suggestedLocation: _suggestedLocationController.text.trim().isNotEmpty ? _suggestedLocationController.text.trim() : null,
      );
      
      _saveUserData();
      
      if (_isChangingMind) {
        // ... (remove old participant logic - should be fine as it uses name)
        await ref.read(eventsProvider.notifier).removeParticipant(
             eventId: event.id,
             participantName: _nameController.text.trim(),
        );
      }
      
      await ref.read(eventsProvider.notifier).addParticipant(
        eventId: event.id,
        participant: participant,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isChangingMind ? '回應已更新' : '回應提交成功'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        
        // 提交成功後返回上一頁
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit response: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
} 