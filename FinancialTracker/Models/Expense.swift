import Foundation

struct Expense: Identifiable, Codable {
    let id: UUID
    let amount: Double
    let category: ExpenseCategory
    let note: String
    let date: Date
    let isImpulse: Bool
}
