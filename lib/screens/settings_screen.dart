import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ADDED
import 'package:url_launcher/url_launcher.dart'; // ADDED for launching URLs
// import 'package:package_info_plus/package_info_plus.dart'; // Commented out for now
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart'; // Import AppTheme for constants

// Provider for PackageInfo
// final packageInfoProvider = FutureProvider<PackageInfo>((ref) async { // Commented out
//   return await PackageInfo.fromPlatform(); // Commented out
// });

const String _userNameKey = 'user_name'; // Key for SharedPreferences
const String _pushNotificationsKey = 'push_notifications_enabled'; // ADDED Key for push notifications

class SettingsScreen extends ConsumerStatefulWidget { // MODIFIED to ConsumerStatefulWidget
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> { // MODIFIED state class
  String _currentUserName = 'Your Name'; // Default or loading state
  // TextEditingController for editing name will be in the dialog
  bool _pushNotificationsEnabled = true; // ADDED state for push notifications, default to true

  // Define placeholder URLs
  final String _privacyPolicyUrl = 'https://example.com/privacy';
  final String _termsOfServiceUrl = 'https://example.com/terms';

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadPushNotificationSetting(); // ADDED call to load setting
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString(_userNameKey);
    if (savedName != null && savedName.isNotEmpty) {
      if (mounted) {
        setState(() {
          _currentUserName = savedName;
        });
      }
    }
  }

  Future<void> _saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
  }

  // ADDED: Load push notification setting
  Future<void> _loadPushNotificationSetting() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSetting = prefs.getBool(_pushNotificationsKey);
    if (savedSetting != null) {
      if (mounted) {
        setState(() {
          _pushNotificationsEnabled = savedSetting;
        });
      }
    }
  }

  // ADDED: Save push notification setting
  Future<void> _savePushNotificationSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pushNotificationsKey, value);
  }

  // ADDED: Helper function to launch URLs
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Log or show an error message if the URL can't be launched
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $urlString')),
        );
      }
    }
  }

  void _showEditUserNameDialog() {
    final userNameController = TextEditingController(text: _currentUserName);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Your Name'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: userNameController,
              decoration: const InputDecoration(labelText: 'Name',
              hintText: 'Enter your name'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name cannot be empty';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final newName = userNameController.text.trim();
                  await _saveUserName(newName);
                  if (mounted) {
                    setState(() {
                      _currentUserName = newName;
                    });
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Name updated!',
                          style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                        ),
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // final packageInfo = ref.watch(packageInfoProvider); // Commented out
    
    return Scaffold(
      // Use scaffoldBackgroundColor from the theme
      backgroundColor: theme.scaffoldBackgroundColor, 
      appBar: AppBar(
        // Use appBarTheme properties from the theme
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        elevation: theme.appBarTheme.elevation ?? 0,
        title: Text(
          'Settings',
          // Use titleTextStyle from appBarTheme, or a style from textTheme
          style: theme.appBarTheme.titleTextStyle ?? theme.textTheme.headlineSmall?.copyWith(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
        ),
        // Use iconTheme from appBarTheme
        iconTheme: theme.appBarTheme.iconTheme ?? IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spaceMD), // Use AppTheme constant
        children: [
          const _SectionHeader(title: 'Profile'),
          const SizedBox(height: AppTheme.spaceMD),
          
          _ProfileCard( // MODIFIED: Pass userName and onEdit callback
            userName: _currentUserName,
            onEditName: _showEditUserNameDialog, 
          ),
          
          const SizedBox(height: AppTheme.spaceLG),
          
          const _SectionHeader(title: 'Appearance'),
          const SizedBox(height: AppTheme.spaceXS),
          
          _SettingTile(
            icon: Icons.dark_mode,
            title: 'Dark Mode',
            trailing: Switch(
              value: isDark,
              onChanged: (value) {
                ref.read(themeProvider.notifier).toggleTheme();
              },
              activeColor: theme.colorScheme.primary,
            ),
          ),
          
          const SizedBox(height: AppTheme.spaceLG),
          const _SectionHeader(title: 'Notifications'),
          const SizedBox(height: AppTheme.spaceXS),
          
          _SettingTile(
            icon: Icons.notifications,
            title: 'Push Notifications',
            subtitle: 'Manage event reminders & updates', // Added subtitle for clarity
            trailing: Switch(
              value: _pushNotificationsEnabled, // MODIFIED to use state variable
              onChanged: (value) { // MODIFIED to update state and save
                setState(() {
                  _pushNotificationsEnabled = value;
                });
                _savePushNotificationSetting(value);
                // Placeholder for actual push notification service call
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Push Notifications ${value ? "Enabled" : "Disabled"}')),
                );
              },
              activeColor: theme.colorScheme.primary,
            ),
          ),
          
          const SizedBox(height: AppTheme.spaceLG),
          const _SectionHeader(title: 'About'),
          const SizedBox(height: AppTheme.spaceXS),
          
          _SettingTile(
            icon: Icons.info_outline,
            title: 'App Version',
            subtitle: '1.0.0 (requires package_info_plus)', // Placeholder for when package_info is commented out
          ),
          
          _SettingTile(
            icon: Icons.text_snippet_outlined,
            title: 'Privacy Policy',
            onTap: () { // MODIFIED to launch URL
              _launchURL(_privacyPolicyUrl);
            },
          ),
          
          _SettingTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () { // MODIFIED to launch URL
              _launchURL(_termsOfServiceUrl);
            },
          ),
          
          const SizedBox(height: AppTheme.spaceLG),
          
          ElevatedButton.icon(
            onPressed: () {
              // Placeholder for Sign Out logic
              // Typically involves clearing user session/token and navigating to login/home screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sign Out tapped (not implemented)')),
              );
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
            style: ElevatedButton.styleFrom(
              // Inherit from theme, but override specific colors for this button
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError, // Usually white for error color
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceSM, horizontal: AppTheme.spaceMD),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD), // Use AppTheme constant
              ),
              textStyle: theme.elevatedButtonTheme.style?.textStyle?.resolve({}) ?? theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onError),
            ),
          ),
          
          const SizedBox(height: AppTheme.spaceXL + AppTheme.spaceMD), // Increased bottom padding
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  
  const _SectionHeader({required this.title});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSM), // Add some bottom padding
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith( // Use a style from textTheme
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String userName;
  final VoidCallback onEditName;
  // final String email;
  
  const _ProfileCard({ // MODIFIED constructor
    required this.userName,
    required this.onEditName,
    // required this.email,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Use CardTheme from AppTheme as a base if possible, or define consistent style here
    return Card(
      elevation: theme.cardTheme.elevation ?? 1.0, // MODIFIED: Use theme.cardTheme.elevation or a default
      color: theme.cardTheme.color, // MODIFIED: Directly use theme.cardTheme.color; AppTheme should handle dark/light specifics
      shape: theme.cardTheme.shape ?? RoundedRectangleBorder( // Use theme.cardTheme.shape
        borderRadius: BorderRadius.circular(AppTheme.radiusLG), // Use AppTheme constant
        side: BorderSide(
          color: theme.dividerColor, // Use theme.dividerColor
          width: 1,
        ),
      ),
      margin: const EdgeInsets.only(bottom: AppTheme.spaceSM),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMD),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: theme.colorScheme.primary,
              child: Text( 
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U', // Use first letter of userName
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimary, // MODIFIED: Use onPrimary for better contrast
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName, // Display dynamic userName
                    style: theme.textTheme.titleLarge?.copyWith(
                       fontWeight: FontWeight.bold,
                       color: theme.textTheme.titleLarge?.color ?? (isDark ? Colors.white : Colors.black), // MODIFIED: Prefer theme text color
                    ),
                  ),
                  // Removed email Text field for now
                  // const SizedBox(height: AppTheme.spaceXS),
                  // Text(
                  //   'user.email@example.com', // Placeholder
                  //   style: theme.textTheme.bodyMedium?.copyWith(
                  //     color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  //   ),
                  // ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.edit,
                color: theme.colorScheme.primary,
              ),
              onPressed: onEditName, // Call onEditName callback
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  // final bool isDark; // isDark can be derived from Theme.of(context)
  
  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    // required this.isDark, // Removed
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Try to use ListTileTheme or define consistent style here
    return Card(
      elevation: 0,
      color: Colors.transparent, // Keep transparent to show ListTile's own shape/border
      margin: const EdgeInsets.only(bottom: AppTheme.spaceSM), // Use AppTheme constant
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMD, vertical: AppTheme.spaceXS), // Use AppTheme constants
        leading: Icon(
          icon,
          color: theme.colorScheme.secondary, // MODIFIED: Changed from primary to secondary for a softer look
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith( // Use textTheme
            fontWeight: FontWeight.w500,
            color: theme.textTheme.titleMedium?.color ?? (isDark ? Colors.white70 : Colors.black87), // MODIFIED: Prefer theme text color or a slightly adjusted default
          ),
        ),
        subtitle: subtitle != null 
            ? Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith( // Use textTheme
                  color: theme.hintColor, // MODIFIED: Use theme.hintColor for subtitle
                ),
              )
            : null,
        trailing: trailing,
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD), // Use AppTheme constant
          side: BorderSide(
            color: theme.dividerColor, // Use theme.dividerColor
            width: 1,
          ),
        ),
      ),
    );
  }
} 