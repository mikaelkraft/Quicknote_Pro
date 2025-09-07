import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

class HomeScreenWidgetService {
  static final HomeScreenWidgetService _instance = HomeScreenWidgetService._internal();
  factory HomeScreenWidgetService() => _instance;
  HomeScreenWidgetService._internal();

  /// Initialize home screen widgets
  Future<void> initializeWidgets() async {
    try {
      if (kIsWeb) {
        debugPrint('Home screen widgets not supported on web platform');
        return;
      }

      // Register the widget update callback
      HomeWidget.registerBackgroundCallback(_backgroundCallback);
      
      // Update widget with initial data
      await updateWidget();
      
      debugPrint('Home screen widgets initialized successfully');
    } catch (e) {
      debugPrint('Error initializing home screen widgets: $e');
    }
  }

  /// Update the home screen widget with latest note data
  Future<void> updateWidget({
    String? recentNoteTitle,
    String? recentNoteContent,
    int? totalNotesCount,
  }) async {
    try {
      if (kIsWeb) return;

      // Save data to be displayed in widget
      await HomeWidget.saveWidgetData('recent_note_title', recentNoteTitle ?? 'No recent notes');
      await HomeWidget.saveWidgetData('recent_note_content', recentNoteContent ?? 'Create your first note');
      await HomeWidget.saveWidgetData('total_notes_count', totalNotesCount ?? 0);
      await HomeWidget.saveWidgetData('last_update', DateTime.now().millisecondsSinceEpoch.toString());

      // Update the actual widget
      await HomeWidget.updateWidget(
        androidName: 'QuickNoteWidgetProvider',
        iOSName: 'QuickNoteWidget',
      );

      debugPrint('Home screen widget updated successfully');
    } catch (e) {
      debugPrint('Error updating home screen widget: $e');
    }
  }

  /// Configure quick actions for the widget
  Future<void> setupQuickActions() async {
    try {
      if (kIsWeb) return;

      // Set app-specific data for widget interactions
      await HomeWidget.saveWidgetData('action_create_note', 'create_note');
      await HomeWidget.saveWidgetData('action_open_app', 'open_app');
      await HomeWidget.saveWidgetData('action_voice_note', 'voice_note');

      debugPrint('Widget quick actions configured');
    } catch (e) {
      debugPrint('Error setting up quick actions: $e');
    }
  }

  /// Handle widget interactions
  static Future<void> handleWidgetInteraction(String? action) async {
    debugPrint('Widget interaction received: $action');
    
    switch (action) {
      case 'create_note':
        // Navigate to note creation
        await _triggerAppAction('create_note');
        break;
      case 'voice_note':
        // Start voice recording
        await _triggerAppAction('voice_note');
        break;
      case 'open_app':
        // Just open the app
        await _triggerAppAction('open_app');
        break;
      default:
        await _triggerAppAction('open_app');
    }
  }

  /// Trigger an action in the main app
  static Future<void> _triggerAppAction(String action) async {
    try {
      await HomeWidget.saveWidgetData('pending_action', action);
      debugPrint('Action triggered: $action');
    } catch (e) {
      debugPrint('Error triggering action: $e');
    }
  }

  /// Get pending action (called when app launches)
  Future<String?> getPendingAction() async {
    try {
      if (kIsWeb) return null;
      
      final action = await HomeWidget.getWidgetData('pending_action');
      if (action != null) {
        // Clear the pending action
        await HomeWidget.saveWidgetData('pending_action', null);
      }
      return action;
    } catch (e) {
      debugPrint('Error getting pending action: $e');
      return null;
    }
  }

  /// Check if home screen widgets are supported
  bool isSupported() {
    return !kIsWeb;
  }

  /// Get widget configuration for display in settings
  Map<String, dynamic> getWidgetInfo() {
    return {
      'isSupported': isSupported(),
      'platform': kIsWeb ? 'web' : (defaultTargetPlatform.name),
      'features': [
        'Quick note creation',
        'Recent note preview',
        'Voice note shortcut',
        'Notes count display',
      ],
    };
  }
}

/// Background callback for widget interactions
@pragma('vm:entry-point')
void _backgroundCallback(Uri? data) {
  debugPrint('Widget background callback triggered: $data');
  
  if (data == null) return;
  
  final action = data.queryParameters['action'];
  HomeScreenWidgetService.handleWidgetInteraction(action);
}