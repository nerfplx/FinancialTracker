import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var vm: SmartSpendViewModel
    @State private var editingExpense: Expense?
    
    private var daysLeftInMonth: Int {
        let calendar = Calendar.current
        let now = Date()
        guard let range = calendar.range(of: .day, in: .month, for: now) else { return 0 }
        let lastDay = range.count
        let currentDay = calendar.component(.day, from: now)
        return lastDay - currentDay + 1
    }
    
    private var monthProgressRatio: CGFloat {
        guard vm.profile.monthlyLimit > 0 else { return 0 }
        return CGFloat(min(vm.monthSpent / vm.profile.monthlyLimit, 1))
    }
    
    private var dayProgressRatio: CGFloat {
        guard vm.profile.dailyLimit > 0 else { return 0 }
        return CGFloat(min(vm.todaySpent / vm.profile.dailyLimit, 1))
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    VStack(spacing: 8) {
                        combinedProgressCard
                            .padding(.bottom, 24)
                        if vm.todayOverrunPercent > 0 {
                            todayOverrunCard
                        }
                        if vm.dailySummary.impulse > 0 {
                            dailySummaryCard
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color.clear)
                }
                
                Section {
                    if vm.todayExpenses.isEmpty {
                        Text(L10n.Dashboard.noExpenses)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(vm.todayExpenses) { item in
                            expenseRow(item)
                        }
                        .onDelete(perform: deleteExpenses)
                    }
                } header: {
                    Text(L10n.Dashboard.sectionTodayExpenses)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(L10n.Titles.dashboard)
            .sheet(item: $editingExpense) { item in
                EditExpenseView(expense: item)
                    .environmentObject(vm)
            }
        }
    }
    
    private var combinedProgressCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            monthProgressCard
            todayProgressCard
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var todayOverrunCard: some View {
        Text(L10n.Dashboard.overrunPercent(Int(vm.todayOverrunPercent.rounded())))
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.red)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )
    }

    private var dailySummaryCard: some View {
        Text(L10n.Dashboard.impulseSpent(vm.format(vm.dailySummary.impulse)))
            .font(.subheadline)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )
    }
    
    private var monthProgressCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(L10n.Dashboard.month)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Spacer()
                Text(L10n.Dashboard.daysLeft(daysLeftInMonth))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text("\(vm.format(vm.monthSpent)) / \(vm.format(vm.profile.monthlyLimit))")
                .font(.title3.bold())
                .foregroundColor(.primary)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.gray.opacity(0.15))
                    Capsule()
                        .fill(monthProgressRatio > 0.85 ? Color.orange : Color.indigo)
                        .frame(width: monthProgressRatio * geo.size.width)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }
    
    private var todayProgressCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(L10n.Dashboard.dailyLimit)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            Text("\(vm.format(vm.todaySpent)) / \(vm.format(vm.profile.dailyLimit))")
                .font(.title3.bold())
                .foregroundColor(.primary)
            GeometryReader { geo in
                let ratio = dayProgressRatio
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.gray.opacity(0.15))
                    Capsule()
                        .fill(ratio > 0.85 ? Color.red : Color.indigo)
                        .frame(width: ratio * geo.size.width)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }
    
    private func expenseRow(_ item: Expense) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: item.category.icon)
                .foregroundColor(.indigo)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(item.category.title)
                        .font(.subheadline.weight(.semibold))
                    if item.isImpulse {
                        Image(systemName: "bolt.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
                Text(item.note.isEmpty ? L10n.Common.emptyNote : item.note)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(item.date, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(vm.format(item.amount))
                .font(.subheadline.weight(.semibold))
            
            Menu {
                Button(L10n.Dashboard.menuEdit) {
                    editingExpense = item
                }
                Button(L10n.Dashboard.menuDelete, role: .destructive) {
                    vm.deleteExpense(id: item.id)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func deleteExpenses(at offsets: IndexSet) {
        let ids = offsets.map { vm.todayExpenses[$0].id }
        for id in ids {
            vm.deleteExpense(id: id)
        }
    }
}
