import 'package:flutter_test/flutter_test.dart';
import 'package:quicknote_pro/services/widget/home_screen_widget_service.dart';

void main() {
  group('HomeScreenWidgetService', () {
    late HomeScreenWidgetService widgetService;

    setUp(() {
      widgetService = HomeScreenWidgetService();
    });

    test('should be singleton', () {
      final instance1 = HomeScreenWidgetService();
      final instance2 = HomeScreenWidgetService();
      
      expect(identical(instance1, instance2), isTrue);
    });

    test('should initialize widgets without error', () async {
      expect(() => widgetService.initializeWidgets(), returnsNormally);
    });

    test('should update widget without error', () async {
      expect(() => widgetService.updateWidget(
        recentNoteTitle: 'Test Note',
        recentNoteContent: 'This is test content',
        totalNotesCount: 5,
      ), returnsNormally);
    });

    test('should setup quick actions without error', () async {
      expect(() => widgetService.setupQuickActions(), returnsNormally);
    });

    test('should handle widget interactions correctly', () async {
      final actions = ['create_note', 'voice_note', 'open_app', null, 'unknown'];
      
      for (final action in actions) {
        expect(() => HomeScreenWidgetService.handleWidgetInteraction(action), 
               returnsNormally);
      }
    });

    test('should get pending action without error', () async {
      final result = widgetService.getPendingAction();
      expect(result, completion(isNull)); // Should be null on web
    });

    test('should check platform support correctly', () {
      final isSupported = widgetService.isSupported();
      
      // On test platform (web), should return false
      expect(isSupported, isFalse);
    });

    test('should return widget info with correct structure', () {
      final info = widgetService.getWidgetInfo();
      
      expect(info, isA<Map<String, dynamic>>());
      expect(info.keys, containsAll(['isSupported', 'platform', 'features']));
      expect(info['isSupported'], isA<bool>());
      expect(info['platform'], isA<String>());
      expect(info['features'], isA<List>());
      expect(info['features'], isNotEmpty);
    });

    test('should handle widget update with null parameters', () async {
      expect(() => widgetService.updateWidget(), returnsNormally);
    });

    test('should handle widget update with empty strings', () async {
      expect(() => widgetService.updateWidget(
        recentNoteTitle: '',
        recentNoteContent: '',
        totalNotesCount: 0,
      ), returnsNormally);
    });

    test('should handle widget update with long content', () async {
      final longContent = 'This is a very long note content that should be handled properly by the widget service. ' * 10;
      
      expect(() => widgetService.updateWidget(
        recentNoteTitle: 'Long Note',
        recentNoteContent: longContent,
        totalNotesCount: 1,
      ), returnsNormally);
    });

    test('should return correct widget features', () {
      final info = widgetService.getWidgetInfo();
      final features = info['features'] as List;
      
      expect(features, contains('Quick note creation'));
      expect(features, contains('Recent note preview'));
      expect(features, contains('Voice note shortcut'));
      expect(features, contains('Notes count display'));
    });

    test('should handle background callback without error', () {
      final testUri = Uri.parse('test://app?action=create_note');
      
      expect(() => widgetService.handleWidgetInteraction('create_note'), 
             returnsNormally);
    });

    test('should validate widget action types', () async {
      final validActions = ['create_note', 'voice_note', 'open_app'];
      
      for (final action in validActions) {
        expect(() => HomeScreenWidgetService.handleWidgetInteraction(action), 
               returnsNormally);
      }
    });
  });
}