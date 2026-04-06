import SwiftUI

struct AddExpenseView: View {
    @EnvironmentObject private var vm: SmartSpendViewModel
    @State private var isImpulse = false
    @State private var draftAmount = ""
    @State private var draftCategory: ExpenseCategory = .food
    @State private var draftNote = ""

    private var parsedAmount: Double {
        vm.parseAmount(draftAmount) ?? 0
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 14) {
                    TextField(L10n.AddExpense.amount, text: $draftAmount)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: draftAmount) { newValue in
                            let sanitized = vm.sanitizedAmount(newValue)
                            if sanitized != newValue {
                                draftAmount = sanitized
                            }
                        }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.AddExpense.category)
                            .font(.headline)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(ExpenseCategory.allCases) { item in
                                    categoryChip(item)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }

                    TextField(L10n.AddExpense.note, text: $draftNote)
                        .textFieldStyle(.roundedBorder)

                    Toggle(L10n.AddExpense.impulseToggle, isOn: $isImpulse)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.AddExpense.aiTitle)
                            .font(.headline)
                        Text(highlightedAdvice)
                            .font(.subheadline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(14)

                    Button(L10n.AddExpense.save) {
                        dismissKeyboard()
                        vm.addExpense(
                            amount: parsedAmount,
                            category: draftCategory,
                            note: draftNote,
                            isImpulse: isImpulse
                        )
                        draftAmount = ""
                        draftNote = ""
                    }
                    .disabled(parsedAmount <= 0)
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding()
                .contentShape(Rectangle())
                .onTapGesture {
                    dismissKeyboard()
                }
            }
            .navigationTitle(L10n.Titles.addExpense)
        }
    }

    private func categoryChip(_ item: ExpenseCategory) -> some View {
        let selected = draftCategory == item
        return Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                draftCategory = item
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: item.icon)
                Text(item.title)
            }
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(selected ? Color.indigo : Color(.secondarySystemBackground))
            .foregroundColor(selected ? .white : .primary)
            .cornerRadius(12)
            .scaleEffect(selected ? 1.04 : 1)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.32, dampingFraction: 0.78), value: draftCategory)
    }

    private var highlightedAdvice: AttributedString {
        let message = vm.aiAdvice(for: parsedAmount, category: draftCategory)
        var result = AttributedString(message)

        let severity = vm.aiSeverity(for: parsedAmount, category: draftCategory)
        let numberColor: Color
        switch severity {
        case .normal: numberColor = .indigo
        case .medium: numberColor = .orange
        case .high: numberColor = .red
        }

        let pattern = #"\d+([.,]\d+)?%?"#
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let ns = message as NSString
            let matches = regex.matches(in: message, range: NSRange(location: 0, length: ns.length))
            for match in matches.reversed() {
                if let range = Range(match.range, in: result) {
                    result[range].foregroundColor = numberColor
                    result[range].font = .system(.subheadline, design: .rounded).bold()
                }
            }
        }

        if severity == .high {
            result.foregroundColor = .red.opacity(0.95)
        } else {
            result.foregroundColor = .secondary
        }
        return result
    }
}
