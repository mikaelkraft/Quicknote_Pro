package com.quicknote_pro.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class QuickNoteWidgetProvider : AppWidgetProvider() {
    
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        if (action != null) {
            when (action) {
                ACTION_CREATE_NOTE -> {
                    handleWidgetAction(context, "create_note")
                }
                ACTION_VOICE_NOTE -> {
                    handleWidgetAction(context, "voice_note")
                }
                ACTION_OPEN_APP -> {
                    handleWidgetAction(context, "open_app")
                }
                else -> super.onReceive(context, intent)
            }
        } else {
            super.onReceive(context, intent)
        }
    }

    private fun handleWidgetAction(context: Context, action: String) {
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        launchIntent?.let {
            it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            it.putExtra("widget_action", action)
            context.startActivity(it)
        }
    }

    companion object {
        const val ACTION_CREATE_NOTE = "com.quicknote_pro.app.CREATE_NOTE"
        const val ACTION_VOICE_NOTE = "com.quicknote_pro.app.VOICE_NOTE"
        const val ACTION_OPEN_APP = "com.quicknote_pro.app.OPEN_APP"

        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val widgetData = HomeWidgetPlugin.getData(context)
            
            val recentNoteTitle = widgetData?.getString("recent_note_title", "No recent notes") ?: "No recent notes"
            val recentNoteContent = widgetData?.getString("recent_note_content", "Create your first note") ?: "Create your first note"
            val totalNotesCount = widgetData?.getInt("total_notes_count", 0) ?: 0
            
            // Truncate content for widget display
            val displayContent = if (recentNoteContent.length > 50) {
                recentNoteContent.take(47) + "..."
            } else {
                recentNoteContent
            }

            val views = RemoteViews(context.packageName, R.layout.widget_quick_note)
            
            // Set text content
            views.setTextViewText(R.id.widget_title, recentNoteTitle)
            views.setTextViewText(R.id.widget_content, displayContent)
            views.setTextViewText(R.id.widget_notes_count, "$totalNotesCount notes")

            // Set click intents
            views.setOnClickPendingIntent(R.id.widget_create_note_btn, 
                getPendingIntent(context, ACTION_CREATE_NOTE))
            views.setOnClickPendingIntent(R.id.widget_voice_note_btn, 
                getPendingIntent(context, ACTION_VOICE_NOTE))
            views.setOnClickPendingIntent(R.id.widget_main_content, 
                getPendingIntent(context, ACTION_OPEN_APP))

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun getPendingIntent(context: Context, action: String): PendingIntent {
            val intent = Intent(context, QuickNoteWidgetProvider::class.java)
            intent.action = action
            return PendingIntent.getBroadcast(
                context, 
                action.hashCode(), 
                intent, 
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }
    }
}