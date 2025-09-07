import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../models/doodle_data.dart';

/// Service for generating thumbnails from doodle data
class DoodleThumbnailService {
  static const double defaultThumbnailWidth = 150;
  static const double defaultThumbnailHeight = 150;

  /// Generate a PNG thumbnail from doodle data
  /// Returns the thumbnail as bytes for storage
  static Future<Uint8List?> generateThumbnail(
    DoodleData doodleData, {
    double width = defaultThumbnailWidth,
    double height = defaultThumbnailHeight,
  }) async {
    try {
      // Create a picture recorder to capture the drawing
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      // Calculate scale to fit doodle in thumbnail
      final scaleX = width / doodleData.canvasSize.width;
      final scaleY = height / doodleData.canvasSize.height;
      final scale = scaleX < scaleY ? scaleX : scaleY;
      
      // Apply scaling
      canvas.scale(scale);
      
      // Draw background
      final backgroundPaint = Paint()..color = doodleData.backgroundColor;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, doodleData.canvasSize.width, doodleData.canvasSize.height),
        backgroundPaint,
      );
      
      // Draw all visible strokes
      for (final stroke in doodleData.allStrokes) {
        if (stroke.points.length < 2) continue;
        
        final paint = Paint()
          ..color = stroke.color
          ..strokeCap = stroke.strokeCap
          ..strokeWidth = stroke.width
          ..style = PaintingStyle.stroke;
        
        // Apply tool-specific effects
        switch (stroke.toolType) {
          case 'highlighter':
            paint.blendMode = BlendMode.multiply;
            paint.color = stroke.color.withValues(alpha: 0.5);
            break;
          case 'brush':
            paint.strokeCap = StrokeCap.round;
            break;
          default:
            break;
        }

        // Draw stroke as path
        final path = Path();
        path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
        
        for (int i = 1; i < stroke.points.length; i++) {
          final point = stroke.points[i];
          path.lineTo(point.dx, point.dy);
        }
        
        canvas.drawPath(path, paint);
      }
      
      // End recording and create image
      final picture = recorder.endRecording();
      final img = await picture.toImage(width.toInt(), height.toInt());
      
      // Convert to PNG bytes
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      
      // Clean up
      picture.dispose();
      img.dispose();
      
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Error generating thumbnail: $e');
      return null;
    }
  }

  /// Generate a thumbnail as a Flutter Image widget for display
  static Future<Widget?> generateThumbnailWidget(
    DoodleData doodleData, {
    double width = defaultThumbnailWidth,
    double height = defaultThumbnailHeight,
  }) async {
    final bytes = await generateThumbnail(doodleData, width: width, height: height);
    
    if (bytes != null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    
    return null;
  }

  /// Generate a placeholder thumbnail for empty doodles
  static Widget generatePlaceholderThumbnail({
    double width = defaultThumbnailWidth,
    double height = defaultThumbnailHeight,
    Color backgroundColor = Colors.white,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          Icons.brush,
          size: width * 0.3,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  /// Check if a doodle needs a thumbnail (has content)
  static bool needsThumbnail(DoodleData doodleData) {
    return !doodleData.isEmpty && doodleData.allStrokes.isNotEmpty;
  }

  /// Get optimal thumbnail size maintaining aspect ratio
  static Size getOptimalThumbnailSize(
    Size originalSize, {
    double maxWidth = defaultThumbnailWidth,
    double maxHeight = defaultThumbnailHeight,
  }) {
    final aspectRatio = originalSize.width / originalSize.height;
    
    double width = maxWidth;
    double height = maxWidth / aspectRatio;
    
    if (height > maxHeight) {
      height = maxHeight;
      width = maxHeight * aspectRatio;
    }
    
    return Size(width, height);
  }
}