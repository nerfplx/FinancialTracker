import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var vm: SmartSpendViewModel
    @State private var page = 0
    @State private var income = ""
    @State private var goal: SpendGoal = .control

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 52, weight: .bold))
                .foregroundColor(.blue)

            Text(page == 0 ? L10n.Onboarding.titleBudget : L10n.Onboarding.titleGoal)
                .font(.title3.bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if page == 0 {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.Onboarding.incomeLabel)
                        .font(.subheadline.weight(.semibold))
                    TextField(L10n.Onboarding.incomePlaceholder, text: $income)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: income) { newValue in
                            let sanitized = vm.sanitizedAmount(newValue)
                            if sanitized != newValue {
                                income = sanitized
                            }
                        }
                }
                .padding(.horizontal)
            } else {
                VStack(spacing: 12) {
                    ForEach(SpendGoal.allCases) { value in
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                goal = value
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(value.title)
                                    .font(.headline)
                                Text(value.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(goal == value ? Color.indigo.opacity(0.14) : Color(.secondarySystemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(goal == value ? Color.indigo : Color.clear, lineWidth: 1.5)
                            )
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }

            Button(page == 0 ? L10n.Onboarding.next : L10n.Onboarding.start) {
                dismissKeyboard()
                if page == 0 {
                    page = 1
                } else {
                    let parsedIncome = vm.parseAmount(income) ?? 0
                    vm.onboardingFinish(income: max(parsedIncome, 1), goal: goal)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal)

            Text(L10n.Onboarding.hint)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()
        }
        .padding(.bottom)
        .contentShape(Rectangle())
        .onTapGesture {
            dismissKeyboard()
        }
    }
}
