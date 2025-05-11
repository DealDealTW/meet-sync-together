import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
// import 'package:uuid/uuid.dart'; // We'll assume uuid is available for robust ID generation, actual use in service layer

// 暫時移除 part 聲明直到我們運行 build_runner
// part 'contact.g.dart'; // For future hive_generator use

enum ContactStatus {
  pending, // 待處理，尚未確認
  verified, // 已確認
  rejected, // 已拒絕
  invited, // 已邀請，等待接受
}

// 手動添加 typeId，不使用 HiveType 註解
class Contact extends HiveObject {
  final String id;
  final String name;
  final DateTime createdAt;
  final String? email; // 添加電子郵件字段
  final ContactStatus status; // 添加驗證狀態
  final DateTime? verifiedAt; // 驗證時間
  final String? userId; // 關聯的用戶ID（如果已驗證）
  final String? verificationCode; // 驗證碼

  Contact({
    String? id,
    required this.name,
    required this.email,
    DateTime? createdAt,
    this.status = ContactStatus.invited,
    this.verifiedAt,
    this.userId,
    this.verificationCode,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.createdAt = createdAt ?? DateTime.now();

  // 取得狀態的顯示文字
  String get statusText {
    switch (status) {
      case ContactStatus.pending:
        return '待處理';
      case ContactStatus.verified:
        return '已驗證';
      case ContactStatus.rejected:
        return '已拒絕';
      case ContactStatus.invited:
        return '已邀請';
      default:
        return '未知';
    }
  }

  // 取得狀態顏色（可用於UI顯示）
  int get statusColor {
    switch (status) {
      case ContactStatus.pending:
        return 0xFFFFA500; // 橙色
      case ContactStatus.verified:
        return 0xFF4CAF50; // 綠色
      case ContactStatus.rejected:
        return 0xFFF44336; // 紅色
      case ContactStatus.invited:
        return 0xFF2196F3; // 藍色
      default:
        return 0xFF757575; // 灰色
    }
  }

  // 複製當前對象並更新部分字段
  Contact copyWith({
    String? name,
    String? email,
    ContactStatus? status,
    DateTime? verifiedAt,
    String? userId,
    String? verificationCode,
  }) {
    return Contact(
      id: this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: this.createdAt,
      status: status ?? this.status,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      userId: userId ?? this.userId,
      verificationCode: verificationCode ?? this.verificationCode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
      'status': status.toString(),
    };
  }

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  String toString() => 'Contact(id: $id, name: $name, email: $email, createdAt: $createdAt)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Contact &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ email.hashCode ^ createdAt.hashCode;
}

// Manual Hive Adapter (ContactAdapter)
class ContactAdapter extends TypeAdapter<Contact> {
  @override
  final int typeId = 4;

  @override
  Contact read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Contact(
      id: fields[0] as String,
      name: fields[1] as String,
      email: fields[2] as String? ?? '',
      createdAt: fields[3] as DateTime,
      status: fields[4] as ContactStatus? ?? ContactStatus.invited,
      verifiedAt: fields[5] as DateTime?,
      userId: fields[6] as String?,
      verificationCode: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Contact obj) {
    writer
      ..writeByte(8) // 更新字段數量
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.verifiedAt)
      ..writeByte(6)
      ..write(obj.userId)
      ..writeByte(7)
      ..write(obj.verificationCode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
} 