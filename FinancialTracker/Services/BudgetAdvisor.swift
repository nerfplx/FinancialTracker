import Foundation

struct BudgetAdvisor {
    func advice(
        amount: Double,
        category: ExpenseCategory,
        todayExpenses: [Expense],
        todaySpent: Double,
        dailyLimit: Double,
        formattedAmount: (Double) -> String
    ) -> String {
        guard dailyLimit > 0 else {
            return L10n.Advisor.noLimit
        }
        
        let alreadyToday = todayExpenses
            .filter { $0.category == category }
            .reduce(0) { $0 + $1.amount }
        let projected = todaySpent + amount
        let overrun = max(((projected - dailyLimit) / dailyLimit) * 100, 0)
        
        if amount > dailyLimit * 0.7 {
            return L10n.Advisor.largePurchase
        }
        if alreadyToday > 0 {
            return L10n.Advisor.alreadyToday(formattedAmount(alreadyToday), overrunPercent: Int(overrun.rounded()))
        }
        if projected > dailyLimit {
            return L10n.Advisor.overLimit(overrunPercent: Int(overrun.rounded()))
        }
        return L10n.Advisor.ok
    }
}
