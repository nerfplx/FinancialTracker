import Foundation

enum BudgetCalculator {
    static func monthlyLimit(from income: Double, goal: SpendGoal) -> Double {
        switch goal {
        case .saveMore:
            return max(income * 0.35, 500)
        case .control:
            return max(income * 0.45, 700)
        }
    }
    
    static func dailyLimit(from monthly: Double) -> Double {
        max(monthly / 30, 10)
    }
}
