import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'demo/note_editor_demo.dart';
import 'controllers/note_controller.dart';
import 'services/note_persistence_service.dart';
import 'services/attachment_service.dart';
import 'repositories/notes_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services for the demo
  final repository = NotesRepository();
  final persistenceService = NotePersistenceService(repository);
  final attachmentService = AttachmentService();
  
  await repository.initialize();
  await persistenceService.initialize();
  await attachmentService.initialize();

  // Create note controller
  final noteController = NoteController(persistenceService, attachmentService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: noteController),
      ],
      child: const NoteEditorDemo(),
    ),
  );
}