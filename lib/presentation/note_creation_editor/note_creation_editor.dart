import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/note_model.dart';
import '../../services/notes/notes_service.dart';
import './widgets/drawing_canvas_widget.dart';
import './widgets/formatting_toolbar_widget.dart';
import './widgets/image_insertion_widget.dart';
import './widgets/file_attachment_widget.dart';
import './widgets/save_status_indicator_widget.dart';
import './widgets/voice_input_widget.dart';
import './widgets/ocr_text_extraction_widget.dart';

class NoteCreationEditor extends StatefulWidget {
  final String? noteId; // If provided, edit existing note
  
  const NoteCreationEditor({Key? key, this.noteId}) : super(key: key);

  @override
  State<NoteCreationEditor> createState() => _NoteCreationEditorState();
}

class _NoteCreationEditorState extends State<NoteCreationEditor>
    with TickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _contentFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  bool _isKeyboardVisible = false;
  bool _showFormattingToolbar = false;
  bool _showDrawingCanvas = false;
  bool _showImageInsertion = false;
  bool _showFileAttachment = false;
  bool _showOcrExtraction = false;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  bool _isPremiumUser = false; // Mock premium status
  DateTime? _lastSaved;
  
  Note? _currentNote;
  NotesService? _notesService;

  @override
  void initState() {
    super.initState();
    _notesService = Provider.of<NotesService>(context, listen: false);
    _setupKeyboardListener();
    _setupAutoSave();
    _titleFocusNode.requestFocus();

    // Setup text change listeners
    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
    _contentFocusNode.addListener(_onContentFocusChanged);
    
    // Load existing note or create new one
    _initializeNote();
  }

  @override
  void dispose() {
    _notesService?.stopAutoSave();
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Initialize note - load existing or create new
  Future<void> _initializeNote() async {
    if (widget.noteId != null) {
      // Load existing note
      _currentNote = await _notesService!.getNoteById(widget.noteId!);
      if (_currentNote != null) {
        _titleController.text = _currentNote!.title;
        _contentController.text = _currentNote!.content;
        _notesService!.setCurrentNote(_currentNote);
      }
    } else {
      // Create new note
      _currentNote = await _notesService!.createNote();
      _notesService!.setCurrentNote(_currentNote);
    }
    
    if (_currentNote != null) {
      _notesService!.startAutoSave(_currentNote!);
    }
  }

  void _setupKeyboardListener() {
    // Listen for keyboard visibility changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mediaQuery = MediaQuery.of(context);
      final keyboardHeight = mediaQuery.viewInsets.bottom;

      setState(() {
        _isKeyboardVisible = keyboardHeight > 0;
        _showFormattingToolbar =
            _isKeyboardVisible && _contentFocusNode.hasFocus;
      });
    });
  }

  void _setupAutoSave() {
    // Auto-save every 30 seconds
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 30));
      if (mounted && _hasUnsavedChanges) {
        await _saveNote(showConfirmation: false);
      }
      return mounted;
    });
  }

  void _onTextChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  void _onContentFocusChanged() {
    setState(() {
      _showFormattingToolbar = _isKeyboardVisible && _contentFocusNode.hasFocus;
    });
  }

  Future<void> _saveNote({bool showConfirmation = true}) async {
    if (_currentNote == null || _notesService == null) return;
    
    setState(() => _isSaving = true);

    try {
      // Update note with current content
      final updatedNote = _currentNote!.copyWith(
        title: _titleController.text,
        content: _contentController.text,
      );

      await _notesService!.saveNote(updatedNote);
      _currentNote = updatedNote;

      setState(() {
        _isSaving = false;
        _hasUnsavedChanges = false;
        _lastSaved = DateTime.now();
      });

      if (showConfirmation) {
        HapticFeedback.lightImpact();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Note saved successfully'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isSaving = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save note: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (_hasUnsavedChanges) {
      return await _showUnsavedChangesDialog();
    }
    return true;
  }

  Future<bool> _showUnsavedChangesDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Unsaved Changes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            content: Text(
              'You have unsaved changes. Do you want to save before leaving?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
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
                  await _saveNote();
                  Navigator.of(context).pop(true);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _handleFormatAction(String action) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    String newText = text;
    int newCursorPosition = selection.baseOffset;

    switch (action) {
      case 'bold':
        if (selection.isValid && !selection.isCollapsed) {
          final selectedText = text.substring(selection.start, selection.end);
          newText = text.replaceRange(
              selection.start, selection.end, '**$selectedText**');
          newCursorPosition = selection.end + 4;
        } else {
          newText = text.substring(0, selection.baseOffset) +
              '****' +
              text.substring(selection.baseOffset);
          newCursorPosition = selection.baseOffset + 2;
        }
        break;
      case 'italic':
        if (selection.isValid && !selection.isCollapsed) {
          final selectedText = text.substring(selection.start, selection.end);
          newText = text.replaceRange(
              selection.start, selection.end, '*$selectedText*');
          newCursorPosition = selection.end + 2;
        } else {
          newText = text.substring(0, selection.baseOffset) +
              '**' +
              text.substring(selection.baseOffset);
          newCursorPosition = selection.baseOffset + 1;
        }
        break;
      case 'bullet_list':
        newText = text.substring(0, selection.baseOffset) +
            '\n• ' +
            text.substring(selection.baseOffset);
        newCursorPosition = selection.baseOffset + 3;
        break;
      case 'numbered_list':
        newText = text.substring(0, selection.baseOffset) +
            '\n1. ' +
            text.substring(selection.baseOffset);
        newCursorPosition = selection.baseOffset + 4;
        break;
      case 'heading':
        newText = text.substring(0, selection.baseOffset) +
            '\n# ' +
            text.substring(selection.baseOffset);
        newCursorPosition = selection.baseOffset + 3;
        break;
      case 'quote':
        newText = text.substring(0, selection.baseOffset) +
            '\n> ' +
            text.substring(selection.baseOffset);
        newCursorPosition = selection.baseOffset + 3;
        break;
      case 'code':
        if (selection.isValid && !selection.isCollapsed) {
          final selectedText = text.substring(selection.start, selection.end);
          newText = text.replaceRange(
              selection.start, selection.end, '`$selectedText`');
          newCursorPosition = selection.end + 2;
        } else {
          newText = text.substring(0, selection.baseOffset) +
              '``' +
              text.substring(selection.baseOffset);
          newCursorPosition = selection.baseOffset + 1;
        }
        break;
    }

    _contentController.text = newText;
    _contentController.selection =
        TextSelection.collapsed(offset: newCursorPosition);
    HapticFeedback.selectionClick();
  }

  void _handleVoiceTranscription(String transcription) {
    final currentText = _contentController.text;
    final cursorPosition = _contentController.selection.baseOffset;

    final newText = currentText.substring(0, cursorPosition) +
        (currentText.isNotEmpty && cursorPosition > 0 ? ' ' : '') +
        transcription +
        currentText.substring(cursorPosition);

    _contentController.text = newText;
    _contentController.selection = TextSelection.collapsed(
      offset: cursorPosition +
          transcription.length +
          (currentText.isNotEmpty && cursorPosition > 0 ? 1 : 0),
    );

    HapticFeedback.lightImpact();
  }

  void _handleImageInsertion(String imagePath) async {
    if (_notesService == null) return;
    
    setState(() => _showImageInsertion = false);

    try {
      await _notesService!.addImageToCurrentNote(imagePath);
      
      // Insert image reference in content
      final currentText = _contentController.text;
      final cursorPosition = _contentController.selection.baseOffset;
      final imageRef = '\n![Image](${imagePath})\n';

      final newText = currentText.substring(0, cursorPosition) +
          imageRef +
          currentText.substring(cursorPosition);

      _contentController.text = newText;
      _contentController.selection = TextSelection.collapsed(
        offset: cursorPosition + imageRef.length,
      );

      HapticFeedback.lightImpact();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image added to note')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add image: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
  void _handleFileAttachment(String filePath) async {
    if (_notesService == null) return;
    
    setState(() => _showFileAttachment = false);

    try {
      await _notesService!.addAttachmentToCurrentNote(filePath);
      
      // Insert file reference in content
      final currentText = _contentController.text;
      final cursorPosition = _contentController.selection.baseOffset;
      final fileName = filePath.split('/').last;
      final fileRef = '\n[📎 $fileName]($filePath)\n';

      final newText = currentText.substring(0, cursorPosition) +
          fileRef +
          currentText.substring(cursorPosition);

      _contentController.text = newText;
      _contentController.selection = TextSelection.collapsed(
        offset: cursorPosition + fileRef.length,
      );

      HapticFeedback.lightImpact();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File attached to note')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to attach file: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
  void _handleOcrTextExtraction(String extractedText) async {
    setState(() => _showOcrExtraction = false);

    try {
      // Insert extracted text at cursor position
      final currentText = _contentController.text;
      final cursorPosition = _contentController.selection.baseOffset;
      
      // Add a separator if there's existing content
      final separator = currentText.isNotEmpty && !currentText.endsWith('\n') ? '\n\n' : '';
      final textToInsert = '$separator--- Extracted Text ---\n$extractedText\n\n';

      final newText = currentText.substring(0, cursorPosition) +
          textToInsert +
          currentText.substring(cursorPosition);

      _contentController.text = newText;
      _contentController.selection = TextSelection.collapsed(
        offset: cursorPosition + textToInsert.length,
      );

      HapticFeedback.lightImpact();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Text extracted and added to note')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add extracted text: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            _buildMainContent(),
            if (_showFormattingToolbar) _buildFormattingToolbar(),
            if (!_showDrawingCanvas) _buildVoiceInput(),
            if (_showDrawingCanvas) _buildDrawingCanvas(),
            if (_showImageInsertion) _buildImageInsertion(),
            if (_showFileAttachment) _buildFileAttachment(),
            if (_showOcrExtraction) _buildOcrExtraction(),
          ],
        ),
        floatingActionButton: _buildFloatingActionButtons(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
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
        isSaving: _isSaving,
        hasUnsavedChanges: _hasUnsavedChanges,
        lastSaved: _lastSaved,
      ),
      actions: [
        IconButton(
          onPressed: () => _saveNote(),
          icon: CustomIconWidget(
            iconName: 'save',
            size: 6.w,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'export':
                _showExportOptions();
                break;
              case 'share':
                _shareNote();
                break;
              case 'delete':
                _showDeleteConfirmation();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'download',
                    size: 5.w,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  SizedBox(width: 3.w),
                  const Text('Export'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'share',
                    size: 5.w,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  SizedBox(width: 3.w),
                  const Text('Share'),
                ],
              ),
            ),
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
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // Title input
        Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: TextField(
            controller: _titleController,
            focusNode: _titleFocusNode,
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
        ),

        Divider(
          height: 1,
          thickness: 1,
          color: Theme.of(context).dividerColor,
          indent: 4.w,
          endIndent: 4.w,
        ),

        // Content input
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            child: TextField(
              controller: _contentController,
              focusNode: _contentFocusNode,
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
          ),
        ),
      ],
    );
  }

  Widget _buildFormattingToolbar() {
    return Positioned(
      bottom: MediaQuery.of(context).viewInsets.bottom,
      left: 0,
      right: 0,
      child: FormattingToolbarWidget(
        onFormatAction: _handleFormatAction,
        isVisible: _showFormattingToolbar,
      ),
    );
  }

  Widget _buildVoiceInput() {
    return VoiceInputWidget(
      onTranscriptionComplete: _handleVoiceTranscription,
      isPremiumUser: _isPremiumUser,
    );
  }

  Widget _buildDrawingCanvas() {
    return Positioned.fill(
      child: DrawingCanvasWidget(
        isPremiumUser: _isPremiumUser,
        onClose: () => setState(() => _showDrawingCanvas = false),
      ),
    );
  }

  Widget _buildImageInsertion() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: Container(
            margin: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(4.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Insert Image',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        onPressed: () =>
                            setState(() => _showImageInsertion = false),
                        icon: CustomIconWidget(
                          iconName: 'close',
                          size: 6.w,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                ImageInsertionWidget(
                  onImageSelected: _handleImageInsertion,
                ),
                SizedBox(height: 2.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildFileAttachment() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: Container(
            margin: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(4.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Attach File',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        onPressed: () =>
                            setState(() => _showFileAttachment = false),
                        icon: CustomIconWidget(
                          iconName: 'close',
                          size: 6.w,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                FileAttachmentWidget(
                  onFileSelected: _handleFileAttachment,
                ),
                SizedBox(height: 2.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOcrExtraction() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: Container(
            margin: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(4.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Extract Text from Image',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        onPressed: () =>
                            setState(() => _showOcrExtraction = false),
                        icon: CustomIconWidget(
                          iconName: 'close',
                          size: 6.w,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                OcrTextExtractionWidget(
                  onTextExtracted: _handleOcrTextExtraction,
                  isPremiumUser: _isPremiumUser,
                ),
                SizedBox(height: 2.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'drawing',
          onPressed: () => setState(() => _showDrawingCanvas = true),
          backgroundColor: AppTheme.getAccentColor(
              Theme.of(context).brightness == Brightness.light),
          child: CustomIconWidget(
            iconName: 'brush',
            size: 6.w,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 2.h),
        FloatingActionButton(
          heroTag: 'image',
          onPressed: () => setState(() => _showImageInsertion = true),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          child: CustomIconWidget(
            iconName: 'image',
            size: 6.w,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 2.h),
        FloatingActionButton(
          heroTag: 'ocr',
          onPressed: () => setState(() => _showOcrExtraction = true),
          backgroundColor: _isPremiumUser 
              ? const Color(0xFF4CAF50) 
              : Colors.grey[400],
          child: Stack(
            children: [
              Center(
                child: CustomIconWidget(
                  iconName: 'text_fields',
                  size: 6.w,
                  color: Colors.white,
                ),
              ),
              if (!_isPremiumUser)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 4.w,
                    height: 4.w,
                    decoration: BoxDecoration(
                      color: AppTheme.getWarningColor(true),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Center(
                      child: CustomIconWidget(
                        iconName: 'lock',
                        size: 2.w,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 2.h),
        FloatingActionButton(
          heroTag: 'file',
          onPressed: () => setState(() => _showFileAttachment = true),
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

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Export Note',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 3.h),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'text_snippet',
                size: 6.w,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Export as TXT'),
              onTap: () {
                Navigator.pop(context);
                _exportAsTxt();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'picture_as_pdf',
                size: 6.w,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Export as PDF'),
              onTap: () {
                Navigator.pop(context);
                _exportAsPdf();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _exportAsTxt() {
    // Implement TXT export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exported as TXT')),
    );
  }

  void _exportAsPdf() {
    // Implement PDF export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exported as PDF')),
    );
  }

  void _shareNote() {
    // Implement note sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note shared')),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Note',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Text(
          'Are you sure you want to delete this note? This action cannot be undone.',
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
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
