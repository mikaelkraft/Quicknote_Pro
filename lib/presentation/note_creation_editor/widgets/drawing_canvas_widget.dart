import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

class DrawingCanvasWidget extends StatefulWidget {
  final Function() onClose;

  const DrawingCanvasWidget({
    Key? key,
    required this.onClose,
  }) : super(key: key);

  @override
  State<DrawingCanvasWidget> createState() => _DrawingCanvasWidgetState();
}

class _DrawingCanvasWidgetState extends State<DrawingCanvasWidget> {
  List<DrawnLine> _lines = [];
  Color _selectedColor = Colors.black;
  double _selectedWidth = 2.0;
  bool _isErasing = false;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: widget.onClose,
          icon: CustomIconWidget(
            iconName: 'close',
            size: 6.w,
            color: Colors.black,
          ),
        ),
        title: Text(
          'Drawing',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.black,
              ),
        ),
        actions: [
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
              color: Colors.black,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildToolPalette(),
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.white,
              child: CustomPaint(
                painter: DrawingPainter(_lines),
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
    );
  }

  Widget _buildToolPalette() {
    return Container(
      height: 15.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Brush sizes
          Container(
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
                        ...Consumer<EntitlementService>(
                          builder: (context, entitlementService, child) {
                            if (entitlementService.hasFeature(PremiumFeature.advancedDrawingTools)) {
                              return [
                                _buildSizeOption(6.0),
                                _buildSizeOption(8.0),
                                _buildSizeOption(12.0),
                              ];
                            } else {
                              return [_buildPremiumSizeLockIndicator()];
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 4.w),
                _buildEraserButton(),
              ],
            ),
          ),
          // Colors
          Container(
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
                        ..._basicColors
                            .map((color) => _buildColorOption(color)),
                        ...Consumer<EntitlementService>(
                          builder: (context, entitlementService, child) {
                            if (entitlementService.hasFeature(PremiumFeature.advancedDrawingTools)) {
                              return _premiumColors
                                  .map((color) => _buildColorOption(color))
                                  .toList();
                            } else {
                              return [_buildPremiumColorLockIndicator()];
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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

  Widget _buildPremiumColorLockIndicator() {
    return GestureDetector(
      onTap: () => _showPremiumDialog(PremiumFeature.advancedDrawingTools),
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
            iconName: 'workspace_premium',
            size: 3.w,
            color: Colors.amber,
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumSizeLockIndicator() {
    return GestureDetector(
      onTap: () => _showPremiumDialog(PremiumFeature.advancedDrawingTools),
      child: Container(
        width: 10.w,
        height: 5.h,
        margin: EdgeInsets.only(right: 2.w),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: Center(
          child: CustomIconWidget(
            iconName: 'workspace_premium',
            size: 4.w,
            color: Colors.amber,
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumLockIndicator() {
    return _buildPremiumColorLockIndicator();
  }

  void _showPremiumDialog(PremiumFeature feature) {
    final entitlementService = context.read<EntitlementService>();
    final featureName = entitlementService.getFeatureName(feature);
    final featureDescription = entitlementService.getFeatureDescription(feature);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.amber),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                featureName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              featureDescription,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            Text(
              'Premium drawing tools include:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            ...['Multiple brush sizes', 'Extended color palette', 'Advanced stroke effects', 'Drawing layers support']
                .map((benefit) => Padding(
                  padding: EdgeInsets.only(bottom: 0.5.h),
                  child: Row(
                    children: [
                      Icon(Icons.check, color: Colors.green, size: 16.sp),
                      SizedBox(width: 2.w),
                      Expanded(child: Text(benefit, style: TextStyle(fontSize: 11.sp))),
                    ],
                  ),
                )),
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
              Navigator.pushNamed(context, AppRoutes.premiumUpgrade);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text('Upgrade Now', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
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
