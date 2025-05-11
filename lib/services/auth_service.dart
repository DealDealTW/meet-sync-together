import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/app_user.dart';

// 創建狀態對象
class AuthState {
  final AppUser? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  // 複製當前狀態並更新部分字段
  AuthState copyWith({
    AppUser? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

// 創建 AuthNotifier 類
class AuthNotifier extends StateNotifier<AuthState> {
  // 初始化為未認證狀態
  AuthNotifier() : super(AuthState());

  // 初始化 Supabase 客戶端 (將在實際集成時使用)
  // Supabase get _supabase => Supabase.instance.client;

  // 模擬用戶登入狀態 (開發階段使用)
  bool _mockAuthenticated = false;
  AppUser? _mockUser;
  
  // 初始化方法
  Future<void> init() async {
    state = state.copyWith(isLoading: true);
    try {
      // 檢查本地存儲的用戶信息
      final prefs = await SharedPreferences.getInstance();
      final String? userJson = prefs.getString('user');
      
      // 以下為實際獲取 Supabase 當前用戶的代碼 (將在實際集成時使用)
      // final currentUser = _supabase.auth.currentUser;
      // if (currentUser != null) {
      //   state = state.copyWith(
      //     user: AppUser.fromSupabaseUser(currentUser.toJson()),
      //     isAuthenticated: true,
      //     isLoading: false,
      //   );
      // } else {
      //   state = state.copyWith(isLoading: false);
      // }
      
      // 以下為開發階段使用的模擬代碼
      if (_mockAuthenticated && _mockUser != null) {
        state = state.copyWith(
          user: _mockUser,
          isAuthenticated: true,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  // 用電子郵件和密碼註冊
  Future<void> signUpWithEmail(String email, String password, String name) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // 實際的 Supabase 註冊代碼 (將在實際集成時使用)
      // final response = await _supabase.auth.signUp(
      //   email: email,
      //   password: password,
      //   data: {'name': name}
      // );
      // final user = response.user;
      // if (user != null) {
      //   state = state.copyWith(
      //     user: AppUser.fromSupabaseUser(user.toJson()),
      //     isAuthenticated: true,
      //     isLoading: false,
      //   );
      // }
      
      // 以下為開發階段使用的模擬代碼 - 允許任何有效註冊直接成功
      if (email.isNotEmpty && password.isNotEmpty && name.isNotEmpty) {
        final mockUser = AppUser(
          id: const Uuid().v4(),
          email: email,
          displayName: name,
        );
        _mockUser = mockUser;
        _mockAuthenticated = true;
        
        // 等待一下來模擬網絡請求
        await Future.delayed(const Duration(milliseconds: 800));
        
        state = state.copyWith(
          user: mockUser,
          isAuthenticated: true,
          isLoading: false,
        );
      } else {
        // 如果任一字段為空，則註冊失敗
        await Future.delayed(const Duration(milliseconds: 800));
        state = state.copyWith(
          error: '所有字段都必須填寫',
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  // 用電子郵件和密碼登入
  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // 實際的 Supabase 登入代碼 (將在實際集成時使用)
      // final response = await _supabase.auth.signInWithPassword(
      //   email: email,
      //   password: password,
      // );
      // final user = response.user;
      // if (user != null) {
      //   state = state.copyWith(
      //     user: AppUser.fromSupabaseUser(user.toJson()),
      //     isAuthenticated: true,
      //     isLoading: false,
      //   );
      // }
      
      // 以下為開發階段使用的模擬代碼 - 修改為允許任何電子郵件和密碼組合登入成功
      // 模擬登入成功
      if (email.isNotEmpty && password.isNotEmpty) {
        // 提取用戶名稱從電子郵件中（例如 user@example.com -> user）
        String displayName = email.split('@').first;
        // 將首字母大寫
        displayName = displayName.substring(0, 1).toUpperCase() + displayName.substring(1);
        
        final mockUser = AppUser(
          id: const Uuid().v4(),
          email: email,
          displayName: displayName,
        );
        _mockUser = mockUser;
        _mockAuthenticated = true;
        
        // 等待一下來模擬網絡請求
        await Future.delayed(const Duration(milliseconds: 800));
        
        state = state.copyWith(
          user: mockUser,
          isAuthenticated: true,
          isLoading: false,
        );
      } else {
        // 如果電子郵件或密碼為空則登入失敗
        await Future.delayed(const Duration(milliseconds: 800));
        state = state.copyWith(
          error: '電子郵件和密碼不能為空',
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  // 透過第三方登入 (Google, Apple, Facebook)
  Future<void> signInWithProvider(String provider) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // 實際的 Supabase 第三方登入代碼 (將在實際集成時使用)
      // 第三方登入可能因平台和配置而有所不同
      // await _supabase.auth.signInWithOAuth(
      //   Provider.values.firstWhere((p) => p.toString() == 'Provider.$provider'),
      // );
      
      // 以下為開發階段使用的模擬代碼
      // 模擬登入成功
      final mockUser = AppUser(
        id: const Uuid().v4(),
        email: 'user@${provider.toLowerCase()}.com',
        displayName: '$provider 用戶',
        photoUrl: 'https://ui-avatars.com/api/?name=$provider+User',
      );
      _mockUser = mockUser;
      _mockAuthenticated = true;
      
      // 等待一下來模擬網絡請求
      await Future.delayed(const Duration(milliseconds: 1200));
      
      state = state.copyWith(
        user: mockUser,
        isAuthenticated: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  // 登出
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // 實際的 Supabase 登出代碼 (將在實際集成時使用)
      // await _supabase.auth.signOut();
      
      // 以下為開發階段使用的模擬代碼
      _mockAuthenticated = false;
      _mockUser = null;
      
      // 等待一下來模擬網絡請求
      await Future.delayed(const Duration(milliseconds: 500));
      
      state = state.copyWith(
        user: null,
        isAuthenticated: false,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  // 重置密碼
  Future<void> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // 實際的 Supabase 重置密碼代碼 (將在實際集成時使用)
      // await _supabase.auth.resetPasswordForEmail(email);
      
      // 以下為開發階段使用的模擬代碼
      // 等待一下來模擬網絡請求
      await Future.delayed(const Duration(milliseconds: 800));
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  // 更新用戶資料
  Future<void> updateUserProfile({String? displayName, String? photoUrl}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      if (state.user == null) {
        throw Exception('用戶未登入');
      }
      
      // 實際的 Supabase 更新用戶資料代碼 (將在實際集成時使用)
      // await _supabase.auth.updateUser(UserAttributes(
      //   data: {
      //     'name': displayName ?? state.user!.displayName,
      //     'avatar_url': photoUrl ?? state.user!.photoUrl,
      //   },
      // ));
      
      // 以下為開發階段使用的模擬代碼
      // 等待一下來模擬網絡請求
      await Future.delayed(const Duration(milliseconds: 800));
      
      final updatedUser = state.user!.copyWith(
        displayName: displayName,
        photoUrl: photoUrl,
      );
      _mockUser = updatedUser;
      
      state = state.copyWith(
        user: updatedUser,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }
}

// 創建 Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

// 創建一個方便獲取當前用戶的 Provider
final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authProvider).user;
});

// 創建一個監聽是否登入的 Provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
}); 