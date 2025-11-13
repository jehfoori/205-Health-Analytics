import Foundation

struct PhysiologicalPoint: Identifiable {
    let id = UUID()
    let time: Date
    let hrv: Double
    let heartRate: Int
}

struct DailyPhysio: Identifiable {
    let id = UUID()
    let date: Date
    let avgHRV: Double
    let avgHR: Double
}

struct AppUsageStat: Identifiable {
    let id = UUID()
    let appName: String
    let category: String
    let minutesToday: Int
    let minutes7dAvg: Int
    let trend: UsageTrend
}

struct UsageInterval: Identifiable {
    let id = UUID()
    let start: Date
    let end: Date
    let appName: String
    let minutes: Int
}

extension MockData {
    // timeline for today, overall
    static let usageTimelineToday: [UsageInterval] = {
        let cal = Calendar.current
        let today = Date()
        func time(_ hour: Int, _ min: Int) -> Date {
            cal.date(bySettingHour: hour, minute: min, second: 0, of: today) ?? today
        }
        return [
            UsageInterval(start: time(8, 30), end: time(8, 37), appName: "Instagram", minutes: 7),
            UsageInterval(start: time(9, 10), end: time(9, 14), appName: "Mail", minutes: 4),
            UsageInterval(start: time(12, 40), end: time(12, 55), appName: "TikTok", minutes: 15),
            UsageInterval(start: time(22, 10), end: time(22, 40), appName: "TikTok", minutes: 30),
        ]
    }()
}


enum UsageTrend {
    case up, down, flat
}

struct AssociationInsight: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let corr: Double
    let direction: AssociationDirection
}

enum AssociationDirection {
    case stressor
    case helper
}

enum MockData {
    static let physioStressScore = 72
    static let physioStressLabel = "Moderate stress"
    static let physioStressSubtitle = "Based on HRV variability + resting HR"

    // today, intra-day
    static let physiologicalToday: [PhysiologicalPoint] = {
        let now = Date()
        return (0..<7).map { idx in
            let t = Calendar.current.date(byAdding: .hour, value: -idx * 2, to: now) ?? now
            return PhysiologicalPoint(
                time: t,
                hrv: Double.random(in: 48...75),
                heartRate: Int.random(in: 58...82)
            )
        }.sorted { $0.time < $1.time }
    }()

    // long-term (7 days)
    static let physiologicalDaily: [DailyPhysio] = {
        let cal = Calendar.current
        return (0..<7).map { offset in
            let d = cal.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
            return DailyPhysio(
                date: d,
                avgHRV: Double.random(in: 50...80),
                avgHR: Double.random(in: 58...75)
            )
        }.reversed()
    }()

    // screen time
    static let topAppsToday: [AppUsageStat] = [
        AppUsageStat(appName: "TikTok",    category: "Social",       minutesToday: 52, minutes7dAvg: 47, trend: .up),
        AppUsageStat(appName: "Instagram", category: "Social",       minutesToday: 38, minutes7dAvg: 30, trend: .up),
        AppUsageStat(appName: "YouTube",   category: "Entertainment",minutesToday: 33, minutes7dAvg: 40, trend: .down),
        AppUsageStat(appName: "Mail",      category: "Productivity", minutesToday: 14, minutes7dAvg: 19, trend: .flat),
        AppUsageStat(appName: "Calm",      category: "Health",       minutesToday: 8,  minutes7dAvg: 6,  trend: .flat),
    ]

    // associations (for its tab)
    static let associations: [AssociationInsight] = [
        AssociationInsight(
            title: "Late TikTok",
            description: "HRV lower next morning when usage >40min after 11pm.",
            corr: -0.44,
            direction: .stressor
        ),
        AssociationInsight(
            title: "Instagram bursts",
            description: "Multiple 5–10min checks correlate w/ higher HR.",
            corr: -0.28,
            direction: .stressor
        ),
        AssociationInsight(
            title: "Calm sessions",
            description: "Small HRV uptick within 1h of session.",
            corr: 0.22,
            direction: .helper
        )
    ]
}

struct TodayEvent: Identifiable {
    let id = UUID()
    let time: String     // "22:10"
    let title: String    // "Long TikTok session"
    let note: String     // "HRV dipped 15 min later"
    let severity: TodayEventSeverity
}

enum TodayEventSeverity {
    case low, med, high
}

struct BehaviorPattern: Identifiable {
    let id = UUID()
    let title: String      // "Evening social"
    let description: String
    let strength: String   // "consistent", "weak", "emerging"
}

extension MockData {
    static let todayEvents: [TodayEvent] = [
        TodayEvent(time: "08:30 - 09:16", title: "Twitter [46m]", note: "Extended period of elevated heart rate", severity: .med),
        TodayEvent(time: "22:15 - 22:45", title: "TikTok [30m]", note: "Prolonged use past scheduled bed time", severity: .high)
    ]

    static let behaviorPatterns: [BehaviorPattern] = [
        BehaviorPattern(
            title: "Morning Habits",
            description: "Consistent usage of social media upon waking",
            strength: "consistent"
        ),
        BehaviorPattern(
            title: "Day Habits",
            description: "",
            strength: "weak"
        ),
        BehaviorPattern(
            title: "Night Habits",
            description: "Decrease in usage during night-hours",
            strength: "emerging"
        )
    ]
}
