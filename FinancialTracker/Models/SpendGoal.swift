import Foundation

enum SpendGoal: String, CaseIterable, Codable, Identifiable {
    case saveMore = "saveMore"
    case control = "control"
    
    var id: String {
        switch self {
        case .saveMore: return "saveMore"
        case .control: return "control"
        }
    }
    
    var description: String {
        switch self {
        case .saveMore:
            return L10n.Goals.saveMoreDesc
        case .control:
            return L10n.Goals.controlDesc
        }
    }

    var title: String {
        switch self {
        case .saveMore: return L10n.Goals.saveMore
        case .control: return L10n.Goals.control
        }
    }
}
