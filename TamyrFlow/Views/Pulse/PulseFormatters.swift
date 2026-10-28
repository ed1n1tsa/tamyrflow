import Foundation

enum PulseFormatters {
    static var locale: Locale {
        Locale(identifier: LanguageStoreBootstrap.bundle.preferredLocalizations.first ?? "ru")
    }

    static func bpm(_ value: Double?) -> String {
        guard let value else { return "—" }
        return "\(Int(value.rounded()))"
    }

    static func bpmWithUnit(_ value: Double?) -> String {
        guard let value else { return L10n.Pulse.noData }
        return "\(Int(value.rounded())) \(L10n.Pulse.bpmUnit)"
    }

    static func relativeDateTime(_ date: Date) -> String {
        let cal = Calendar.current
        let time: DateFormatter = {
            let f = DateFormatter()
            f.locale = locale
            f.dateFormat = "HH:mm"
            return f
        }()
        if cal.isDateInToday(date) {
            return "\(L10n.Pulse.today), \(time.string(from: date))"
        }
        if cal.isDateInYesterday(date) {
            return "\(L10n.Pulse.yesterday), \(time.string(from: date))"
        }
        let day: DateFormatter = {
            let f = DateFormatter()
            f.locale = locale
            f.setLocalizedDateFormatFromTemplate("d MMM")
            return f
        }()
        return "\(day.string(from: date)), \(time.string(from: date))"
    }

    static func shortDateTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.setLocalizedDateFormatFromTemplate("d MMM, HH:mm")
        return f.string(from: date)
    }

    static func weekdayShort(_ date: Date) -> String {
        let cal = Calendar.current
        // Calendar weekday: 1=Sun … 7=Sat → map to goals_day_* via L10n.Activity
        return L10n.Activity.weekdayShort(cal.component(.weekday, from: date))
    }

    static func sourceTitle(_ source: PulseSource) -> String {
        switch source {
        case .device: return L10n.Pulse.sourceWatch
        case .appleHealth: return L10n.Pulse.sourceAppleHealth
        case .manual: return L10n.Pulse.sourceManual
        }
    }

    static func trendText(_ percent: Double?, period: PulsePeriod) -> String? {
        guard let percent else { return nil }
        let arrow = percent >= 0 ? "↑" : "↓"
        let absPct = abs(percent)
        let pct = absPct < 1 ? String(format: "%.1f%%", absPct) : String(format: "%.0f%%", absPct)
        let compare: String
        switch period {
        case .day: compare = L10n.Pulse.vsPrevDay
        case .week: compare = L10n.Pulse.vsPrevWeek
        case .month: compare = L10n.Pulse.vsPrevMonth
        }
        return "\(arrow) \(pct) \(compare)"
    }
}
