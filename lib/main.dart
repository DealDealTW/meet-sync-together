import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth/login_screen.dart';
import 'services/auth_service.dart';
import 'screens/auth/auth_wrapper.dart';
import 'theme/theme_provider.dart';

// Import models and adapters
import 'models/event.dart';
import 'models/time_slot.dart';
import 'models/participant.dart';
import 'models/location_option.dart';
import 'models/contact.dart';
import 'models/app_user.dart';

// Define _eventsBoxName constant (assuming it might be used elsewhere or defined in event_service.dart)
const String _eventsBoxName = 'eventsBox';
const String _localUserIdKey = 'local_user_id';

// Provider for localUserId
final localUserIdProvider = FutureProvider<String>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  String? userId = prefs.getString('userId');
  
  if (userId == null) {
    userId = const Uuid().v4();
    await prefs.setString('userId', userId);
  }
  
  return userId;
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_TW', null);
  
  // 設置系統UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Hive for all platforms
  await Hive.initFlutter();

  // 註冊 Hive 適配器
  // 注意：由於我們暫時移除了 HiveType 註解，我們需要手動註冊適配器
  Hive.registerAdapter(Event.eventAdapter()); 
  Hive.registerAdapter(TimeSlotAdapter()); 
  Hive.registerAdapter(Participant.participantAdapter());
  Hive.registerAdapter(LocationOptionAdapter()); 
  Hive.registerAdapter(ContactAdapter());

  // Open Hive box(es)
  await Hive.openBox<Event>(_eventsBoxName); // Use constant for box name
  await Hive.openBox<Contact>('contactsBox');

  // 獲取 SharedPreferences 實例，用於主題設置
  final prefs = await SharedPreferences.getInstance();

  // 初始化 Supabase (使用佔位符值)
  // 在實際集成時，您需要提供真實的 URL 和 key
  // await Supabase.initialize(
  //   url: 'YOUR_SUPABASE_URL',
  //   anonKey: 'YOUR_SUPABASE_ANON_KEY',
  // );

  runApp(
    ProviderScope(
      overrides: [
        // 覆蓋 sharedPreferencesProvider，提供實際的 SharedPreferences 實例
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 確保 authProvider 被初始化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).init();
    });
    
    final theme = ref.watch(themeProvider);
    
    return MaterialApp(
      title: 'MeetUp App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: theme == AppThemeMode.dark ? ThemeMode.dark : ThemeMode.light,
      // 使用 AuthWrapper 決定顯示哪個畫面 (登入畫面或主畫面)
      home: const AuthWrapper(),
    );
  }
}
