import 'package:flutter/material.dart';

/// 自定義下拉刷新控制器
class RefreshController {
  bool _isRefreshing = false;
  bool _isRefreshFailed = false;

  RefreshController({bool initialRefresh = false}) {
    _isRefreshing = initialRefresh;
  }

  bool get isRefreshing => _isRefreshing;
  bool get isRefreshFailed => _isRefreshFailed;

  void refreshCompleted() {
    _isRefreshing = false;
    _isRefreshFailed = false;
  }

  void refreshFailed() {
    _isRefreshing = false;
    _isRefreshFailed = true;
  }

  void dispose() {
    // 清理资源
  }
}

/// 下拉刷新組件
class PullToRefreshWidget extends StatefulWidget {
  final Widget child;
  final RefreshController controller;
  final Future<void> Function() onRefresh;
  final Color? backgroundColor;
  final Color? refreshIndicatorColor;

  const PullToRefreshWidget({
    Key? key,
    required this.child,
    required this.controller,
    required this.onRefresh,
    this.backgroundColor,
    this.refreshIndicatorColor,
  }) : super(key: key);

  @override
  State<PullToRefreshWidget> createState() => _PullToRefreshWidgetState();
}

class _PullToRefreshWidgetState extends State<PullToRefreshWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return RefreshIndicator(
      color: widget.refreshIndicatorColor ?? theme.colorScheme.primary,
      backgroundColor: widget.backgroundColor ?? theme.colorScheme.surface,
      strokeWidth: 2.0,
      onRefresh: widget.onRefresh,
      child: widget.child,
    );
  }
} 