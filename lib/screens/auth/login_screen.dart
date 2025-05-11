import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _attemptLogin() {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      ref.read(authProvider.notifier).signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }
  }

  void _signInWithProvider(String provider) {
    HapticFeedback.lightImpact();
    ref.read(authProvider.notifier).signInWithProvider(provider);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo and App Name
                      CircleAvatar(
                        backgroundColor: theme.colorScheme.primary,
                        radius: 40,
                        child: const Icon(
                          Icons.calendar_today_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 100.ms)
                          .scale(begin: const Offset(0.5, 0.5), duration: 400.ms),
                      const SizedBox(height: AppTheme.spaceMD),
                      Text(
                        'MeetUp',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 250.ms)
                          .slideY(begin: 0.2, end: 0, duration: 400.ms, delay: 250.ms),
                      const SizedBox(height: AppTheme.spaceXS),
                      Text(
                        '安排您的活動從未如此簡單',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: isDark ? Colors.white70 : Colors.grey.shade700,
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 350.ms)
                          .slideY(begin: 0.2, end: 0, duration: 400.ms, delay: 350.ms),
                      SizedBox(height: size.height * 0.06),

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
                          .fadeIn(duration: 400.ms, delay: 450.ms)
                          .slideX(begin: 0.1, end: 0, duration: 400.ms, delay: 450.ms),
                      const SizedBox(height: AppTheme.spaceMD),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: '密碼',
                          hintText: '請輸入您的密碼',
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
                            return '請輸入您的密碼';
                          }
                          return null;
                        },
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 550.ms)
                          .slideX(begin: -0.1, end: 0, duration: 400.ms, delay: 550.ms),
                      const SizedBox(height: AppTheme.spaceSM),

                      // Remember me and Forgot password
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },
                                activeColor: theme.colorScheme.primary,
                              ),
                              Text(
                                '記住我',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ForgotPasswordScreen(),
                                ),
                              );
                            },
                            child: Text(
                              '忘記密碼？',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 650.ms),
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

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: authState.isLoading ? null : _attemptLogin,
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
                                  '登入',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 750.ms)
                          .slideY(begin: 0.1, end: 0, duration: 400.ms, delay: 750.ms),

                      const SizedBox(height: AppTheme.spaceLG),

                      // Or Sign In with
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMD),
                            child: Text(
                              '或者使用其他方式登入',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDark ? Colors.white70 : Colors.grey.shade700,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                            ),
                          ),
                        ],
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 850.ms),

                      const SizedBox(height: AppTheme.spaceLG),

                      // Social Sign In Options
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Google
                          _buildSocialButton(
                            onPressed: () => _signInWithProvider('Google'),
                            icon: Icons.g_mobiledata_rounded,
                            iconColor: Colors.red,
                            backgroundColor: isDark ? Colors.grey.shade800 : Colors.white,
                            delay: 950,
                          ),
                          const SizedBox(width: AppTheme.spaceMD),
                          // Apple
                          _buildSocialButton(
                            onPressed: () => _signInWithProvider('Apple'),
                            icon: Icons.apple_rounded,
                            iconColor: isDark ? Colors.white : Colors.black,
                            backgroundColor: isDark ? Colors.grey.shade800 : Colors.white,
                            delay: 1050,
                          ),
                          const SizedBox(width: AppTheme.spaceMD),
                          // Facebook
                          _buildSocialButton(
                            onPressed: () => _signInWithProvider('Facebook'),
                            icon: Icons.facebook_rounded,
                            iconColor: Colors.blue,
                            backgroundColor: isDark ? Colors.grey.shade800 : Colors.white,
                            delay: 1150,
                          ),
                        ],
                      ),

                      const SizedBox(height: AppTheme.spaceXXL),

                      // Register option
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '還沒有帳號？',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark ? Colors.white70 : Colors.grey.shade700,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignupScreen(),
                                ),
                              );
                            },
                            child: Text(
                              '立即註冊',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 1250.ms),
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

  Widget _buildSocialButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required int delay,
  }) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 30,
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: delay.ms);
  }
} 