import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/doodle_data.dart';
import '../../services/notes/notes_service.dart';
import '../../services/doodle_thumbnail_service.dart';
import '../note_creation_editor/widgets/drawing_canvas_widget.dart';

/// Widget to display doodles with thumbnails and editing capability
class DoodleDisplayWidget extends StatefulWidget {
  final List<String> doodlePaths;
  final bool isPreview; // If true, show small thumbnails; if false, show larger view
  final bool allowEditing;
  final Function(String doodlePath)? onDoodleUpdated;
  final bool isPremiumUser;

  const DoodleDisplayWidget({
    Key? key,
    required this.doodlePaths,
    this.isPreview = true,
    this.allowEditing = true,
    this.onDoodleUpdated,
    this.isPremiumUser = false,
  }) : super(key: key);

  @override
  State<DoodleDisplayWidget> createState() => _DoodleDisplayWidgetState();
}

class _DoodleDisplayWidgetState extends State<DoodleDisplayWidget> {
  final Map<String, DoodleData?> _loadedDoodles = {};
  final Map<String, Widget?> _thumbnailCache = {};
  NotesService? _notesService;

  @override
  void initState() {
    super.initState();
    _notesService = Provider.of<NotesService>(context, listen: false);
    _loadDoodles();
  }

  @override
  void didUpdateWidget(DoodleDisplayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.doodlePaths != widget.doodlePaths) {
      _loadedDoodles.clear();
      _thumbnailCache.clear();
      _loadDoodles();
    }
  }

  Future<void> _loadDoodles() async {
    for (final path in widget.doodlePaths) {
      if (!_loadedDoodles.containsKey(path)) {
        _loadDoodle(path);
      }
    }
  }

  Future<void> _loadDoodle(String doodlePath) async {
    try {
      final jsonData = await _notesService!.loadDoodleData(doodlePath);
      if (jsonData != null && mounted) {
        final doodleData = DoodleData.fromJsonString(jsonData);
        setState(() {
          _loadedDoodles[doodlePath] = doodleData;
        });
        
        // Generate thumbnail for preview mode
        if (widget.isPreview) {
          _generateThumbnail(doodlePath, doodleData);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadedDoodles[doodlePath] = null;
        });
      }
    }
  }

  Future<void> _generateThumbnail(String doodlePath, DoodleData doodleData) async {
    if (DoodleThumbnailService.needsThumbnail(doodleData)) {
      final thumbnail = await DoodleThumbnailService.generateThumbnailWidget(
        doodleData,
        width: widget.isPreview ? 15.w : 30.w,
        height: widget.isPreview ? 10.h : 20.h,
      );
      
      if (mounted) {
        setState(() {
          _thumbnailCache[doodlePath] = thumbnail;
        });
      }
    } else {
      setState(() {
        _thumbnailCache[doodlePath] = DoodleThumbnailService.generatePlaceholderThumbnail(
          width: widget.isPreview ? 15.w : 30.w,
          height: widget.isPreview ? 10.h : 20.h,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.doodlePaths.isEmpty) {
      return const SizedBox.shrink();
    }

    return widget.isPreview ? _buildPreviewGrid() : _buildDetailedView();
  }

  Widget _buildPreviewGrid() {
    return Container(
      height: 12.h,
      margin: EdgeInsets.symmetric(vertical: 1.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: widget.doodlePaths.asMap().entries.map((entry) {
            final index = entry.key;
            final path = entry.value;
            return _buildThumbnailCard(path, index);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDetailedView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Doodles (${widget.doodlePaths.length})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: 2.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 2.w,
            mainAxisSpacing: 2.h,
            childAspectRatio: 1.5,
          ),
          itemCount: widget.doodlePaths.length,
          itemBuilder: (context, index) {
            return _buildDoodleCard(widget.doodlePaths[index], index);
          },
        ),
      ],
    );
  }

  Widget _buildThumbnailCard(String doodlePath, int index) {
    final thumbnail = _thumbnailCache[doodlePath];
    final doodle = _loadedDoodles[doodlePath];
    
    return GestureDetector(
      onTap: () => _openDoodleEditor(doodlePath),
      child: Container(
        width: 15.w,
        height: 10.h,
        margin: EdgeInsets.only(right: 2.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: thumbnail ?? _buildLoadingThumbnail(),
            ),
            if (widget.allowEditing)
              Positioned(
                top: 1.w,
                right: 1.w,
                child: Container(
                  width: 6.w,
                  height: 6.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: CustomIconWidget(
                    iconName: 'edit',
                    size: 3.w,
                    color: Colors.blue,
                  ),
                ),
              ),
            if (doodle != null && !doodle.isEmpty)
              Positioned(
                bottom: 1.w,
                left: 1.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 1.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${doodle.strokeCount}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoodleCard(String doodlePath, int index) {
    final thumbnail = _thumbnailCache[doodlePath];
    final doodle = _loadedDoodles[doodlePath];
    
    return GestureDetector(
      onTap: () => _openDoodleEditor(doodlePath),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          color: Theme.of(context).cardColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  color: Colors.grey[100],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: thumbnail ?? _buildLoadingThumbnail(),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: EdgeInsets.all(2.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Doodle ${index + 1}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (doodle != null)
                      Text(
                        doodle.isEmpty ? 'Empty' : '${doodle.strokeCount} strokes',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingThumbnail() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: SizedBox(
          width: 4.w,
          height: 4.w,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  void _openDoodleEditor(String doodlePath) {
    if (!widget.allowEditing) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DrawingCanvasWidget(
          isPremiumUser: widget.isPremiumUser,
          existingDoodlePath: doodlePath,
          onClose: () => Navigator.of(context).pop(),
          onDoodleSaved: (savedPath) {
            Navigator.of(context).pop();
            widget.onDoodleUpdated?.call(savedPath);
            // Refresh the doodle
            _loadedDoodles.remove(doodlePath);
            _thumbnailCache.remove(doodlePath);
            _loadDoodle(doodlePath);
          },
        ),
        fullscreenDialog: true,
      ),
    );
  }
}