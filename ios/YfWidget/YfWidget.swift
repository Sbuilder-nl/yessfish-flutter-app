// YessFish home-screenwidget (iOS): laatste openbare vangst + visweer.
// Data komt uit de app via de home_widget-plugin → UserDefaults in de App Group.
// Zelfde inhoud als de Android-widget (YfWidgetProvider).

import WidgetKit
import SwiftUI

private let appGroup = "group.nl.sbuilder.yessfish"

struct YfEntry: TimelineEntry {
    let date: Date
    let species: String
    let user: String
    let weather: String
    let photo: UIImage?
}

private func laadEntry() -> YfEntry {
    let d = UserDefaults(suiteName: appGroup)
    var foto: UIImage? = nil
    if let b64 = d?.string(forKey: "latest_photo_b64"), !b64.isEmpty,
       let data = Data(base64Encoded: b64) {
        foto = UIImage(data: data)
    }
    return YfEntry(
        date: Date(),
        species: d?.string(forKey: "latest_species") ?? "",
        user: d?.string(forKey: "latest_user") ?? "",
        weather: d?.string(forKey: "weather_text") ?? "",
        photo: foto
    )
}

struct YfProvider: TimelineProvider {
    func placeholder(in context: Context) -> YfEntry {
        YfEntry(date: Date(), species: "Snoek", user: "YessFish", weather: "🌤️ 18° · lichte wind", photo: nil)
    }
    func getSnapshot(in context: Context, completion: @escaping (YfEntry) -> Void) {
        completion(laadEntry())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<YfEntry>) -> Void) {
        // De app ververst de widget zelf bij openen; dit is de vangnet-refresh.
        let herlaad = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [laadEntry()], policy: .after(herlaad)))
    }
}

private let yfNavy = Color(red: 0.051, green: 0.169, blue: 0.243) // app-donkerblauw
private let yfTeal = Color(red: 0.075, green: 0.463, blue: 0.427) // app-teal

struct YfWidgetView: View {
    var entry: YfEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            if family == .systemSmall { klein } else { middel }
        }
        .yfAchtergrond()
    }

    private var foto: some View {
        Group {
            if let img = entry.photo {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    yfTeal.opacity(0.35)
                    Text("🎣").font(.system(size: 28))
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var klein: some View {
        VStack(alignment: .leading, spacing: 5) {
            foto.frame(maxWidth: .infinity).frame(height: 64)
            if !entry.species.isEmpty {
                Text("🎣 \(entry.species)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            if !entry.weather.isEmpty {
                Text(entry.weather)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(12)
    }

    private var middel: some View {
        HStack(spacing: 12) {
            foto.frame(width: 96, height: 96)
            VStack(alignment: .leading, spacing: 4) {
                Text("YessFish")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                if !entry.species.isEmpty {
                    Text("🎣 \(entry.species)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                if !entry.user.isEmpty {
                    Text(entry.user)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                if !entry.weather.isEmpty {
                    Text(entry.weather)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(14)
    }
}

extension View {
    // iOS 17 wil containerBackground; op iOS 16 gewoon een achtergrond.
    @ViewBuilder func yfAchtergrond() -> some View {
        let verloop = LinearGradient(colors: [yfNavy, yfTeal],
                                     startPoint: .topLeading, endPoint: .bottomTrailing)
        if #available(iOS 17.0, *) {
            self.containerBackground(for: .widget) { verloop }
        } else {
            ZStack { verloop; self }
        }
    }
}

@main
struct YfWidgetBundle: WidgetBundle {
    var body: some Widget { YfWidget() }
}

struct YfWidget: Widget {
    let kind = "YfWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: YfProvider()) { entry in
            YfWidgetView(entry: entry)
        }
        .configurationDisplayName("YessFish")
        .description("De laatste vangst en het visweer op je startscherm.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
