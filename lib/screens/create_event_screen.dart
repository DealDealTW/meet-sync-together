import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

import '../models/event.dart';
import '../models/time_slot.dart';
import '../models/location_option.dart';
import '../services/event_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../widgets/gradient_button.dart';
import '../widgets/input_field.dart';
import 'event_details_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import '../main.dart'; // ADDED for localUserIdProvider
import '../services/contact_service.dart'; // 添加聯絡人服務

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationNameController = TextEditingController();
  final _creatorNameController = TextEditingController();
  
  final List<TimeSlot> _timeSlots = [];
  final List<LocationOption> _locationOptions = [];
  bool _isSubmitting = false;
  int _currentIndex = 1; // Default to Create tab
  
  @override
  void initState() {
    super.initState();
    _loadCreatorName();
  }

  Future<void> _loadCreatorName() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('user_name');
    if (savedName != null) {
      _creatorNameController.text = savedName;
    }
  }

  Future<void> _saveCreatorName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationNameController.dispose();
    _creatorNameController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary,
              radius: 18,
              child: Icon(
                Icons.calendar_today_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'MeetUp',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create New Event',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Creator Name InputField
                InputField(
                  controller: _creatorNameController,
                  label: 'Your Name (Creator)',
                  placeholder: 'Enter your name',
                  prefix: Icon(Icons.person_outline, color: theme.colorScheme.primary),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name as the creator';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 20),
                
                // Event Name
                InputField(
                  controller: _titleController,
                  label: 'Event Title',
                  placeholder: 'Weekend Dinner',
                  prefix: Icon(Icons.title, color: theme.colorScheme.primary),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an event title';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 20),
                
                // Description
                InputField(
                  controller: _descriptionController,
                  label: 'Description (Optional)',
                  placeholder: 'Let\'s catch up over dinner!',
                  prefix: Icon(Icons.description_outlined, color: theme.colorScheme.primary),
                  minLines: 3,
                  maxLines: 5,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 20),
                
                // Location Options (Voting System)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Location Options',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _showAddLocationDialog,
                      icon: Icon(
                        Icons.add_location_alt,
                        color: theme.colorScheme.primary,
                        size: 16,
                      ),
                      label: Text(
                        'Add Location',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Location Options List
                ..._buildLocationOptions(),
                
                if (_locationOptions.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTheme.spaceMD),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(isDark ? 0.3 : 0.7),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      border: Border.all(
                        color: theme.dividerColor.withOpacity(isDark ? 0.3 : 0.7),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.place,
                          size: 40,
                          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Add at least one location option',
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Let participants vote for the best location',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // Time Options
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Time Options',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _showAddTimeDialog,
                      icon: Icon(
                        Icons.add_alarm,
                        color: theme.colorScheme.primary,
                        size: 16,
                      ),
                      label: Text(
                        'Add Time',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Time Slots List
                ..._buildTimeSlotFields(),
                
                const SizedBox(height: 32),
                
                // Buttons row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _createEvent,
                        style: ElevatedButton.styleFrom(
                           padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMD),
                        ),
                        child: _isSubmitting
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Text('Create Event'),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward, size: 16),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index != _currentIndex) {
            if (index == 0) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            } else if (index == 2) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            }
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // Show Add Location Dialog
  void _showAddLocationDialog() {
    _locationNameController.clear();
    
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: const Text('Add Location Option'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InputField(
                controller: _locationNameController,
                label: 'Location Name',
                placeholder: 'e.g., Central Park Cafe',
                prefix: Icon(Icons.pin_drop_outlined, color: theme.colorScheme.primary),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a location name';
                  }
                  if (_locationOptions.any((loc) => loc.name.toLowerCase() == value.toLowerCase())) {
                    return 'This location has already been added.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spaceMD),
              TextButton.icon(
                icon: Icon(Icons.search, color: theme.colorScheme.secondary),
                label: Text('Search on Google Maps', style: TextStyle(color: theme.colorScheme.secondary)),
                onPressed: () async {
                  if (_locationNameController.text.isNotEmpty) {
                    final query = Uri.encodeComponent(_locationNameController.text);
                    final url = 'https://www.google.com/maps/search/?api=1&query=$query';
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url));
                    }
                  }
                },
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_locationNameController.text.isNotEmpty && 
                    !_locationOptions.any((loc) => loc.name.toLowerCase() == _locationNameController.text.trim().toLowerCase())) {
                  setState(() {
                    _locationOptions.add(
                      LocationOption(name: _locationNameController.text.trim())
                    );
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
  
  // Open Google search for a location
  void _openGoogleSearch(String name) async {
    final query = Uri.encodeComponent(name);
    final url = Uri.parse('https://www.google.com/search?q=$query');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open browser'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
  
  // Add location to options list
  void _addLocationOption(LocationOption location) {
    setState(() {
      // Check if the location already exists to avoid duplicates
      if (!_locationOptions.any((option) => option.name.toLowerCase() == location.name.toLowerCase())) {
        _locationOptions.add(location);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('This location has already been added'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }
  
  // Build location options list
  List<Widget> _buildLocationOptions() {
    if (_locationOptions.isEmpty) {
      return [];
    }
    return _locationOptions.map((locOpt) {
      return Card(
        elevation: 1,
        margin: const EdgeInsets.only(bottom: AppTheme.spaceSM),
        child: ListTile(
          leading: Icon(Icons.place_outlined, color: Theme.of(context).colorScheme.primary),
          title: Text(locOpt.name),
          trailing: IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: AppTheme.errorColor),
            onPressed: () {
              setState(() {
                _locationOptions.removeWhere((lo) => lo.id == locOpt.id);
              });
            },
          ),
        ),
      );
    }).toList();
  }
  
  List<Widget> _buildTimeSlotFields() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // If no time options, show a message
    if (_timeSlots.isEmpty) {
      return [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppTheme.spaceMD),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(isDark ? 0.3 : 0.7),
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            border: Border.all(
              color: theme.dividerColor.withOpacity(isDark ? 0.3 : 0.7),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.access_time,
                size: 40,
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No time options added yet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Click "Add Time" to set available times for your event',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ];
    }
    
    // Show added time options
    return _timeSlots.map((slot) {
      final dateFormatter = DateFormat('E, MMM d, yyyy');
      final timeFormatter = DateFormat('HH:mm');
      
      return Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spaceSM),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                Icons.event,
                size: 22,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateFormatter.format(slot.startTime),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${timeFormatter.format(slot.startTime)} - ${timeFormatter.format(slot.endTime)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: theme.colorScheme.error,
                  size: 22,
                ),
                onPressed: () => _removeTimeSlot(slot),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
  
  // Show Add Time Dialog
  void _showAddTimeDialog() async {
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    
    // Select date
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (pickedDate == null) return;
    selectedDate = pickedDate;
    
    // Select time
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (pickedTime == null) return;
    selectedTime = pickedTime;
    
    // Create time slot
    final selectedDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
    
    // Default time slot is one hour
    final endTime = selectedDateTime.add(const Duration(hours: 1));
    
    setState(() {
      _timeSlots.add(
        TimeSlot(
          startTime: selectedDateTime,
          endTime: endTime,
        ),
      );
    });
  }
  
  // Remove time slot
  void _removeTimeSlot(TimeSlot slot) {
    setState(() {
      _timeSlots.remove(slot);
    });
  }
  
  // Create event
  Future<void> _createEvent() async {
    if (_formKey.currentState!.validate()) {
      if (_timeSlots.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one time option'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      setState(() {
        _isSubmitting = true;
      });
      
      try {
        String? userId = await ref.read(localUserIdProvider.future);
        final event = Event(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
          timeSlots: _timeSlots,
          locationOptions: _locationOptions,
          creatorId: userId,
          creator: _creatorNameController.text.trim(),
        );
        
        // Save the creator name for future use
        _saveCreatorName(_creatorNameController.text.trim());
        
        // Add event to database
        await ref.read(eventsProvider.notifier).addEvent(event);
        
        // Show success and navigate back
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
          
          // 活動創建成功後，顯示分享選項
          await _showShareCreatedEventDialog(event);
          
          // 無論使用者是否選擇分享，都導航到活動詳情頁面
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => EventDetailsScreen(eventId: event.id),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating event: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  // 添加分享創建的活動對話框
  Future<void> _showShareCreatedEventDialog(Event event) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text('活動創建成功！'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('您的活動「${event.title}」已成功創建。現在您可以邀請朋友參加！'),
                const SizedBox(height: 20),
                
                // 各種分享選項
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 系統分享
                    _buildShareOption(
                      icon: Icons.share,
                      label: '分享',
                      color: Colors.blue,
                      onTap: () async {
                        Navigator.of(context).pop();
                        await _shareViaSystem(event);
                      },
                    ),
                    
                    // WhatsApp
                    _buildShareOption(
                      icon: Icons.chat,
                      label: 'WhatsApp',
                      color: Colors.green,
                      onTap: () async {
                        Navigator.of(context).pop();
                        await _shareViaWhatsApp(event);
                      },
                    ),
                    
                    // LINE
                    _buildShareOption(
                      icon: Icons.message,
                      label: 'LINE',
                      color: Colors.green.shade800,
                      onTap: () async {
                        Navigator.of(context).pop();
                        await _shareViaLine(event);
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                // 應用內聯絡人邀請選項
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showInviteFriendsDialog(context, ref, event);
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('邀請應用內聯絡人'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    minimumSize: const Size(double.infinity, 45),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('稍後再說'),
            ),
          ],
        );
      },
    );
  }
  
  // 構建分享選項按鈕
  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            radius: 24,
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  // 通過系統分享對話框分享活動
  Future<void> _shareViaSystem(Event event) async {
    final String shareMessage = 
      '我邀請你參加活動：${event.title}！\n\n'
      '點擊此鏈接加入：${event.getShareLink()}\n'
      '或使用活動代碼：${event.shareCode}';
    
    try {
      await Share.share(shareMessage);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('無法打開分享對話框：$e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
  
  // 通過WhatsApp分享活動
  Future<void> _shareViaWhatsApp(Event event) async {
    final String shareMessage = 
      '我邀請你參加活動：${event.title}！\n'
      '點擊此鏈接加入：${event.getShareLink()}\n'
      '或使用活動代碼：${event.shareCode}';
    
    final Uri whatsappUri = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(shareMessage)}');
    
    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri);
      } else {
        throw Exception('未安裝WhatsApp或無法開啟');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('無法開啟WhatsApp：$e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
  
  // 通過LINE分享活動
  Future<void> _shareViaLine(Event event) async {
    final String shareMessage = 
      '我邀請你參加活動：${event.title}！\n'
      '點擊此鏈接加入：${event.getShareLink()}\n'
      '或使用活動代碼：${event.shareCode}';
    
    final Uri lineUri = Uri.parse('line://msg/text/${Uri.encodeComponent(shareMessage)}');
    
    try {
      if (await canLaunchUrl(lineUri)) {
        await launchUrl(lineUri);
      } else {
        throw Exception('未安裝LINE或無法開啟');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('無法開啟LINE：$e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
  
  // 顯示邀請聯絡人對話框
  Future<void> _showInviteFriendsDialog(BuildContext context, WidgetRef ref, Event event) async {
    // 這裡我們可以復用 EventDetailsScreen 中的邀請好友功能
    // 在實際應用中，您可能想要將這個功能抽象為一個獨立的組件以避免代碼重複
    // 為簡單起見，這裡直接導航到活動詳情頁面
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => EventDetailsScreen(eventId: event.id),
      ),
    );
  }
} 