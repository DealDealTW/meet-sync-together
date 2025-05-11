import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../models/event.dart';
import '../models/time_slot.dart';
import '../models/location_option.dart';

/// 事件圖片生成器，用於創建可分享的事件卡片圖像
class EventImageGenerator {
  static Future<Uint8List> generateEventImage({
    required Event event,
    required ThemeData themeData,
  }) async {
    // 獲取最佳時間和地點
    final bestTimeSlots = event.getBestTimeSlots();
    final bestLocations = event.getSortedLocationVotesWithOptions();
    
    final hasTimeSlots = bestTimeSlots.isNotEmpty;
    final hasLocations = bestLocations.isNotEmpty;
    
    final topTimeSlot = hasTimeSlots ? bestTimeSlots.first : null;
    final topLocation = hasLocations && bestLocations.isNotEmpty ? bestLocations.first.key : null;

    // 創建一個用於渲染的GlobalKey
    final GlobalKey repaintBoundaryKey = GlobalKey();
    
    // 構建要渲染的UI
    final Widget cardUI = Material(
      color: Colors.transparent,
      child: RepaintBoundary(
        key: repaintBoundaryKey,
        child: Container(
          width: 1080, // 用於生成高質量圖片的尺寸
          height: 1920,
          color: themeData.colorScheme.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 頂部漸變區域
              Container(
                height: 400,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      themeData.colorScheme.primary,
                      themeData.colorScheme.primary.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // 裝飾性網格線
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _GridPainter(
                          lineColor: Colors.white.withOpacity(0.1),
                          lineWidth: 1.5,
                          gridSize: 40,
                        ),
                      ),
                    ),
                    // 事件標題和創建者
                    Positioned(
                      left: 40,
                      right: 40,
                      bottom: 40,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Created by ${event.creator ?? 'Unknown'}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // 內容區域
              Expanded(
                child: Container(
                  color: themeData.colorScheme.surface,
                  padding: EdgeInsets.all(40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 描述
                      if (event.description != null && event.description!.isNotEmpty) ...[
                        Text(
                          'Description',
                          style: TextStyle(
                            color: themeData.colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        Container(
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: themeData.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: themeData.colorScheme.outline.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            event.description!,
                            style: TextStyle(
                              color: themeData.colorScheme.onSurface,
                              fontSize: 24,
                              height: 1.4,
                            ),
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(height: 32),
                      ],
                      
                      // 時間
                      if (topTimeSlot != null) ...[
                        Text(
                          'Time',
                          style: TextStyle(
                            color: themeData.colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        Container(
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: themeData.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: themeData.colorScheme.primary,
                                child: Icon(
                                  Icons.access_time_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatDate(topTimeSlot.startTime),
                                      style: TextStyle(
                                        color: themeData.colorScheme.onSurface,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      '${_formatTime(topTimeSlot.startTime)} - ${_formatTime(topTimeSlot.endTime)}',
                                      style: TextStyle(
                                        color: themeData.colorScheme.primary,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 32),
                      ],
                      
                      // 地點
                      if (topLocation != null) ...[
                        Text(
                          'Location',
                          style: TextStyle(
                            color: themeData.colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        Container(
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: themeData.colorScheme.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: themeData.colorScheme.secondary,
                                child: Icon(
                                  Icons.place_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              SizedBox(width: 24),
                              Expanded(
                                child: Text(
                                  topLocation.name,
                                  style: TextStyle(
                                    color: themeData.colorScheme.onSurface,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 32),
                      ],
                      
                      Spacer(),
                      
                      // 底部邀請信息
                      Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: themeData.colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Join this event!',
                                    style: TextStyle(
                                      color: themeData.colorScheme.onSurfaceVariant,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Use code: ${event.shareCode}',
                                    style: TextStyle(
                                      color: themeData.colorScheme.onSurfaceVariant.withOpacity(0.7),
                                      fontSize: 24,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: themeData.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              padding: EdgeInsets.all(16),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    
    // 創建一個新的OverlayEntry來渲染我們的UI
    OverlayEntry entry = OverlayEntry(builder: (context) => cardUI);
    
    // 使用Builder來獲得context，而不是使用window.focusManager
    final WidgetsBinding binding = WidgetsFlutterBinding.ensureInitialized();
    final BuildContext context = binding.renderViewElement!;
    final NavigatorState navigator = Navigator.of(context);
    navigator.overlay!.insert(entry);
    
    // 等待下一幀渲染完成
    await Future.delayed(Duration(milliseconds: 100));
    
    // 捕獲渲染的UI
    RenderRepaintBoundary boundary = repaintBoundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    // 移除臨時OverlayEntry
    entry.remove();
    
    // 返回圖像數據
    return byteData!.buffer.asUint8List();
  }
  
  static String _formatDate(DateTime date) {
    return DateFormat('EEEE, MMMM d, y').format(date);
  }
  
  static String _formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }
}

/// 網格繪製器，用於繪製背景網格
class _GridPainter extends CustomPainter {
  final Color lineColor;
  final double lineWidth;
  final double gridSize;
  
  _GridPainter({
    required this.lineColor,
    required this.lineWidth,
    required this.gridSize,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke;
    
    // 繪製水平線
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    
    // 繪製垂直線
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 