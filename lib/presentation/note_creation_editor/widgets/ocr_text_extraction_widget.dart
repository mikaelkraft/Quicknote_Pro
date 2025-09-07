import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../services/ocr/ocr_service.dart';
import '../../../widgets/custom_icon_widget.dart';

class OcrTextExtractionWidget extends StatefulWidget {
  final Function(String) onTextExtracted;
  final bool isPremiumUser;

  const OcrTextExtractionWidget({
    Key? key,
    required this.onTextExtracted,
    required this.isPremiumUser,
  }) : super(key: key);

  @override
  State<OcrTextExtractionWidget> createState() => _OcrTextExtractionWidgetState();
}

class _OcrTextExtractionWidgetState extends State<OcrTextExtractionWidget>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final OcrService _ocrService = OcrService();
  
  bool _isProcessing = false;
  String _extractedText = '';
  double _confidence = 0.0;
  late AnimationController _processingController;
  late Animation<double> _processingAnimation;

  @override
  void initState() {
    super.initState();
    _processingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _processingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _processingController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _processingController.dispose();
    super.dispose();
  }

  Future<void> _selectImageAndExtractText(ImageSource source) async {
    if (!widget.isPremiumUser) {
      _showPremiumDialog();
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await _extractTextFromImage(image.path);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to select image');
    }
  }

  Future<void> _extractTextFromImage(String imagePath) async {
    setState(() {
      _isProcessing = true;
      _extractedText = '';
      _confidence = 0.0;
    });

    _processingController.repeat();

    try {
      final result = await _ocrService.extractTextWithDetails(imagePath);
      
      setState(() {
        _extractedText = result['text'] as String;
        _confidence = result['confidence'] as double;
        _isProcessing = false;
      });

      _processingController.stop();
      _processingController.reset();

      if (_extractedText.isNotEmpty && !_extractedText.contains('Error')) {
        _showTextPreview();
      } else {
        _showErrorSnackBar('No text found in the image');
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _processingController.stop();
      _showErrorSnackBar('Failed to extract text from image');
    }
  }

  void _showTextPreview() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'text_fields',
              size: 6.w,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                'Extracted Text',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(maxHeight: 40.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_confidence > 0) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: _getConfidenceColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getConfidenceColor(), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName: 'analytics',
                        size: 4.w,
                        color: _getConfidenceColor(),
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'Confidence: ${(_confidence * 100).toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _getConfidenceColor(),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 2.h),
              ],
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _extractedText,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onTextExtracted(_extractedText);
            },
            child: const Text('Add to Note'),
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor() {
    if (_confidence >= 0.8) return Colors.green;
    if (_confidence >= 0.6) return Colors.orange;
    return Colors.red;
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
              iconName: 'text_fields',
              size: 12.w,
              color: AppTheme.getWarningColor(
                  Theme.of(context).brightness == Brightness.light),
            ),
            SizedBox(height: 2.h),
            Text(
              'OCR text extraction from images is a premium feature. Upgrade to extract text from photos and documents.',
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
              // Navigate to premium upgrade screen
            },
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'text_fields',
                size: 6.w,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'Extract Text from Image',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (!widget.isPremiumUser)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: AppTheme.getWarningColor(true).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.getWarningColor(true)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName: 'lock',
                        size: 3.w,
                        color: AppTheme.getWarningColor(true),
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        'PRO',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.getWarningColor(true),
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 3.h),
          if (_isProcessing) _buildProcessingIndicator(),
          if (!_isProcessing) _buildImageOptions(),
        ],
      ),
    );
  }

  Widget _buildProcessingIndicator() {
    return Container(
      height: 20.h,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _processingAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _processingAnimation.value * 2 * 3.14159,
                  child: CustomIconWidget(
                    iconName: 'auto_fix_high',
                    size: 12.w,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                );
              },
            ),
            SizedBox(height: 2.h),
            Text(
              'Extracting text from image...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            SizedBox(height: 1.h),
            LinearProgressIndicator(
              backgroundColor: Theme.of(context).dividerColor,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOptions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildOptionButton(
          icon: 'camera_alt',
          label: 'Camera',
          onTap: () => _selectImageAndExtractText(ImageSource.camera),
        ),
        _buildOptionButton(
          icon: 'photo_library',
          label: 'Gallery',
          onTap: () => _selectImageAndExtractText(ImageSource.gallery),
        ),
      ],
    );
  }

  Widget _buildOptionButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 25.w,
        height: 15.h,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isPremiumUser 
                ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                : Theme.of(context).dividerColor,
            width: widget.isPremiumUser ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: icon,
              size: 8.w,
              color: widget.isPremiumUser 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).disabledColor,
            ),
            SizedBox(height: 1.h),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: widget.isPremiumUser 
                        ? null
                        : Theme.of(context).disabledColor,
                  ),
            ),
            if (!widget.isPremiumUser) ...[
              SizedBox(height: 0.5.h),
              CustomIconWidget(
                iconName: 'lock',
                size: 3.w,
                color: Theme.of(context).disabledColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}