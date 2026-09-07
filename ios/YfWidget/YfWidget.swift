// YessFish home-screenwidget (iOS): laatste openbare vangst + visweer + snelknoppen.
// Zelfde inhoud en knoppen als de Android-widget (YfWidgetProvider): vangst, stek, kaart, feed.
// Data komt uit de app via de home_widget-plugin → UserDefaults in de App Group.
// Knoppen openen de app met yessfishwidget://<doel>?homeWidget (home_widget vereist de query 'homeWidget').

import WidgetKit
import SwiftUI

private let appGroup = "group.nl.sbuilder.yessfish"

struct YfEntry: TimelineEntry {
    let date: Date
    let species: String
    let user: String
    let weather: String
    let catchId: String
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
        catchId: d?.string(forKey: "latest_catch_id") ?? "",
        photo: foto
    )
}

private func yfUrl(_ doel: String) -> URL { URL(string: "yessfishwidget://\(doel)?homeWidget")! }

struct YfProvider: TimelineProvider {
    func placeholder(in context: Context) -> YfEntry {
        YfEntry(date: Date(), species: "Snoek", user: "YessFish", weather: "🌤️ 18° · lichte wind", catchId: "", photo: nil)
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
private let yfMint = Color(red: 0.55, green: 0.90, blue: 0.80)

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

    // Kleine widget: laatste vangst; tik = snelvangst (de snelste weg om te loggen).
    private var klein: some View {
        VStack(alignment: .leading, spacing: 5) {
            foto.frame(maxWidth: .infinity).frame(height: 58)
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
            HStack(spacing: 4) {
                Image(systemName: "camera.fill").font(.system(size: 10, weight: .bold))
                Text("Snelvangst").font(.system(size: 11, weight: .bold))
            }
            .foregroundColor(yfNavy)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(yfMint)
            .clipShape(Capsule())
        }
        .padding(12)
        .widgetURL(yfUrl("catch"))
    }

    private func knop(_ doel: String, _ icoon: String, _ tekst: String) -> some View {
        Link(destination: yfUrl(doel)) {
            VStack(spacing: 2) {
                Image(systemName: icoon).font(.system(size: 14, weight: .bold))
                Text(tekst).font(.system(size: 9, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.8)
            }
            .foregroundColor(yfNavy)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(yfMint)
            .clipShape(RoundedRectangle(cornerRadius: 9))
        }
    }

    // Middelgrote widget: foto (tik = die vangst) + info + vier knoppen zoals op Android.
    private var middel: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Group {
                    if entry.catchId.isEmpty { foto } else { Link(destination: yfUrl("view/\(entry.catchId)")) { foto } }
                }
                .frame(width: 84, height: 72)
                VStack(alignment: .leading, spacing: 3) {
                    Text("YessFish")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                    if !entry.species.isEmpty {
                        Text("🎣 \(entry.species)")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    if !entry.user.isEmpty {
                        Text(entry.user)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.85))
                            .lineLimit(1)
                    }
                    if !entry.weather.isEmpty {
                        Text(entry.weather)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: 6) {
                knop("catch", "camera.fill", "Vangst")
                knop("spot", "mappin.and.ellipse", "Stek")
                knop("map", "map.fill", "Kaart")
                knop("feed", "bubble.left.and.bubble.right.fill", "Feed")
            }
        }
        .padding(12)
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
        .description("Laatste vangst, visweer en snelknoppen: vangst, stek, kaart, feed.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
