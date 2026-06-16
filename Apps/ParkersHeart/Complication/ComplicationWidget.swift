import WidgetKit
import SwiftUI

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry { SimpleEntry(date: Date()) }
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) { completion(SimpleEntry(date: Date())) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        completion(Timeline(entries: [SimpleEntry(date: Date())], policy: .never))
    }
}

struct ComplicationView: View {
    var entry: SimpleEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Text("💛").font(.title2)
            }
        case .accessoryCorner:
            Text("💛").font(.title2)
                .widgetLabel("Parker's Heart")
        case .accessoryRectangular:
            HStack {
                Text("💛").font(.title3)
                Text("Parker's Heart").font(.headline).foregroundColor(.yellow)
                Spacer()
            }
        default:
            Text("💛 Parker's Heart")
        }
    }
}

@main
struct ParkersHeartComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "com.zevgt.parkersheart.complication", provider: Provider()) { entry in
            ComplicationView(entry: entry)
        }
        .configurationDisplayName("Parker's Heart")
        .description("Open Parker's Heart app")
        .supportedFamilies([.accessoryCircular, .accessoryCorner, .accessoryRectangular, .accessoryInline])
    }
}
