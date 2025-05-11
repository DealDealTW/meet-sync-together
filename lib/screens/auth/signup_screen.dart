import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'login_screen.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _attemptSignUp() {
    if (_formKey.currentState!.validate() && _agreeToTerms) {
      HapticFeedback.lightImpact();
      ref.read(authProvider.notifier).signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );
    } else if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('請同意我們的使用條款和隱私政策'),
          backgroundColor: Colors.red,
        ),
      );
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
          '建立帳號',
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
                    children: [
                      // Title
                      Text(
                        '註冊',
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
                        '建立您的帳號，開始使用MeetUp的全部功能',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: isDark ? Colors.white70 : Colors.grey.shade700,
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 200.ms)
                          .slideY(begin: 0.1, end: 0, duration: 400.ms, delay: 200.ms),
                      const SizedBox(height: AppTheme.spaceLG * 1.5),

                      // Name Field
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: '顯示名稱',
                          hintText: '您希望其他人如何稱呼您',
                          prefixIcon: Icon(Icons.person_outline, color: theme.colorScheme.primary.withOpacity(0.7)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                          ),
                          filled: true,
                          fillColor: isDark ? Colors.grey.shade800.withOpacity(0.5) : Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '請輸入您的名稱';
                          }
                          return null;
                        },
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 300.ms)
                          .slideX(begin: 0.05, end: 0, duration: 400.ms, delay: 300.ms),
                      const SizedBox(height: AppTheme.spaceMD),

                      // Email Field
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
                          .fadeIn(duration: 400.ms, delay: 400.ms)
                          .slideX(begin: -0.05, end: 0, duration: 400.ms, delay: 400.ms),
                      const SizedBox(height: AppTheme.spaceMD),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: '密碼',
                          hintText: '最少6個字符',
                          prefixIcon: Icon(Icons.lock_outline, color: theme.colorScheme.primary.withOpacity(0.7)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                          ),
                          filled: true,
                          fillColor: isDark ? Colors.grey.shade800.withOpacity(0.5) : Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '請輸入密碼';
                          }
                          if (value.length < 6) {
                            return '密碼長度必須至少為6個字符';
                          }
                          return null;
                        },
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 500.ms)
                          .slideX(begin: 0.05, end: 0, duration: 400.ms, delay: 500.ms),
                      const SizedBox(height: AppTheme.spaceMD),

                      // Confirm Password Field
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: '確認密碼',
                          hintText: '請再次輸入密碼',
                          prefixIcon: Icon(Icons.lock_outline, color: theme.colorScheme.primary.withOpacity(0.7)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                          ),
                          filled: true,
                          fillColor: isDark ? Colors.grey.shade800.withOpacity(0.5) : Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '請確認您的密碼';
                          }
                          if (value != _passwordController.text) {
                            return '兩次輸入的密碼不一致';
                          }
                          return null;
                        },
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 600.ms)
                          .slideX(begin: -0.05, end: 0, duration: 400.ms, delay: 600.ms),
                      const SizedBox(height: AppTheme.spaceMD),

                      // Terms and Conditions checkbox
                      Row(
                        children: [
                          Checkbox(
                            value: _agreeToTerms,
                            onChanged: (value) {
                              setState(() {
                                _agreeToTerms = value ?? false;
                              });
                            },
                            activeColor: theme.colorScheme.primary,
                          ),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                text: '我同意 MeetUp 的 ',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                                ),
                                children: [
                                  TextSpan(
                                    text: '使用條款',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    recognizer: null, // Add TapGestureRecognizer for real implementation
                                  ),
                                  const TextSpan(text: ' 和 '),
                                  TextSpan(
                                    text: '隱私政策',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    recognizer: null, // Add TapGestureRecognizer for real implementation
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 700.ms),
                      const SizedBox(height: AppTheme.spaceLG),

                      // Error message if any
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

                      // Sign Up Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: authState.isLoading ? null : _attemptSignUp,
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
                                  '註冊',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 800.ms)
                          .slideY(begin: 0.1, end: 0, duration: 400.ms, delay: 800.ms),

                      const SizedBox(height: AppTheme.spaceLG * 1.5),

                      // Already have an account
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '已經有帳號？',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark ? Colors.white70 : Colors.grey.shade700,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              Navigator.pop(context);
                            },
                            child: Text(
                              '立即登入',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 900.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 