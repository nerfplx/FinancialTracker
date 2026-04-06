import Foundation

struct UserProfile: Codable {
    var monthlyIncome: Double
    var monthlyLimit: Double
    var dailyLimit: Double
    var usesCustomDailyLimit: Bool
    var autoRecalculateLimit: Bool
    var currency: String
    var goal: SpendGoal
    
    static let empty = UserProfile(
        monthlyIncome: 0,
        monthlyLimit: 1200,
        dailyLimit: 40,
        usesCustomDailyLimit: false,
        autoRecalculateLimit: true,
        currency: "$",
        goal: .control
    )
    
    enum CodingKeys: String, CodingKey {
        case monthlyIncome
        case monthlyLimit
        case dailyLimit
        case usesCustomDailyLimit
        case autoRecalculateLimit
        case currency
        case goal
    }
    
    init(
        monthlyIncome: Double,
        monthlyLimit: Double,
        dailyLimit: Double,
        usesCustomDailyLimit: Bool,
        autoRecalculateLimit: Bool,
        currency: String,
        goal: SpendGoal
    ) {
        self.monthlyIncome = monthlyIncome
        self.monthlyLimit = monthlyLimit
        self.dailyLimit = dailyLimit
        self.usesCustomDailyLimit = usesCustomDailyLimit
        self.autoRecalculateLimit = autoRecalculateLimit
        self.currency = currency
        self.goal = goal
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        monthlyIncome = try container.decodeIfPresent(Double.self, forKey: .monthlyIncome) ?? 0
        monthlyLimit = try container.decodeIfPresent(Double.self, forKey: .monthlyLimit) ?? 1200
        dailyLimit = try container.decodeIfPresent(Double.self, forKey: .dailyLimit) ?? 40
        usesCustomDailyLimit = try container.decodeIfPresent(Bool.self, forKey: .usesCustomDailyLimit) ?? false
        autoRecalculateLimit = try container.decodeIfPresent(Bool.self, forKey: .autoRecalculateLimit) ?? true
        currency = try container.decodeIfPresent(String.self, forKey: .currency) ?? "$"
        goal = try container.decodeIfPresent(SpendGoal.self, forKey: .goal) ?? .control
    }
}
