import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'dart:io';

import '../../core/app_export.dart';
import '../../models/note.dart';
import '../../models/attachment.dart';
import '../../controllers/note_controller.dart';
import '../../services/media_picker.dart';
import '../presentation/note_creation_editor/widgets/save_status_indicator_widget.dart';

class NoteEditorScreen extends StatefulWidget {
  final String? noteId;
  
  const NoteEditorScreen({Key? key, this.noteId}) : super(key: key);

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late NoteController _noteController;
  final MediaPicker _mediaPicker = MediaPicker();
  
  @override
  void initState() {
    super.initState();
    _noteController = Provider.of<NoteController>(context, listen: false);
    
    // Initialize note
    if (widget.noteId != null) {
      _noteController.watchNote(widget.noteId!);
    } else {
      _noteController.createNew();
    }
  }

  @override
  void dispose() {
    // Ensure final save on dispose
    _noteController.flushPendingSave();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    await _noteController.flushPendingSave();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NoteController>(
      builder: (context, controller, child) {
        return WillPopScope(
          onWillPop: _onWillPop,
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: _buildAppBar(controller),
            body: Column(
              children: [
                _buildTitleField(controller),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Theme.of(context).dividerColor,
                  indent: 4.w,
                  endIndent: 4.w,
                ),
                Expanded(
                  child: _buildContentField(controller),
                ),
                if (controller.attachments.isNotEmpty)
                  _buildAttachmentsSection(controller),
              ],
            ),
            floatingActionButton: _buildFloatingActionButtons(),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(NoteController controller) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      leading: IconButton(
        onPressed: () async {
          if (await _onWillPop()) {
            Navigator.pop(context);
          }
        },
        icon: CustomIconWidget(
          iconName: 'arrow_back',
          size: 6.w,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      title: SaveStatusIndicatorWidget(
        isSaving: controller.isSaving,
        hasUnsavedChanges: false,
        lastSaved: controller.currentNote?.updatedAt,
      ),
      actions: [
        IconButton(
          onPressed: () => controller.saveNote(),
          icon: CustomIconWidget(
            iconName: 'save',
            size: 6.w,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'delete':
                _showDeleteConfirmation(controller);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'delete',
                    size: 5.w,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    'Delete',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTitleField(NoteController controller) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: TextField(
        controller: controller.titleController,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
        decoration: InputDecoration(
          hintText: 'Note title...',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        textCapitalization: TextCapitalization.sentences,
        maxLines: 2,
      ),
    );
  }

  Widget _buildContentField(NoteController controller) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: TextField(
        controller: controller.contentController,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: 'Start writing your note...',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        textCapitalization: TextCapitalization.sentences,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
      ),
    );
  }

  Widget _buildAttachmentsSection(NoteController controller) {
    return Container(
      height: 20.h,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attachments (${controller.attachments.length})',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: 2.h),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: controller.attachments.length,
              separatorBuilder: (context, index) => SizedBox(width: 3.w),
              itemBuilder: (context, index) {
                final attachment = controller.attachments[index];
                return _buildAttachmentTile(controller, attachment);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentTile(NoteController controller, Attachment attachment) {
    return Container(
      width: 30.w,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              child: attachment.isImage
                  ? _buildImageThumbnail(attachment)
                  : _buildFileThumbnail(attachment),
            ),
          ),
          Container(
            padding: EdgeInsets.all(2.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.name,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (attachment.sizeBytes != null) ...[
                  SizedBox(height: 1.h),
                  Text(
                    attachment.fileSizeFormatted,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                  ),
                ],
                SizedBox(height: 1.h),
                IconButton(
                  onPressed: () => _removeAttachment(controller, attachment),
                  icon: CustomIconWidget(
                    iconName: 'delete',
                    size: 4.w,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  style: IconButton.styleFrom(
                    minimumSize: Size(8.w, 4.h),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageThumbnail(Attachment attachment) {
    return FutureBuilder<String?>(
      future: _noteController.getAttachmentPath(attachment),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return Image.file(
            File(snapshot.data!),
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return _buildErrorThumbnail();
            },
          );
        }
        return _buildLoadingThumbnail();
      },
    );
  }

  Widget _buildFileThumbnail(Attachment attachment) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'attach_file',
            size: 8.w,
            color: Theme.of(context).colorScheme.secondary,
          ),
          SizedBox(height: 1.h),
          Text(
            attachment.fileExtension?.toUpperCase() ?? 'FILE',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.secondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingThumbnail() {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorThumbnail() {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.error.withOpacity(0.1),
      child: Center(
        child: CustomIconWidget(
          iconName: 'error',
          size: 6.w,
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'camera',
          onPressed: () => _pickImageFromCamera(),
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: CustomIconWidget(
            iconName: 'camera_alt',
            size: 6.w,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 2.h),
        FloatingActionButton(
          heroTag: 'gallery',
          onPressed: () => _pickImageFromGallery(),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          child: CustomIconWidget(
            iconName: 'photo',
            size: 6.w,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 2.h),
        FloatingActionButton(
          heroTag: 'file',
          onPressed: () => _pickFile(),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          child: CustomIconWidget(
            iconName: 'attach_file',
            size: 6.w,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final file = await _mediaPicker.pickImageFromCamera();
      if (file != null) {
        await _noteController.addAttachment(file, typeHint: AttachmentType.image);
        _showSuccessMessage('Image captured and added to note');
      }
    } catch (e) {
      _showErrorMessage('Failed to capture image: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final file = await _mediaPicker.pickImageFromGallery();
      if (file != null) {
        await _noteController.addAttachment(file, typeHint: AttachmentType.image);
        _showSuccessMessage('Image added to note');
      }
    } catch (e) {
      _showErrorMessage('Failed to pick image: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      final file = await _mediaPicker.pickAnyFile();
      if (file != null) {
        await _noteController.addAttachment(file, typeHint: AttachmentType.file);
        _showSuccessMessage('File attached to note');
      }
    } catch (e) {
      _showErrorMessage('Failed to attach file: $e');
    }
  }

  Future<void> _removeAttachment(NoteController controller, Attachment attachment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Attachment'),
        content: Text('Are you sure you want to remove "${attachment.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await controller.removeAttachment(attachment.id);
        _showSuccessMessage('Attachment removed');
      } catch (e) {
        _showErrorMessage('Failed to remove attachment: $e');
      }
    }
  }

  void _showDeleteConfirmation(NoteController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Note'),
        content: Text('Are you sure you want to delete this note? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await controller.deleteCurrentNote();
                Navigator.pop(context);
                _showSuccessMessage('Note deleted');
              } catch (e) {
                _showErrorMessage('Failed to delete note: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}