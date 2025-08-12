import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';

class FileAttachmentWidget extends StatefulWidget {
  final Function(String) onFileSelected;

  const FileAttachmentWidget({
    Key? key,
    required this.onFileSelected,
  }) : super(key: key);

  @override
  State<FileAttachmentWidget> createState() => _FileAttachmentWidgetState();
}

class _FileAttachmentWidgetState extends State<FileAttachmentWidget> {
  bool _isLoading = false;

  Future<void> _pickFile() async {
    // Request storage permission on Android
    if (!kIsWeb) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        _showPermissionDialog();
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        allowedExtensions: null,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          widget.onFileSelected(file.path!);
        } else {
          _showErrorSnackBar('Unable to access selected file');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick file: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    // Request storage permission on Android
    if (!kIsWeb) {
      final status = await Permission.photos.request();
      if (!status.isGranted) {
        _showPermissionDialog();
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          widget.onFileSelected(file.path!);
        } else {
          _showErrorSnackBar('Unable to access selected image');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDocument() async {
    // Request storage permission on Android
    if (!kIsWeb) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        _showPermissionDialog();
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'rtf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          widget.onFileSelected(file.path!);
        } else {
          _showErrorSnackBar('Unable to access selected document');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick document: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Storage Permission Required',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Text(
          'Please grant storage permission to access files.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
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
          Text(
            'Attach File',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 3.h),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildOptionButton(
                      icon: 'description',
                      label: 'Document',
                      onTap: _pickDocument,
                    ),
                    _buildOptionButton(
                      icon: 'image',
                      label: 'Image',
                      onTap: _pickImage,
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                _buildOptionButton(
                  icon: 'attach_file',
                  label: 'Any File',
                  onTap: _pickFile,
                  fullWidth: true,
                ),
              ],
            ),
          SizedBox(height: 2.h),
          Text(
            'Supported: PDF, DOC, TXT, Images, and more',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
    bool fullWidth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : 25.w,
        height: 15.h,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: icon,
              size: 8.w,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: 1.h),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}