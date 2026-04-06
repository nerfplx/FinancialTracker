import Foundation

struct NotificationSettings: Codable {
    var notifyDailyOverrun: Bool
    var notifyDailySummary: Bool
    var notifyImpulse: Bool
    
    static let `default` = NotificationSettings(
        notifyDailyOverrun: false,
        notifyDailySummary: false,
        notifyImpulse: false
    )
}
