import WidgetKit
import SwiftUI

struct QuickNoteWidget: Widget {
    let kind: String = "QuickNoteWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            QuickNoteWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("QuickNote Pro")
        .description("Quick access to create notes and view recent content")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), title: "Recent Note", content: "Your latest note content...", noteCount: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), title: "Sample Note", content: "This is a sample note for preview", noteCount: 5)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Get data from home widget plugin
        let userDefaults = UserDefaults(suiteName: "group.com.quicknote_pro.app")
        let title = userDefaults?.string(forKey: "recent_note_title") ?? "No recent notes"
        let content = userDefaults?.string(forKey: "recent_note_content") ?? "Create your first note"
        let noteCount = userDefaults?.integer(forKey: "total_notes_count") ?? 0

        let currentDate = Date()
        let entry = SimpleEntry(date: currentDate, title: title, content: content, noteCount: noteCount)
        entries.append(entry)

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let title: String
    let content: String
    let noteCount: Int
}

struct QuickNoteWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(.blue)
                Text("QuickNote Pro")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(entry.noteCount) notes")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(entry.content)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Action buttons for medium size
            if entry.date.timeIntervalSince1970 > 0 { // Always true, just for conditional view
                HStack {
                    Link(destination: URL(string: "quicknote://create_note")!) {
                        HStack {
                            Image(systemName: "plus")
                            Text("New")
                        }
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                    }
                    
                    Spacer()
                    
                    Link(destination: URL(string: "quicknote://voice_note")!) {
                        HStack {
                            Image(systemName: "mic")
                            Text("Voice")
                        }
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

@main
struct QuickNoteWidgetBundle: WidgetBundle {
    var body: some Widget {
        QuickNoteWidget()
    }
}