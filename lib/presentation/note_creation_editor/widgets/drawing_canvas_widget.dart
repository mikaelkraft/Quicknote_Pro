import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/doodle_data.dart';
import '../../../services/notes/notes_service.dart';

class DrawingCanvasWidget extends StatefulWidget {
  final bool isPremiumUser;
  final Function() onClose;
  final Function(String doodlePath)? onDoodleSaved;
  final String? existingDoodlePath; // For editing existing doodles

  const DrawingCanvasWidget({
    Key? key,
    required this.isPremiumUser,
    required this.onClose,
    this.onDoodleSaved,
    this.existingDoodlePath,
  }) : super(key: key);

  @override
  State<DrawingCanvasWidget> createState() => _DrawingCanvasWidgetState();
}

class _DrawingCanvasWidgetState extends State<DrawingCanvasWidget> {
  final GlobalKey _canvasKey = GlobalKey();
  
  DoodleData? _doodleData;
  List<DoodleStroke> _currentStrokes = [];
  List<List<DoodleStroke>> _undoHistory = [];
  int _currentLayer = 0;
  
  Color _selectedColor = Colors.black;
  double _selectedWidth = 2.0;
  bool _isErasing = false;
  String _currentTool = 'pen';
  
  NotesService? _notesService;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;

  final List<Color> _basicColors = [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
  ];

  final List<Color> _premiumColors = [
    Colors.pink,
    Colors.teal,
    Colors.indigo,
    Colors.amber,
    Colors.brown,
    Colors.grey,
    Colors.cyan,
    Colors.lime,
  ];

  final List<String> _tools = ['pen', 'eraser'];
  final List<String> _premiumTools = ['highlighter', 'brush'];

  @override
  void initState() {
    super.initState();
    _notesService = Provider.of<NotesService>(context, listen: false);
    _initializeDoodle();
  }

  /// Initialize doodle data - load existing or create new
  Future<void> _initializeDoodle() async {
    if (widget.existingDoodlePath != null) {
      await _loadExistingDoodle();
    } else {
      _createNewDoodle();
    }
  }

  /// Load existing doodle data
  Future<void> _loadExistingDoodle() async {
    try {
      final jsonData = await _notesService!.loadDoodleData(widget.existingDoodlePath!);
      if (jsonData != null) {
        setState(() {
          _doodleData = DoodleData.fromJsonString(jsonData);
          _currentStrokes = _doodleData!.allStrokes;
        });
      } else {
        _createNewDoodle();
      }
    } catch (e) {
      _createNewDoodle();
      _showErrorSnackBar('Failed to load doodle: $e');
    }
  }

  /// Create new doodle with default settings
  void _createNewDoodle() {
    final canvasSize = Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height * 0.7);
    setState(() {
      _doodleData = DoodleData.createNew(canvasSize: canvasSize);
      _currentStrokes = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_doodleData == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: _doodleData!.backgroundColor,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _buildToolPalette(),
            Expanded(
              child: Container(
                key: _canvasKey,
                width: double.infinity,
                color: _doodleData!.backgroundColor,
                child: CustomPaint(
                  painter: DoodlePainter(_currentStrokes, _doodleData!),
                  child: GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: Container(),
                  ),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: _buildFloatingActionButtons(),
      ),
    );
  }

  /// Handle back button and unsaved changes
  Future<bool> _onWillPop() async {
    if (_hasUnsavedChanges) {
      return await _showUnsavedChangesDialog();
    }
    return true;
  }

  /// Show unsaved changes dialog
  Future<bool> _showUnsavedChangesDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Unsaved Changes'),
            content: const Text('You have unsaved changes. Do you want to save before leaving?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Discard'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _saveDoodle();
                  Navigator.of(context).pop(true);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Build app bar with save and tools
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _doodleData!.backgroundColor,
      elevation: 0,
      leading: IconButton(
        onPressed: () async {
          if (await _onWillPop()) {
            widget.onClose();
          }
        },
        icon: CustomIconWidget(
          iconName: 'close',
          size: 6.w,
          color: Colors.black,
        ),
      ),
      title: Text(
        widget.existingDoodlePath != null ? 'Edit Doodle' : 'New Doodle',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.black,
            ),
      ),
      actions: [
        if (_hasUnsavedChanges)
          Container(
            margin: EdgeInsets.only(right: 2.w),
            child: Center(
              child: Container(
                width: 2.w,
                height: 2.w,
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        IconButton(
          onPressed: _clearCanvas,
          icon: CustomIconWidget(
            iconName: 'clear',
            size: 6.w,
            color: Colors.black,
          ),
        ),
        IconButton(
          onPressed: _undoLastStroke,
          icon: CustomIconWidget(
            iconName: 'undo',
            size: 6.w,
            color: _undoHistory.isNotEmpty ? Colors.black : Colors.grey,
          ),
        ),
        IconButton(
          onPressed: _isSaving ? null : _saveDoodle,
          icon: _isSaving
              ? SizedBox(
                  width: 4.w,
                  height: 4.w,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : CustomIconWidget(
                  iconName: 'save',
                  size: 6.w,
                  color: Colors.blue,
                ),
        ),
      ],
    );
  }

  Widget _buildToolPalette() {
    return Container(
      height: widget.isPremiumUser ? 18.h : 15.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Tools row (if premium)
          if (widget.isPremiumUser) _buildToolsRow(),
          // Brush sizes
          _buildSizesRow(),
          // Colors
          _buildColorsRow(),
        ],
      ),
    );
  }

  /// Build tools row for premium users
  Widget _buildToolsRow() {
    return Container(
      height: 6.h,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Row(
        children: [
          Text(
            'Tool:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ..._tools.map((tool) => _buildToolOption(tool)),
                  ..._premiumTools.map((tool) => _buildToolOption(tool)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build brush sizes row
  Widget _buildSizesRow() {
    return Container(
      height: 7.h,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Row(
        children: [
          Text(
            'Size:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSizeOption(1.0),
                  _buildSizeOption(2.0),
                  _buildSizeOption(4.0),
                  if (widget.isPremiumUser) ...[
                    _buildSizeOption(6.0),
                    _buildSizeOption(8.0),
                    _buildSizeOption(12.0),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(width: 4.w),
          if (!widget.isPremiumUser) _buildEraserButton(),
        ],
      ),
    );
  }

  /// Build colors row
  Widget _buildColorsRow() {
    return Container(
      height: 7.h,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Row(
        children: [
          Text(
            'Color:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ..._basicColors.map((color) => _buildColorOption(color)),
                  if (widget.isPremiumUser) ...[
                    ..._premiumColors.map((color) => _buildColorOption(color)),
                  ] else ...[
                    _buildPremiumLockIndicator(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeOption(double size) {
    final isSelected = _selectedWidth == size && !_isErasing;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedWidth = size;
          _isErasing = false;
        });
      },
      child: Container(
        width: 10.w,
        height: 5.h,
        margin: EdgeInsets.only(right: 2.w),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[100] : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Center(
          child: Container(
            width: size * 2,
            height: size * 2,
            decoration: BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorOption(Color color) {
    final isSelected = _selectedColor == color && !_isErasing;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColor = color;
          _isErasing = false;
        });
      },
      child: Container(
        width: 8.w,
        height: 4.h,
        margin: EdgeInsets.only(right: 2.w),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[400]!,
            width: isSelected ? 3 : 1,
          ),
        ),
      ),
    );
  }

  Widget _buildEraserButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isErasing = !_isErasing;
        });
      },
      child: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: _isErasing ? Colors.red[100] : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _isErasing ? Colors.red : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: CustomIconWidget(
          iconName: 'auto_fix_high',
          size: 5.w,
          color: _isErasing ? Colors.red : Colors.black,
        ),
      ),
    );
  }

  Widget _buildPremiumLockIndicator() {
    return GestureDetector(
      onTap: _showPremiumDialog,
      child: Container(
        width: 8.w,
        height: 4.h,
        margin: EdgeInsets.only(right: 2.w),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[400]!, width: 1),
        ),
        child: Center(
          child: CustomIconWidget(
            iconName: 'lock',
            size: 3.w,
            color: Colors.grey[600]!,
          ),
        ),
      ),
    );
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Premium Feature',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: 'palette',
              size: 12.w,
              color: AppTheme.getWarningColor(true),
            ),
            SizedBox(height: 2.h),
            Text(
              'Unlock advanced drawing tools including multiple brush sizes, extended color palette, and premium brushes.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to premium upgrade
            },
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    final box = context.findRenderObject() as RenderBox;
    final point = box.globalToLocal(details.globalPosition);

    setState(() {
      _lines.add(
        DrawnLine(
          [point],
          _isErasing ? Colors.white : _selectedColor,
          _selectedWidth,
        ),
      );
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final box = context.findRenderObject() as RenderBox;
    final point = box.globalToLocal(details.globalPosition);

    setState(() {
      _lines.last.points.add(point);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    // Line is complete
  }

  void _clearCanvas() {
    setState(() {
      _lines.clear();
    });
  }

  void _undoLastStroke() {
    if (_lines.isNotEmpty) {
      setState(() {
        _lines.removeLast();
      });
    }
  }
}

class DrawnLine {
  final List<Offset> points;
  final Color color;
  final double width;

  DrawnLine(this.points, this.color, this.width);
}

class DrawingPainter extends CustomPainter {
  final List<DrawnLine> lines;

  DrawingPainter(this.lines);

  @override
  void paint(Canvas canvas, Size size) {
    for (final line in lines) {
      final paint = Paint()
        ..color = line.color
        ..strokeCap = StrokeCap.round
        ..strokeWidth = line.width;

      for (int i = 0; i < line.points.length - 1; i++) {
        canvas.drawLine(line.points[i], line.points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
