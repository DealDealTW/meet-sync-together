import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../services/event_service.dart';
import '../models/event.dart';
import '../models/participant.dart';
import '../models/time_slot.dart';
import 'create_event_screen.dart';
import 'event_details_screen.dart';
import 'settings_screen.dart';
import 'contact_screen.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0; // 底部導航索引
  int _selectedTabIndex = 0; // 頂部標籤索引
  final List<String> _tabs = ['All', 'Upcoming', 'Past'];
  late AnimationController _animationController;
  
  // ADDED: Define the pages for the BottomNavigationBar
  final List<Widget> _pages = <Widget>[
    const EventsView(), // Placeholder for the actual events list view/widget
    const ContactScreen(), // ADDED: ContactScreen
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // It's good practice to load initial data in initState or via a FutureProvider
    // if it's an async operation not tied to user interaction triggering a rebuild.
    // However, Riverpod typically handles this well if eventsProvider.notifier.loadEvents()
    // is called when the provider is first read, or if an autoDispose provider refetches.
    // For now, assuming loadEvents is either called by the provider itself or elsewhere appropriately.
    // ref.read(eventsProvider.notifier).loadEvents(); // Potentially add here if not loaded elsewhere

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    // 延遲一下以確保UI已經構建完成
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) { // Check if the widget is still in the tree
        _animationController.forward();
      }
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // final eventsState = ref.watch(eventsProvider);
    // final List<Event> allEvents = eventsState.events;
    // final isLoading = eventsState.isLoading;
    // final error = eventsState.error;
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filtered events logic and sorting logic moved to EventsView

    // The main Scaffold structure
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _selectedIndex == 0 // Only show custom AppBar for Events tab
          ? AppBar(
              backgroundColor: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
              elevation: 0,
              titleSpacing: 16,
              title: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryColor,
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
                    style: theme.appBarTheme.titleTextStyle?.copyWith(
                      color: isDark ? Colors.white : theme.appBarTheme.titleTextStyle?.color ?? AppTheme.textColor,
                    ),
                  ),
                ],
              ).animate(controller: _animationController)
              .fadeIn(duration: 500.ms, curve: Curves.easeOutQuad)
              .slideX(begin: -0.1, end: 0, duration: 500.ms, curve: Curves.easeOutQuad),
              actions: [
                IconButton(
                  icon: Icon(
                    isDark ? Icons.light_mode : Icons.dark_mode,
                    color: isDark ? Colors.white : AppTheme.textColor,
                  ),
                  onPressed: () {
                    ref.read(themeProvider.notifier).toggleTheme();
                  },
                ),
              ],
            )
          : null, // No AppBar for Contacts and Settings, they have their own
      body: _buildBody(), // Use the helper to build body
      // FloatingActionButton logic can be moved to EventsView if specific to it
      // fab logic might need to be conditional based on _selectedIndex or removed from here
      // For simplicity, let's assume FAB is part of EventsView for now if it was there.
      // If FAB was for "Create Event", it makes sense for it to be on the EventsView.

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: theme.bottomNavigationBarTheme.backgroundColor,
        selectedItemColor: theme.bottomNavigationBarTheme.selectedItemColor ?? AppTheme.primaryColor,
        unselectedItemColor: theme.bottomNavigationBarTheme.unselectedItemColor ?? (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
        selectedLabelStyle: theme.bottomNavigationBarTheme.selectedLabelStyle,
        unselectedLabelStyle: theme.bottomNavigationBarTheme.unselectedLabelStyle,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (int index) {
          HapticFeedback.lightImpact();
          setState(() {
            _selectedIndex = index;
            // Reset tab index if navigating away from Events page
            if (_selectedIndex != 0) {
              _selectedTabIndex = 0; 
            }
          });
        },
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.event_rounded),
            label: 'Events',
          ),
          BottomNavigationBarItem( // ADDED: Contacts Tab
            icon: Icon(Icons.people_alt_rounded),
            label: 'Contacts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  // ADDED: Helper method to build the body based on _selectedIndex
  Widget _buildBody() {
    // If Events tab is selected, show EventsView (which includes tabs and list)
    // Otherwise, show the selected page directly
    if (_selectedIndex == 0) {
      return const EventsView(); // Assuming EventsView handles its own tab logic and event list
    }
    return _pages[_selectedIndex];
  }
}

// NEW WIDGET: EventsView to encapsulate event listing and tab logic
class EventsView extends ConsumerStatefulWidget {
  const EventsView({Key? key}) : super(key: key);

  @override
  _EventsViewState createState() => _EventsViewState();
}

class _EventsViewState extends ConsumerState<EventsView> with SingleTickerProviderStateMixin {
  int _selectedTabIndex = 0; //頂部標籤索引 (moved from _HomeScreenState)
  final List<String> _tabs = ['All', 'Upcoming', 'Past']; // (moved from _HomeScreenState)
  late AnimationController _animationController; // (moved from _HomeScreenState)
  // ScrollController for RefreshIndicator
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
     _animationController = AnimationController( // (moved from _HomeScreenState)
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    Future.delayed(const Duration(milliseconds: 100), () { // (moved from _HomeScreenState)
      if (mounted) {
        _animationController.forward();
      }
    });
    // Initial data load if necessary (e.g., if not auto-disposed and re-fetched by provider)
    // ref.read(eventsProvider.notifier).loadEvents(); 
  }

  @override
  void dispose() {
    _animationController.dispose(); // (moved from _HomeScreenState)
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _refreshEvents() async {
    HapticFeedback.mediumImpact();
    // Assuming your eventsProvider.notifier has a method to reload/refresh events
    // For example, if loadEvents() fetches from scratch:
    try {
      await ref.read(eventsProvider.notifier).loadEvents(); // Or a specific refreshEvents method
    } catch (e) {
      // Handle error, maybe show a SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing events: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsState = ref.watch(eventsProvider);
    final List<Event> allEvents = eventsState.events;
    final isLoading = eventsState.isLoading;
    final error = eventsState.error;
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    List<Event> filteredEvents;
    if (_selectedTabIndex == 0) { // All
      filteredEvents = allEvents;
    } else if (_selectedTabIndex == 1) { // Upcoming
      filteredEvents = allEvents.where((event) => !event.isPast && !event.isFinalized).toList();
    } else { // Past (index 2)
      filteredEvents = allEvents.where((event) {
        if (event.isPast) return true;
        if (event.isFinalized) {
          if (event.timeSlots.isEmpty) {
            return event.createdAt.isBefore(DateTime.now().subtract(const Duration(days: 1))); 
          }
          return !event.isHappeningSoon && event.timeSlots.any((ts) => ts.startTime.isBefore(DateTime.now()));
        }
        return false;
      }).toList();
    }

    filteredEvents.sort((a, b) {
      bool aIsUpcoming = !a.isPast && !a.isFinalized;
      bool bIsUpcoming = !b.isPast && !b.isFinalized;
      bool aIsSoon = a.isHappeningSoon;
      bool bIsSoon = b.isHappeningSoon;

      if (aIsUpcoming && !bIsUpcoming) return -1;
      if (!aIsUpcoming && bIsUpcoming) return 1;

      if (aIsUpcoming && bIsUpcoming) {
        if (aIsSoon && !bIsSoon) return -1;
        if (!aIsSoon && bIsSoon) return 1;
        DateTime? aFirstStart = a.timeSlots.isNotEmpty ? a.timeSlots.map((ts) => ts.startTime).reduce((min, e) => e.isBefore(min) ? e : min) : null;
        DateTime? bFirstStart = b.timeSlots.isNotEmpty ? b.timeSlots.map((ts) => ts.startTime).reduce((min, e) => e.isBefore(min) ? e : min) : null;
        if (aFirstStart != null && bFirstStart != null) {
          return aFirstStart.compareTo(bFirstStart);
        }
        return a.createdAt.compareTo(b.createdAt); 
      }

      if (a.isPast && !b.isPast) return 1; 
      if (!a.isPast && b.isPast) return -1;

      if (a.isPast && b.isPast) {
        DateTime? aLastEnd = a.timeSlots.isNotEmpty ? a.timeSlots.map((ts) => ts.endTime).reduce((max, e) => e.isAfter(max) ? e : max) : null;
        DateTime? bLastEnd = b.timeSlots.isNotEmpty ? b.timeSlots.map((ts) => ts.endTime).reduce((max, e) => e.isAfter(max) ? e : max) : null;
        if (aLastEnd != null && bLastEnd != null) {
          return bLastEnd.compareTo(aLastEnd); 
        }
      }
      
      if (a.isFinalized && !b.isFinalized) return 1;
      if (!a.isFinalized && b.isFinalized) return -1;

      return b.createdAt.compareTo(a.createdAt); 
    });

    // Encapsulated Event listing UI
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container( // Header for "My Events" and "New" button
            color: theme.scaffoldBackgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Events',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: isDark ? Colors.white : AppTheme.textColor,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateEventScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                      elevation: 1,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                ),
              ],
            ).animate(controller: _animationController)
             .fadeIn(duration: 600.ms, curve: Curves.easeOutQuad)
             .slideY(begin: -0.1, end: 0, duration: 600.ms, curve: Curves.easeOutQuad),
          ),
          
          // Horizontal tab bar
          Container(
            color: theme.scaffoldBackgroundColor,
            margin: const EdgeInsets.only(top: 8, bottom: AppTheme.spaceSM),
            height: 40,
            child: Row(
              children: [
                const SizedBox(width: 16),
                for (int i = 0; i < _tabs.length; i++)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTabIndex = i;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: _selectedTabIndex == i
                            ? Border(
                                bottom: BorderSide(
                                  color: theme.colorScheme.primary,
                                  width: 2,
                                ),
                              )
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          _tabs[i],
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: _selectedTabIndex == i
                                ? theme.colorScheme.primary
                                : theme.hintColor,
                            fontWeight: _selectedTabIndex == i
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 16),
              ],
            ),
          ),
          
          Expanded(
            child: isLoading && allEvents.isEmpty // Show shimmer only if loading and no events yet
                ? _buildShimmerLoading(context, isDark)
                : error != null
                    ? _buildErrorState(context, error, isDark)
                    : filteredEvents.isEmpty
                        ? _buildEmptyState(context, isDark)
                        : RefreshIndicator(
                            onRefresh: _refreshEvents,
                            color: theme.colorScheme.primary,
                            backgroundColor: theme.cardColor,
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                              itemCount: filteredEvents.length,
                              itemBuilder: (context, index) {
                                final event = filteredEvents[index];
                                return _buildEventCard(context, event, ref, isDark, index)
                                    .animate()
                                    .fadeIn(delay: (100 * (index % 10)).ms, duration: 400.ms, curve: Curves.easeOutQuad)
                                    .slideY(begin: 0.1, end: 0, delay: (100 * (index % 10)).ms, duration: 400.ms, curve: Curves.easeOutQuad);
                              },
                            ),
                          ),
          ),
        ],
      );
  }

  Widget _buildEventCard(BuildContext context, Event event, WidgetRef ref, bool isDark, int index) {
    final theme = Theme.of(context);
    String timeInfo = "No time slots";
    bool hasTimeSlots = event.timeSlots.isNotEmpty;
    bool isFinalized = event.isFinalized;
    TimeSlot? chosenTimeSlot = event.getFinalizedTimeSlot();

    if (isFinalized) {
      if (chosenTimeSlot != null) {
        timeInfo = 'Finalized: ${DateFormat.MMMd().add_jm().format(chosenTimeSlot.startTime)}';
      } else {
        timeInfo = "Finalized (No specific time)";
      }
    } else if (hasTimeSlots) {
      DateTime? earliestStartTime = event.timeSlots
          .map((ts) => ts.startTime)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      timeInfo = 'Starts: ${DateFormat.MMMd().add_jm().format(earliestStartTime)}';
      if (event.timeSlots.length > 1) {
        timeInfo += ' (+${event.timeSlots.length - 1} more)';
      }
    }

    String locationInfo = "No location specified";
    if (event.locationOptions.isNotEmpty) {
      locationInfo = event.locationOptions.first.name;
      if (event.locationOptions.length > 1) {
        locationInfo += ' (+${event.locationOptions.length - 1})';
      }
    }
    
    final cardElevation = theme.cardTheme.elevation ?? (isDark ? 1.0 : 2.0);

    return Card(
      elevation: cardElevation,
      shadowColor: isDark ? Colors.black.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      ),
      color: theme.cardTheme.color,
      margin: const EdgeInsets.only(bottom: AppTheme.spaceMD + AppTheme.spaceXXS),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailsScreen(eventId: event.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        splashColor: theme.colorScheme.primary.withOpacity(0.1),
        highlightColor: theme.colorScheme.primary.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : theme.textTheme.titleLarge?.color,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (event.isHappeningSoon && !isFinalized)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceSM, vertical: AppTheme.spaceXS/2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                      ),
                      child: Text(
                        'SOON',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (isFinalized)
                     Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceSM, vertical: AppTheme.spaceXS/2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                      ),
                      child: Text(
                        'FINALIZED',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (event.isPast)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceSM, vertical: AppTheme.spaceXS/2),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                      ),
                      child: Text(
                        'PAST',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceSM),
              if (event.description?.isNotEmpty ?? false) ...[
                Text(
                  event.description ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTheme.spaceSM),
              ],
              Row(
                children: [
                  Icon(Icons.location_on_outlined, color: theme.hintColor, size: 16),
                  const SizedBox(width: AppTheme.spaceXS),
                  Expanded(
                    child: Text(
                      locationInfo,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceXS),
              Row(
                children: [
                  Icon(Icons.access_time_rounded, color: theme.hintColor, size: 16),
                  const SizedBox(width: AppTheme.spaceXS),
                  Expanded(
                    child: Text(
                      timeInfo,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceMD),
              _buildParticipantAvatars(context, event.participants, theme, isDark),
            ],
          ),
        ),
      ),
    );
  }

 Widget _buildParticipantAvatars(BuildContext context, List<Participant> participants, ThemeData theme, bool isDark) {
    if (participants.isEmpty) {
      return Text(
        'No participants yet.',
        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
      );
    }

    const maxAvatars = 5;
    final displayParticipants = participants.take(maxAvatars).toList();
    final remainingCount = participants.length - maxAvatars;

    return Row(
      children: [
        ...displayParticipants.map((p) {
          final initial = p.name.isNotEmpty ? p.name[0].toUpperCase() : '?';
          return Container(
            margin: const EdgeInsets.only(right: AppTheme.spaceXS/2),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: theme.colorScheme.primary.withOpacity(isDark ? 0.3 : 0.15),
              child: Text(
                initial,
                style: TextStyle(fontSize: 12, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }).toList(),
        if (remainingCount > 0)
          Padding(
            padding: const EdgeInsets.only(left: AppTheme.spaceXS/2),
            child: Text(
              '+${remainingCount} more',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor, fontWeight: FontWeight.w500),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.event_busy_outlined, size: 60, color: theme.hintColor.withOpacity(0.7)),
          const SizedBox(height: AppTheme.spaceMD),
          Text(
            'No events here!',
            style: theme.textTheme.headlineSmall?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: AppTheme.spaceSM),
          Text(
            _selectedTabIndex == 0 ? 'Tap "New" to create your first event.' : 'Try a different filter or create an event.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor.withOpacity(0.8)),
          ),
        ],
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  Widget _buildErrorState(BuildContext context, String? error, bool isDark) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 60),
            const SizedBox(height: AppTheme.spaceMD),
            Text(
              'Oops! Something went wrong.',
              style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spaceSM),
            Text(
              error ?? 'Could not load events. Please try again later.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor),
            ),
            const SizedBox(height: AppTheme.spaceLG),
            ElevatedButton.icon(
              onPressed: _refreshEvents,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.errorContainer,
                foregroundColor: theme.colorScheme.onErrorContainer,
              ),
            )
          ],
        ).animate().fadeIn(duration: 300.ms),
      ),
    );
  }

  Widget _buildShimmerLoading(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final shimmerBaseColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;
    final shimmerHighlightColor = isDark ? Colors.grey[600]! : Colors.grey[200]!;

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 5, // Number of shimmer items
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: shimmerBaseColor,
          highlightColor: shimmerHighlightColor,
          period: const Duration(milliseconds: 1200),
          child: Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLG)),
            margin: const EdgeInsets.only(bottom: AppTheme.spaceMD + AppTheme.spaceXXS),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: double.infinity, height: 20.0, color: Colors.white),
                  const SizedBox(height: AppTheme.spaceSM),
                  Container(width: double.infinity, height: 14.0, color: Colors.white),
                  const SizedBox(height: AppTheme.spaceXS),
                  Container(width: MediaQuery.of(context).size.width * 0.6, height: 14.0, color: Colors.white),
                  const SizedBox(height: AppTheme.spaceMD),
                  Row(
                    children: List.generate(3, (i) => Padding(
                      padding: const EdgeInsets.only(right: AppTheme.spaceXS),
                      child: CircleAvatar(radius: 14, backgroundColor: Colors.white),
                    )),
                  )
                ],
              ),
            ),
          ),
        );
      },
    ).animate().fadeIn();
  }
}

// Helper extension for Shimmer (if you don't have flutter_animate you might need to implement Shimmer differently or remove it)
// This is a simplified placeholder. For a real shimmer, you'd use a package like `shimmer`.
// Since flutter_animate is used, we can leverage its Shimmer effect if available, or build a basic one.

// Basic Shimmer Widget (if not using a package) - This is VERY basic.
// Consider using the `shimmer` package for a better effect.
// For now, assuming `Shimmer.fromColors` is available (e.g. from `flutter_animate` or `shimmer` package)

// Placeholder Shimmer.fromColors if flutter_animate doesn't directly provide it
// You would typically use the shimmer package: ^2.0.0 or similar
// For this example, I'll assume a Shimmer widget structure for the _buildShimmerLoading.
// If Shimmer.fromColors is not found, you'll need to add the dependency or remove its usage.
// Example of a simple Shimmer widget (conceptual):
class Shimmer extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration period;

  const Shimmer.fromColors({
    Key? key,
    required this.child,
    required this.baseColor,
    required this.highlightColor,
    this.period = const Duration(milliseconds: 1500),
  }) : super(key: key);

  @override
  _ShimmerState createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.period)
      ..addListener(() {
        setState(() {});
      })
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) {
        return LinearGradient(
          colors: [widget.baseColor, widget.highlightColor, widget.baseColor],
          stops: const [0.0, 0.5, 1.0], // Adjust stops for desired effect
          begin: Alignment(-1.0 - _controller.value * 2, -0.3), // Animate the gradient
          end: Alignment(1.0 + _controller.value * 2, 0.3),
          tileMode: TileMode.clamp,
        ).createShader(bounds);
      },
      child: widget.child,
    );
  }
} 