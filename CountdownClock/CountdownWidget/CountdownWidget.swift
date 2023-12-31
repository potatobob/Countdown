//
//  CountdownWidget.swift
//  CountdownWidget
//
//  Created by Admin on 2/15/23.
//

import WidgetKit
import SwiftUI
import Intents

extension UIColor {
    convenience init(rgb: Int) {
        let iBlue = rgb & 0xFF
        let iGreen =  (rgb >> 8) & 0xFF
        let iRed =  (rgb >> 16) & 0xFF
        let iAlpha =  (rgb >> 24) & 0xFF
        self.init(red: CGFloat(iRed)/255, green: CGFloat(iGreen)/255,
                  blue: CGFloat(iBlue)/255, alpha: CGFloat(iAlpha)/255)
    }
}
extension UIColor {
    
    func rgb() -> Int? {
        var fRed : CGFloat = 0
        var fGreen : CGFloat = 0
        var fBlue : CGFloat = 0
        var fAlpha: CGFloat = 0
        if self.getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: &fAlpha) {
            let iRed = Int(fRed * 255.0)
            let iGreen = Int(fGreen * 255.0)
            let iBlue = Int(fBlue * 255.0)
            let iAlpha = Int(fAlpha * 255.0)

            //  (Bits 24-31 are alpha, 16-23 are red, 8-15 are green, 0-7 are blue).
            let rgb = (iAlpha << 24) + (iRed << 16) + (iGreen << 8) + iBlue
            return rgb
        } else {
            // Could not extract RGBA components:
            return nil
        }
    }
}
struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        let defaults = UserDefaults(suiteName: "group.countdown.com.CountdownClock")
        var timestamp = defaults?.value(forKey: "timestamp") ?? 1704088860
        var topic = defaults?.value(forKey: "topic") ?? "New Years"
        var rawbgColor = defaults?.value(forKey: "bgcolor") ?? UIColor(.black).rgb()
        var bgcolor = UIColor(rgb: rawbgColor as! Int)
        var rawtextColor = defaults?.value(forKey: "textcolor") ?? UIColor(.white).rgb()
        var textcolor = UIColor(rgb: rawtextColor as! Int)
        return SimpleEntry(date: Date(), configuration: ConfigurationIntent(), timestamp: timestamp as! Int, topic: topic as! String, bgcolor: Color(bgcolor), textcolor: Color(textcolor))
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let defaults = UserDefaults(suiteName: "group.countdown.com.CountdownClock")
        var timestamp = defaults?.value(forKey: "timestamp") ?? 1704088860
        var topic = defaults?.value(forKey: "topic") ?? "New Years"
        var rawbgColor = defaults?.value(forKey: "bgcolor") ?? UIColor(.black).rgb()
        var bgcolor = UIColor(rgb: rawbgColor as! Int)
        var rawtextColor = defaults?.value(forKey: "textcolor") ?? UIColor(.white).rgb()
        var textcolor = UIColor(rgb: rawtextColor as! Int)
        let entry = SimpleEntry(date: Date(), configuration: configuration, timestamp: timestamp as! Int, topic: topic as! String, bgcolor: Color(bgcolor), textcolor: Color(textcolor))
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let defaults = UserDefaults(suiteName: "group.countdown.com.CountdownClock")
            var timestamp = defaults?.value(forKey: "timestamp") ?? 1704088860
            var topic = defaults?.value(forKey: "topic") ?? "New Years"
            var rawbgColor = defaults?.value(forKey: "bgcolor") ?? UIColor(.black).rgb()
            var bgcolor = UIColor(rgb: rawbgColor as! Int)
            var rawtextColor = defaults?.value(forKey: "textcolor") ?? UIColor(.white).rgb()
            var textcolor = UIColor(rgb: rawtextColor as! Int)
            let entry = SimpleEntry(date: entryDate, configuration: configuration, timestamp: timestamp as! Int, topic: topic as! String, bgcolor: Color(bgcolor), textcolor: Color(textcolor))
            entries.append(entry)
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
    let timestamp: Int
    let topic: String
    let bgcolor: Color
    let textcolor: Color
}

struct CountdownWidgetEntryView : View {
    var entry: Provider.Entry
    var body: some View {
        ZStack{
            Color(UIColor(entry.bgcolor))
            VStack{
                Text("The time until \(entry.topic) is:")
                    .fontWeight(.bold)
                Text(Date(timeIntervalSince1970: TimeInterval(entry.timestamp)), style: .relative)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    
            }
            .foregroundColor(entry.textcolor)
        }
    }
}

struct CountdownWidget: Widget {
    let kind: String = "CountdownWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            CountdownWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

struct CountdownWidget_Previews: PreviewProvider {
    static var previews: some View {
        CountdownWidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent(), timestamp: 1704088860, topic: "New Years", bgcolor: Color(.systemBackground), textcolor: Color(.label)))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
