import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class InputField extends StatefulWidget {
  final String label;
  final String? placeholder;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final bool required;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final FocusNode? focusNode;
  final VoidCallback? onTap;
  final bool readOnly;
  final Widget? prefix;
  final Widget? suffix;
  final EdgeInsetsGeometry? contentPadding;
  final TextCapitalization textCapitalization;
  final TextAlign textAlign;
  final String? helperText;
  final String? errorText;
  final BoxConstraints? prefixIconConstraints;
  final BoxConstraints? suffixIconConstraints;
  final Color? fillColor;
  final Color? labelColor;
  final double? borderRadius;
  final TextInputAction? textInputAction;

  const InputField({
    Key? key,
    required this.label,
    this.placeholder,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.required = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.enabled = true,
    this.focusNode,
    this.onTap,
    this.readOnly = false,
    this.prefix,
    this.suffix,
    this.contentPadding,
    this.textCapitalization = TextCapitalization.none,
    this.textAlign = TextAlign.start,
    this.helperText,
    this.errorText,
    this.prefixIconConstraints,
    this.suffixIconConstraints,
    this.fillColor,
    this.labelColor,
    this.borderRadius,
    this.textInputAction,
  }) : super(key: key);

  @override
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _hasText = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
    _hasText = widget.controller != null && widget.controller!.text.isNotEmpty;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    if (widget.controller != null) {
      widget.controller!.addListener(_handleTextChange);
    }
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    if (_isFocused) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _handleTextChange() {
    if (widget.controller != null) {
      final hasText = widget.controller!.text.isNotEmpty;
      if (hasText != _hasText) {
        setState(() {
          _hasText = hasText;
        });
      }
    }
  }

  @override
  void dispose() {
    // 僅在內部創建焦點節點時才需要銷毀
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_handleFocusChange);
    }
    
    if (widget.controller != null) {
      widget.controller!.removeListener(_handleTextChange);
    }
    
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    
    final labelText = widget.required
        ? '${widget.label} *'
        : widget.label;
        
    final labelStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: widget.labelColor ?? 
          (_isFocused 
              ? AppTheme.primaryColor
              : isDark 
                  ? Colors.white70 
                  : AppTheme.textSecondaryColor),
    );
    
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.borderRadius ?? AppTheme.radiusLG),
      borderSide: BorderSide(
        color: _isFocused 
            ? AppTheme.primaryColor
            : (widget.errorText != null 
                ? AppTheme.errorColor 
                : isDark 
                    ? const Color(0xFF4A453A) 
                    : const Color(0xFFEAE0D5)),
        width: _isFocused ? 1.5 : 1.0,
      ),
    );
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            labelText,
            style: labelStyle,
          ).animate(
            target: _isFocused ? 1.0 : 0.0,
          ).moveY(
            begin: 0,
            end: -4,
            curve: Curves.easeInOut,
            duration: 200.ms,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            validator: widget.validator,
            onChanged: widget.onChanged,
            maxLines: widget.maxLines,
            minLines: widget.minLines,
            maxLength: widget.maxLength,
            inputFormatters: widget.inputFormatters,
            enabled: widget.enabled,
            onTap: widget.onTap,
            readOnly: widget.readOnly,
            textCapitalization: widget.textCapitalization,
            textAlign: widget.textAlign,
            cursorColor: AppTheme.primaryColor,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white : AppTheme.textColor,
            ),
            decoration: InputDecoration(
              hintText: widget.placeholder,
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : AppTheme.textSecondaryColor.withOpacity(0.5),
                fontSize: 16,
              ),
              errorText: widget.errorText,
              helperText: widget.helperText,
              helperStyle: TextStyle(
                color: isDark ? Colors.white54 : AppTheme.textSecondaryColor.withOpacity(0.7),
                fontSize: 12,
              ),
              errorStyle: const TextStyle(
                color: AppTheme.errorColor,
                fontSize: 12,
              ),
              prefixIcon: widget.prefix,
              suffixIcon: widget.suffix,
              contentPadding: widget.contentPadding ?? 
                  const EdgeInsets.symmetric(
                    horizontal: 16, 
                    vertical: 16,
                  ),
              filled: true,
              fillColor: widget.fillColor ?? 
                  (isDark 
                      ? const Color(0xFF3B3632)
                      : Colors.white),
              border: inputBorder,
              enabledBorder: inputBorder,
              focusedBorder: inputBorder,
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius ?? AppTheme.radiusLG),
                borderSide: const BorderSide(
                  color: AppTheme.errorColor,
                  width: 1.0,
                ),
              ),
              prefixIconConstraints: widget.prefixIconConstraints,
              suffixIconConstraints: widget.suffixIconConstraints,
              counterText: '',
            ),
          ).animate(
            target: _isFocused ? 1.0 : 0.0,
          ).custom(
            duration: 300.ms,
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius ?? AppTheme.radiusLG),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.2 * value),
                      blurRadius: 8 * value,
                      spreadRadius: 0,
                      offset: Offset(0, 2 * value),
                    ),
                  ],
                ),
                child: child,
              );
            },
          ),
          if (widget.errorText != null)
            SizedBox(height: 4).animate().fadeIn(duration: 200.ms),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).moveY(begin: 10, end: 0, duration: 300.ms);
  }
} 