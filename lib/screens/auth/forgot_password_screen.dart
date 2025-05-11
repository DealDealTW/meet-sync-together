import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isResetRequested = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _resetPassword() {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      ref.read(authProvider.notifier).resetPassword(_emailController.text.trim()).then((_) {
        setState(() {
          _isResetRequested = true;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          '重置密碼',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
                ? [
                    Colors.blueGrey.shade900,
                    Colors.grey.shade900,
                  ]
                : [
                    Colors.blue.shade50,
                    Colors.white,
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceLG),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _isResetRequested 
                        ? _buildSuccessState(theme, isDark)
                        : _buildFormState(theme, isDark, authState),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSuccessState(ThemeData theme, bool isDark) {
    return [
      Center(
        child: Icon(
          Icons.check_circle_outline,
          size: 80,
          color: Colors.green,
        ),
      )
          .animate()
          .scale(duration: 400.ms),
      const SizedBox(height: AppTheme.spaceLG),
      Center(
        child: Text(
          '重置密碼郵件已發送',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
      )
          .animate()
          .fadeIn(duration: 400.ms, delay: 200.ms),
      const SizedBox(height: AppTheme.spaceMD),
      Center(
        child: Text(
          '我們已向 ${_emailController.text} 發送了一封包含密碼重置鏈接的郵件。請檢查您的郵箱並按照郵件中的指示進行操作。',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: isDark ? Colors.white70 : Colors.grey.shade700,
          ),
          textAlign: TextAlign.center,
        ),
      )
          .animate()
          .fadeIn(duration: 400.ms, delay: 400.ms),
      const SizedBox(height: AppTheme.spaceXXL),
      SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
            elevation: 2,
          ),
          child: const Text(
            '返回登入頁面',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      )
          .animate()
          .fadeIn(duration: 400.ms, delay: 600.ms)
          .slideY(begin: 0.1, end: 0, duration: 400.ms, delay: 600.ms),
    ];
  }

  List<Widget> _buildFormState(ThemeData theme, bool isDark, AuthState authState) {
    return [
      Text(
        '忘記密碼？',
        style: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black,
        ),
      )
          .animate()
          .fadeIn(duration: 400.ms, delay: 100.ms)
          .slideY(begin: 0.1, end: 0, duration: 400.ms, delay: 100.ms),
      const SizedBox(height: AppTheme.spaceXS),
      Text(
        '請輸入您的郵箱地址，我們將向您發送重置密碼的鏈接',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: isDark ? Colors.white70 : Colors.grey.shade700,
        ),
      )
          .animate()
          .fadeIn(duration: 400.ms, delay: 200.ms)
          .slideY(begin: 0.1, end: 0, duration: 400.ms, delay: 200.ms),
      const SizedBox(height: AppTheme.spaceLG * 1.5),
      TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          labelText: '電子郵件',
          hintText: 'your@email.com',
          prefixIcon: Icon(Icons.email_outlined, color: theme.colorScheme.primary.withOpacity(0.7)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          ),
          filled: true,
          fillColor: isDark ? Colors.grey.shade800.withOpacity(0.5) : Colors.white,
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return '請輸入您的電子郵件';
          }
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return '請輸入有效的電子郵件地址';
          }
          return null;
        },
      )
          .animate()
          .fadeIn(duration: 400.ms, delay: 300.ms)
          .slideX(begin: 0.05, end: 0, duration: 400.ms, delay: 300.ms),
      const SizedBox(height: AppTheme.spaceLG),
      if (authState.error != null)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppTheme.spaceSM),
          decoration: BoxDecoration(
            color: theme.colorScheme.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            border: Border.all(
              color: theme.colorScheme.error.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: AppTheme.spaceSM),
              Expanded(
                child: Text(
                  authState.error!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 300.ms)
            .shake(
              duration: 300.ms,
            ),
      if (authState.error != null) const SizedBox(height: AppTheme.spaceMD),
      SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: authState.isLoading ? null : _resetPassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
            elevation: 2,
          ),
          child: authState.isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: theme.colorScheme.onPrimary,
                  ),
                )
              : const Text(
                  '發送重置鏈接',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      )
          .animate()
          .fadeIn(duration: 400.ms, delay: 400.ms)
          .slideY(begin: 0.1, end: 0, duration: 400.ms, delay: 400.ms),
      const SizedBox(height: AppTheme.spaceMD),
      Center(
        child: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            '返回登入頁面',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      )
          .animate()
          .fadeIn(duration: 400.ms, delay: 500.ms),
    ];
  }
} 