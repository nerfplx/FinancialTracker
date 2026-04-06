import Foundation

enum ExpenseCategory: String, CaseIterable, Codable, Identifiable {
    case food = "food"
    case transport = "transport"
    case shopping = "shopping"
    case entertainment = "entertainment"
    case health = "health"
    case subscriptions = "subscriptions"
    
    var id: String {
        switch self {
        case .food: return "food"
        case .transport: return "transport"
        case .shopping: return "shopping"
        case .entertainment: return "entertainment"
        case .health: return "health"
        case .subscriptions: return "subscriptions"
        }
    }

    var title: String {
        switch self {
        case .food: return L10n.Categories.food
        case .transport: return L10n.Categories.transport
        case .shopping: return L10n.Categories.shopping
        case .entertainment: return L10n.Categories.entertainment
        case .health: return L10n.Categories.health
        case .subscriptions: return L10n.Categories.subscriptions
        }
    }
    
    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .shopping: return "bag.fill"
        case .entertainment: return "gamecontroller.fill"
        case .health: return "heart.fill"
        case .subscriptions: return "repeat.circle.fill"
        }
    }
}
