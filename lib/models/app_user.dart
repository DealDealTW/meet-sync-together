import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

// 暫時移除 part 聲明直到我們運行 build_runner
// part 'app_user.g.dart';

// 手動添加 typeId，不使用 HiveType 註解
class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final Map<String, dynamic>? metadata;
  
  AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    this.metadata,
  }) : 
    this.createdAt = createdAt ?? DateTime.now(),
    this.lastLoginAt = lastLoginAt ?? DateTime.now();
  
  // 根據 Supabase User 創建 AppUser
  factory AppUser.fromSupabaseUser(Map<String, dynamic> user) {
    return AppUser(
      id: user['id'] ?? const Uuid().v4(),
      email: user['email'] ?? '',
      displayName: user['user_metadata']?['name'],
      photoUrl: user['user_metadata']?['avatar_url'],
      createdAt: user['created_at'] != null 
        ? DateTime.parse(user['created_at']) 
        : DateTime.now(),
      lastLoginAt: DateTime.now(),
      metadata: user['user_metadata'],
    );
  }
  
  // 創建一個虛擬的 AppUser 用於開發/測試
  factory AppUser.dummy() {
    return AppUser(
      id: const Uuid().v4(),
      email: 'user@example.com',
      displayName: '測試用戶',
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
  }
  
  // 複製當前物件並更新部分字段
  AppUser copyWith({
    String? displayName,
    String? photoUrl,
    DateTime? lastLoginAt,
    Map<String, dynamic>? metadata,
  }) {
    return AppUser(
      id: this.id,
      email: this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: this.createdAt,
      lastLoginAt: lastLoginAt ?? DateTime.now(),
      metadata: metadata ?? this.metadata,
    );
  }
} 