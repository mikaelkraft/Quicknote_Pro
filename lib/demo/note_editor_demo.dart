import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quicknote_pro/controllers/note_controller.dart';
import 'package:quicknote_pro/ui/note_editor_screen.dart';
import 'package:quicknote_pro/services/note_persistence_service.dart';
import 'package:quicknote_pro/services/attachment_service.dart';
import 'package:quicknote_pro/repositories/notes_repository.dart';

/// Demo app to showcase the new note editor with attachment functionality
class NoteEditorDemo extends StatelessWidget {
  const NoteEditorDemo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Note Editor Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const DemoHomeScreen(),
    );
  }
}

class DemoHomeScreen extends StatelessWidget {
  const DemoHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Note Editor Demo'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'New Note Editor Features',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              'Automatic Saving',
              'Notes auto-save 500ms after you stop typing',
              Icons.save,
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              'Camera & Gallery',
              'Take photos or select from gallery with proper permissions',
              Icons.camera_alt,
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              'File Attachments',
              'Attach any file type with thumbnails and size display',
              Icons.attach_file,
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              'Attachment Management',
              'View, preview, and delete attachments with confirmation',
              Icons.folder,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _openNoteEditor(context),
              icon: const Icon(Icons.edit),
              label: const Text('Try New Note Editor'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _openNoteEditorWithId(context),
              icon: const Icon(Icons.edit_note),
              label: const Text('Open Existing Note (Demo)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                textStyle: const TextStyle(fontSize: 18),
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(String title, String description, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Colors.blue),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openNoteEditor(BuildContext context) async {
    // Initialize services
    final repository = NotesRepository();
    final persistenceService = NotePersistenceService(repository);
    final attachmentService = AttachmentService();
    
    await repository.initialize();
    await persistenceService.initialize();
    await attachmentService.initialize();
    
    final noteController = NoteController(persistenceService, attachmentService);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: noteController,
          child: const NoteEditorScreen(),
        ),
      ),
    ).then((_) {
      // Dispose controller when returning from editor
      noteController.dispose();
    });
  }

  Future<void> _openNoteEditorWithId(BuildContext context) async {
    // Initialize services
    final repository = NotesRepository();
    final persistenceService = NotePersistenceService(repository);
    final attachmentService = AttachmentService();
    
    await repository.initialize();
    await persistenceService.initialize();
    await attachmentService.initialize();
    
    final noteController = NoteController(persistenceService, attachmentService);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: noteController,
          child: const NoteEditorScreen(noteId: 'demo_note_id'),
        ),
      ),
    ).then((_) {
      // Dispose controller when returning from editor
      noteController.dispose();
    });
  }
}