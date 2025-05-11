import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/contact.dart';
import 'auth_service.dart';

const String _contactsBoxName = 'contactsBox'; // Define box name, consistent with main.dart

// StateNotifierProvider for the ContactsNotifier
final contactsProvider = StateNotifierProvider<ContactsNotifier, List<Contact>>((ref) {
  final box = Hive.box<Contact>(_contactsBoxName);
  return ContactsNotifier(box, ref);
});

class ContactsNotifier extends StateNotifier<List<Contact>> {
  final Box<Contact> _contactsBox;
  final Ref _ref;

  ContactsNotifier(this._contactsBox, this._ref) : super([]) {
    _loadContacts();
  }

  void _loadContacts() {
    final contacts = _contactsBox.values.toList();
    contacts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    state = contacts;
  }

  // 添加新聯絡人
  Future<Contact> addContact({
    required String name,
    required String email,
    ContactStatus status = ContactStatus.invited,
  }) async {
    // 檢查是否已存在相同電子郵件的聯絡人
    final existingContact = state.where((c) => c.email == email).toList();
    if (existingContact.isNotEmpty) {
      throw Exception('已存在相同電子郵件的聯絡人');
    }

    // 生成驗證碼
    final verificationCode = const Uuid().v4().substring(0, 8).toUpperCase();

    // 創建新聯絡人
    final contact = Contact(
      name: name,
      email: email,
      status: status,
      verificationCode: verificationCode,
    );

    // 保存到 Hive
    await _contactsBox.put(contact.id, contact);
    
    // 更新狀態
    state = [contact, ...state];
    
    return contact;
  }

  // 更新聯絡人名稱
  Future<void> updateContactName(String contactId, String newName) async {
    final index = state.indexWhere((contact) => contact.id == contactId);
    if (index >= 0) {
      final contact = state[index];
      final updatedContact = contact.copyWith(name: newName);
      
      await _contactsBox.put(contactId, updatedContact);
      
      state = [
        ...state.sublist(0, index),
        updatedContact,
        ...state.sublist(index + 1),
      ];
    }
  }

  // 更新聯絡人狀態
  Future<void> updateContactStatus(String contactId, ContactStatus newStatus) async {
    final index = state.indexWhere((contact) => contact.id == contactId);
    if (index >= 0) {
      final contact = state[index];
      final DateTime? verifiedAt = newStatus == ContactStatus.verified ? DateTime.now() : contact.verifiedAt;
      
      final updatedContact = contact.copyWith(
        status: newStatus,
        verifiedAt: verifiedAt,
      );
      
      await _contactsBox.put(contactId, updatedContact);
      
      state = [
        ...state.sublist(0, index),
        updatedContact,
        ...state.sublist(index + 1),
      ];
    }
  }
  
  // 將聯絡人與用戶關聯
  Future<void> linkContactToUser(String contactId, String userId) async {
    final index = state.indexWhere((contact) => contact.id == contactId);
    if (index >= 0) {
      final contact = state[index];
      final updatedContact = contact.copyWith(
        userId: userId,
        status: ContactStatus.verified,
        verifiedAt: DateTime.now(),
      );
      
      await _contactsBox.put(contactId, updatedContact);
      
      state = [
        ...state.sublist(0, index),
        updatedContact,
        ...state.sublist(index + 1),
      ];
    }
  }

  // 刪除聯絡人
  Future<void> deleteContact(String contactId) async {
    await _contactsBox.delete(contactId);
    state = state.where((contact) => contact.id != contactId).toList();
  }
  
  // 驗證聯絡人
  Future<bool> verifyContact(String email, String code) async {
    final matchingContacts = state.where((c) => 
      c.email?.toLowerCase() == email.toLowerCase() && 
      c.verificationCode == code &&
      c.status != ContactStatus.verified
    ).toList();
    
    if (matchingContacts.isEmpty) {
      return false;
    }
    
    final contact = matchingContacts.first;
    
    // 獲取當前用戶ID（如果已登入）
    final authState = _ref.read(authProvider);
    final currentUserId = authState.user?.id;
    
    if (currentUserId == null) {
      return false; // 用戶未登入
    }
    
    // 更新聯絡人狀態
    await linkContactToUser(contact.id, currentUserId);
    
    return true;
  }
  
  // 根據電子郵件查找聯絡人
  Contact? findContactByEmail(String email) {
    try {
      return state.firstWhere((c) => c.email?.toLowerCase() == email.toLowerCase());
    } catch (e) {
      return null;
    }
  }
  
  // 獲取特定狀態的聯絡人
  List<Contact> getContactsByStatus(ContactStatus status) {
    return state.where((c) => c.status == status).toList();
  }
  
  // 重新發送邀請
  Future<void> resendInvitation(String contactId) async {
    final index = state.indexWhere((contact) => contact.id == contactId);
    if (index >= 0) {
      final contact = state[index];
      
      // 生成新的驗證碼
      final newVerificationCode = const Uuid().v4().substring(0, 8).toUpperCase();
      
      final updatedContact = contact.copyWith(
        status: ContactStatus.invited,
        verificationCode: newVerificationCode,
      );
      
      await _contactsBox.put(contactId, updatedContact);
      
      state = [
        ...state.sublist(0, index),
        updatedContact,
        ...state.sublist(index + 1),
      ];
      
      // 在這裡可以添加發送邀請郵件的邏輯 (實際整合Supabase時會實現)
    }
  }
} 