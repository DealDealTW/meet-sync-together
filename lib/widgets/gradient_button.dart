import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class GradientButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final double height;
  final double fontSize;
  final IconData? icon;
  final List<Color>? gradientColors;
  final bool isSecondary;
  final BorderRadius? borderRadius;

  const GradientButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 50.0,
    this.fontSize = 16.0,
    this.icon,
    this.gradientColors,
    this.isSecondary = false,
    this.borderRadius,
  }) : super(key: key);

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // 默認漸變色
    final defaultGradient = widget.isSecondary
        ? [
            isDark ? Colors.transparent : Colors.white,
            isDark ? Colors.transparent : Colors.white,
          ]
        : widget.gradientColors ??
            [
              AppTheme.primaryColor,
              AppTheme.secondaryColor,
            ];
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          _animationController.forward();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _animationController.reverse();
          widget.onPressed();
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          _animationController.reverse();
        },
        child: Container(
          height: widget.height,
          width: widget.isFullWidth ? double.infinity : null,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: defaultGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: widget.borderRadius ?? BorderRadius.circular(AppTheme.radiusLG),
            boxShadow: widget.isSecondary
                ? []
                : [
                    BoxShadow(
                      color: defaultGradient.last.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
            border: widget.isSecondary
                ? Border.all(
                    color: isDark
                        ? AppTheme.primaryColor.withOpacity(0.5)
                        : AppTheme.primaryColor.withOpacity(0.3),
                    width: 1.5,
                  )
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(AppTheme.radiusLG),
              splashColor: Colors.white.withOpacity(0.1),
              highlightColor: Colors.transparent,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.isFullWidth ? 20 : 24,
                  vertical: 0,
                ),
                child: Center(
                  child: widget.isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              widget.isSecondary
                                  ? AppTheme.primaryColor
                                  : Colors.white,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.icon != null) ...[
                              Icon(
                                widget.icon,
                                color: widget.isSecondary
                                    ? AppTheme.primaryColor
                                    : Colors.white,
                                size: widget.fontSize + 2,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              widget.text,
                              style: TextStyle(
                                color: widget.isSecondary
                                    ? AppTheme.primaryColor
                                    : Colors.white,
                                fontSize: widget.fontSize,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ).animate(
                          autoPlay: false,
                          controller: _animationController,
                        ).scaleX(
                          begin: 1.0,
                          end: 0.97,
                          curve: Curves.easeInOut,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: 300.ms, curve: Curves.easeOutQuad)
      .slideY(begin: 0.1, end: 0, duration: 300.ms, curve: Curves.easeOutQuad);
  }
} 