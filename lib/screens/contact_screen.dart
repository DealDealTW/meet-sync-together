import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../models/contact.dart';
import '../services/contact_service.dart';
import '../theme/app_theme.dart'; // For consistent styling
import '../services/auth_service.dart'; // 添加身份驗證服務

class ContactScreen extends ConsumerStatefulWidget {
  const ContactScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends ConsumerState<ContactScreen> {
  ContactStatus _selectedFilter = ContactStatus.invited;
  
  @override
  Widget build(BuildContext context) {
    final contacts = ref.watch(contactsProvider);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // 如果用戶未登入，顯示提示登入的訊息
    if (!isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('聯絡人'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_off_outlined,
                size: 60,
                color: isDark ? Colors.white54 : Colors.grey.shade400,
              ),
              const SizedBox(height: AppTheme.spaceMD),
              Text(
                '請先登入',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTheme.spaceSM),
              Text(
                '您需要登入才能管理聯絡人',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // 根據選定的過濾器篩選聯絡人
    List<Contact> filteredContacts = contacts;
    if (_selectedFilter != ContactStatus.invited) {
      filteredContacts = ref.read(contactsProvider.notifier).getContactsByStatus(_selectedFilter);
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('聯絡人'),
        actions: [
          PopupMenuButton<ContactStatus>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: ContactStatus.invited,
                child: Text('全部聯絡人'),
              ),
              const PopupMenuItem(
                value: ContactStatus.verified,
                child: Text('已驗證'),
              ),
              const PopupMenuItem(
                value: ContactStatus.pending,
                child: Text('待處理'),
              ),
            ],
          ),
        ],
      ),
      body: filteredContacts.isEmpty
          ? _buildEmptyState(isDark, theme)
          : ListView.builder(
              padding: const EdgeInsets.all(AppTheme.spaceMD),
              itemCount: filteredContacts.length,
              itemBuilder: (context, index) {
                final contact = filteredContacts[index];
                return _buildContactItem(contact, isDark, theme, index)
                    .animate()
                    .fadeIn(duration: 300.ms, delay: (50 * index).ms)
                    .slideY(begin: 0.1, end: 0, duration: 300.ms, delay: (50 * index).ms);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditContactDialog(context, null),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 60,
            color: isDark ? Colors.white54 : Colors.grey.shade400,
          ),
          const SizedBox(height: AppTheme.spaceMD),
          Text(
            '沒有聯絡人',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSM),
          Text(
            '添加聯絡人以便邀請他們參加您的活動',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isDark ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: AppTheme.spaceLG),
          ElevatedButton.icon(
            onPressed: () => _showAddEditContactDialog(context, null),
            icon: const Icon(Icons.person_add),
            label: const Text('添加聯絡人'),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildContactItem(Contact contact, bool isDark, ThemeData theme, int index) {
    return Card(
      elevation: isDark ? 2 : 1,
      margin: const EdgeInsets.only(bottom: AppTheme.spaceSM),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMD, vertical: AppTheme.spaceSM),
        leading: CircleAvatar(
          backgroundColor: Color(contact.statusColor).withOpacity(0.2),
          child: Text(
            contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
            style: TextStyle(
              color: Color(contact.statusColor),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          contact.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppTheme.spaceXS),
            if (contact.email != null && contact.email!.isNotEmpty)
              Text(
                contact.email!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
            const SizedBox(height: AppTheme.spaceXS),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceSM, vertical: 2),
              decoration: BoxDecoration(
                color: Color(contact.statusColor).withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              ),
              child: Text(
                contact.statusText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Color(contact.statusColor),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 如果是已邀請狀態，顯示重新發送邀請的按鈕
            if (contact.status == ContactStatus.invited)
              IconButton(
                icon: const Icon(Icons.send),
                tooltip: '重新發送邀請',
                onPressed: () => _showResendInvitationDialog(context, contact),
              ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showAddEditContactDialog(context, contact),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteContactDialog(context, contact),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEditContactDialog(BuildContext context, Contact? contact) {
    final isEditing = contact != null;
    final nameController = TextEditingController(text: isEditing ? contact.name : '');
    final emailController = TextEditingController(text: isEditing ? contact.email ?? '' : '');
    final formKey = GlobalKey<FormState>();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? '編輯聯絡人' : '添加聯絡人'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '名稱',
                    hintText: '請輸入聯絡人名稱',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '請輸入聯絡人名稱';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spaceMD),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: '電子郵件',
                    hintText: '請輸入聯絡人電子郵件',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '請輸入聯絡人電子郵件';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return '請輸入有效的電子郵件地址';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    HapticFeedback.lightImpact();
                    final contactsNotifier = ref.read(contactsProvider.notifier);
                    
                    if (isEditing) {
                      final isEmailChanged = contact.email != emailController.text.trim();
                      if (isEmailChanged) {
                        // 如果電子郵件變更，將狀態重置為已邀請
                        await contactsNotifier.updateContactStatus(contact.id, ContactStatus.invited);
                        // 更新電子郵件
                        await contactsNotifier.updateContactName(contact.id, nameController.text.trim());
                        // 重新發送邀請
                        await contactsNotifier.resendInvitation(contact.id);
                      } else {
                        // 僅更新姓名
                        await contactsNotifier.updateContactName(contact.id, nameController.text.trim());
                      }
                    } else {
                      // 新增聯絡人
                      await contactsNotifier.addContact(
                        name: nameController.text.trim(),
                        email: emailController.text.trim(),
                      );
                    }
                    
                    Navigator.pop(context);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEditing ? '聯絡人已更新' : '聯絡人已新增'),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('錯誤：${e.toString()}'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                }
              },
              child: Text(isEditing ? '更新' : '添加'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteContactDialog(BuildContext context, Contact contact) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('刪除聯絡人'),
          content: Text('確定要刪除 ${contact.name} 嗎？此操作無法撤銷。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                HapticFeedback.lightImpact();
                await ref.read(contactsProvider.notifier).deleteContact(contact.id);
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('聯絡人 ${contact.name} 已刪除'),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('刪除'),
            ),
          ],
        );
      },
    );
  }
  
  void _showResendInvitationDialog(BuildContext context, Contact contact) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('重新發送邀請'),
          content: Text('確定要重新發送邀請給 ${contact.name} (${contact.email}) 嗎？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                HapticFeedback.lightImpact();
                await ref.read(contactsProvider.notifier).resendInvitation(contact.id);
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('邀請已重新發送給 ${contact.name}'),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                );
              },
              child: const Text('發送'),
            ),
          ],
        );
      },
    );
  }
} 