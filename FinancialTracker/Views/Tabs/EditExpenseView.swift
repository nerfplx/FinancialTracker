import SwiftUI

struct EditExpenseView: View {
    @EnvironmentObject private var vm: SmartSpendViewModel
    @Environment(\.dismiss) private var dismiss

    let expense: Expense
    @State private var amountText = ""
    @State private var category: ExpenseCategory = .food
    @State private var note = ""
    @State private var isImpulse = false
    @State private var hasChanges = false

    private var parsedAmount: Double {
        vm.parseAmount(amountText) ?? 0
    }

    private static let amountFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    var body: some View {
        NavigationView {
            Form {
                TextField(L10n.EditExpense.amount, text: $amountText)
                    .keyboardType(.decimalPad)
                    .onChange(of: amountText) { newValue in
                        let sanitized = vm.sanitizedAmount(newValue)
                        if sanitized != newValue {
                            amountText = sanitized
                        }
                        hasChanges = true
                    }

                Picker(L10n.EditExpense.category, selection: $category) {
                    ForEach(ExpenseCategory.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }

                TextField(L10n.EditExpense.note, text: $note)
                    .onChange(of: note) { _ in hasChanges = true }
                Toggle(L10n.EditExpense.impulseToggle, isOn: $isImpulse)
                    .onChange(of: isImpulse) { _ in hasChanges = true }
            }
            .onChange(of: category) { _ in hasChanges = true }
            .navigationTitle(L10n.Titles.editExpense)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.save) {
                        dismissKeyboard()
                        vm.updateExpense(
                            id: expense.id,
                            amount: parsedAmount,
                            category: category,
                            note: note,
                            isImpulse: isImpulse
                        )
                        dismiss()
                    }
                    .disabled(parsedAmount <= 0 || !hasChanges)
                }
            }
            .onAppear {
                amountText = Self.amountFormatter.string(from: NSNumber(value: expense.amount)) ?? "\(expense.amount)"
                category = expense.category
                note = expense.note
                isImpulse = expense.isImpulse
                hasChanges = false
            }
        }
    }
}
