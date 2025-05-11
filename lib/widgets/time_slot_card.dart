import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../models/time_slot.dart';
import '../models/participant.dart';

class TimeSlotCard extends StatefulWidget {
  final TimeSlot timeSlot;
  final bool isSelected;
  final Function(TimeSlot) onTap;
  final bool showAvailability;
  final int? availableCount;
  final int? totalCount;
  final bool isTopPick;
  final VoidCallback? onDelete;
  final double? width;
  final double? height;

  const TimeSlotCard({
    Key? key,
    required this.timeSlot,
    required this.isSelected,
    required this.onTap,
    this.showAvailability = false,
    this.availableCount,
    this.totalCount,
    this.isTopPick = false,
    this.onDelete,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  State<TimeSlotCard> createState() => _TimeSlotCardState();
}

class _TimeSlotCardState extends State<TimeSlotCard> with SingleTickerProviderStateMixin {
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // 動態顏色
    final cardColor = widget.isSelected
        ? theme.colorScheme.primary.withOpacity(0.1)
        : isDark
            ? const Color(0xFF3B3632)
            : (theme.cardTheme.color ?? Colors.white);
    
    final borderColor = widget.isSelected
        ? theme.colorScheme.primary
        : isDark
            ? Colors.transparent
            : const Color(0xFFEAE0D5);
    
    // 文字顏色
    final textColor = widget.isSelected
        ? theme.colorScheme.primary
        : isDark
            ? Colors.white
            : AppTheme.textColor;
    
    // 次要文字顏色
    final secondaryTextColor = widget.isSelected
        ? theme.colorScheme.primary.withOpacity(0.8)
        : isDark
            ? Colors.white70
            : AppTheme.textSecondaryColor;
    
    // 日期格式化
    final date = widget.timeSlot.startTime;
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    final isTomorrow = date.year == now.year && date.month == now.month && date.day == now.day + 1;
    
    String dateText;
    if (isToday) {
      dateText = '今天';
    } else if (isTomorrow) {
      dateText = '明天';
    } else {
      // 獲取星期
      final dayNames = ['週一', '週二', '週三', '週四', '週五', '週六', '週日'];
      final dayName = dayNames[(date.weekday - 1) % 7];
      
      // 月份和日期
      dateText = '${date.month}月${date.day}日 $dayName';
    }
    
    // 時間格式化
    final startHour = date.hour;
    final startMinute = date.minute.toString().padLeft(2, '0');
    final startTime = '$startHour:$startMinute';
    
    final endTime = widget.timeSlot.endTime;
    final endHour = endTime.hour;
    final endMinute = endTime.minute.toString().padLeft(2, '0');
    final endTimeStr = '$endHour:$endMinute';
    
    // 計算可用性百分比
    double availabilityPercent = 0.0;
    if (widget.showAvailability && widget.availableCount != null && widget.totalCount != null && widget.totalCount! > 0) {
      availabilityPercent = widget.availableCount! / widget.totalCount!;
    }
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: InkWell(
        onTap: () {
          widget.onTap(widget.timeSlot);
        },
        onTapDown: (_) {
          setState(() => _isPressed = true);
          _animationController.forward();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _animationController.reverse();
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          _animationController.reverse();
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        splashColor: theme.colorScheme.primary.withOpacity(0.12),
        highlightColor: Colors.transparent,
        child: Container(
          width: widget.width,
          height: widget.height,
          margin: const EdgeInsets.only(bottom: AppTheme.spaceSM),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            border: Border.all(
              color: borderColor,
              width: widget.isSelected ? 1.5 : 1.0,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : isDark
                    ? null
                    : AppTheme.lightShadow,
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 日期和標記
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: (widget.isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.primary.withOpacity(0.1)),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                                ),
                                child: Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: widget.isSelected
                                      ? Colors.white
                                      : theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  dateText,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.isTopPick) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  '最佳選擇',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // 時間段
                    Container(
                      decoration: BoxDecoration(
                        color: widget.isSelected
                            ? theme.colorScheme.primary.withOpacity(0.1)
                            : isDark
                                ? Colors.black.withOpacity(0.2)
                                : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: secondaryTextColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '開始',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            startTime,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: widget.isSelected
                            ? theme.colorScheme.primary.withOpacity(0.1)
                            : isDark
                                ? Colors.black.withOpacity(0.2)
                                : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: secondaryTextColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '結束',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            endTimeStr,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    if (widget.showAvailability && widget.availableCount != null && widget.totalCount != null) ...[
                      const SizedBox(height: 16),
                      
                      // 參與者可用性指示器
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '參與者可用性',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: secondaryTextColor,
                                ),
                              ),
                              Text(
                                '${widget.availableCount}/${widget.totalCount}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Stack(
                            children: [
                              // 背景進度條
                              Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              // 前景進度條
                              Container(
                                height: 6,
                                width: (MediaQuery.of(context).size.width - 64) * availabilityPercent,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.colorScheme.primary,
                                      theme.colorScheme.secondary,
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // 刪除按鈕
              if (widget.onDelete != null)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onDelete,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: isDark
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0, duration: 300.ms);
  }
  
  Color getAvatarColor(String name, ThemeData theme) {
    final colors = [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      AppTheme.accentColor,
      AppTheme.successColor,
      AppTheme.warningColor,
    ];
    
    // 根據名字的 hash 值選擇顏色
    final index = name.hashCode % colors.length;
    return colors[index.abs()];
  }
} 