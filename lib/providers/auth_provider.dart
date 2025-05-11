import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppUser {
  final String id;
  final String? name;
  final String? email;

  AppUser({
    required this.id,
    this.name,
    this.email,
  });
}

class AuthState {
  final AppUser? currentUser;
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;

  AuthState({
    this.currentUser,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    AppUser? currentUser,
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      currentUser: currentUser ?? this.currentUser,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    // 初始化時設置一個測試用戶，方便測試聊天功能
    _initTestUser();
  }

  void _initTestUser() {
    // 僅用於前端測試
    state = state.copyWith(
      currentUser: AppUser(
        id: 'test_user',
        name: '測試用戶',
        email: 'test@example.com',
      ),
      isAuthenticated: true,
    );
  }

  // 實際實現中，這些方法會與Supabase交互
  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // 模擬網絡請求延遲
      await Future.delayed(const Duration(seconds: 1));
      
      // 模擬登入成功
      state = state.copyWith(
        currentUser: AppUser(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          name: email.split('@').first,
          email: email,
        ),
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

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    
    try {
      // 模擬網絡請求延遲
      await Future.delayed(const Duration(seconds: 1));
      
      // 清除用戶狀態
      state = AuthState();
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> updateUserProfile({String? name, String? email}) async {
    if (state.currentUser == null) return;
    
    state = state.copyWith(isLoading: true);
    
    try {
      // 模擬網絡請求延遲
      await Future.delayed(const Duration(seconds: 1));
      
      // 更新用戶信息
      state = state.copyWith(
        currentUser: AppUser(
          id: state.currentUser!.id,
          name: name ?? state.currentUser!.name,
          email: email ?? state.currentUser!.email,
        ),
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

// 提供Auth狀態的Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

// 提供當前用戶ID的Provider (便於其他組件使用)
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).currentUser?.id;
});

// 提供當前用戶名稱的Provider
final currentUserNameProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).currentUser?.name;
}); 