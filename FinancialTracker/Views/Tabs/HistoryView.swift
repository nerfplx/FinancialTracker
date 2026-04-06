import SwiftUI

private enum HistoryPeriod: String, CaseIterable, Identifiable {
    case day = "day"
    case week = "week"
    case month = "month"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .day: return L10n.History.day
        case .week: return L10n.History.week
        case .month: return L10n.History.month
        }
    }
}

struct HistoryView: View {
    @EnvironmentObject private var vm: SmartSpendViewModel
    @EnvironmentObject private var localization: LocalizationManager
    @State private var selectedPeriod: HistoryPeriod = .week
    @State private var selectedDate = Date()
    @State private var selectedCategory: ExpenseCategory?
    @State private var showOnlyImpulse = false

    private static let calendar: Calendar = {
        var c = Calendar.current
        c.firstWeekday = 2
        c.minimumDaysInFirstWeek = 4
        return c
    }()

    private var calendar: Calendar { Self.calendar }

    var body: some View {
        NavigationView {
            VStack(spacing: 10) {
                Picker(L10n.History.period, selection: $selectedPeriod) {
                    ForEach(HistoryPeriod.allCases) { period in
                        Text(period.title).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                periodNavigator
                totalRow
                categoryFilter
                impulseToggle

                if filteredExpenses.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "calendar")
                            .font(.system(size: 36))
                            .foregroundColor(.secondary.opacity(0.5))
                            Text(L10n.History.emptyDay(emptyStateLabel))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(groupedByDay, id: \.0) { day, items in
                            Section {
                                ForEach(items) { item in
                                    HStack {
                                        Image(systemName: item.category.icon)
                                            .frame(width: 22)
                                            .foregroundColor(.indigo)
                                        VStack(alignment: .leading, spacing: 3) {
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
                                        }
                                        Spacer()
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text(vm.format(item.amount))
                                                .font(.subheadline.weight(.semibold))
                                            Text(item.date, style: .time)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.vertical, 2)
                                }
                            } header: {
                                HStack {
                                    Text(dayHeader(day))
                                    Spacer()
                                    Text(vm.format(items.reduce(0) { $0 + $1.amount }))
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle(L10n.Titles.history)
        }
    }

    private var periodExpenses: [Expense] {
        switch selectedPeriod {
        case .day:
            return vm.expenses.filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
        case .week:
            guard let interval = calendar.dateInterval(of: .weekOfYear, for: selectedDate) else { return [] }
            return vm.expenses.filter { interval.contains($0.date) }
        case .month:
            return vm.expenses.filter { calendar.isDate($0.date, equalTo: selectedDate, toGranularity: .month) }
        }
    }

    private var filteredExpenses: [Expense] {
        periodExpenses.filter { expense in
            let categoryMatch = selectedCategory == nil || expense.category == selectedCategory
            let impulseMatch = !showOnlyImpulse || expense.isImpulse
            return categoryMatch && impulseMatch
        }
    }

    private var groupedByDay: [(Date, [Expense])] {
        let grouped = Dictionary(grouping: filteredExpenses) { expense in
            calendar.startOfDay(for: expense.date)
        }
        return grouped
            .map { ($0.key, $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.0 > $1.0 }
    }

    private var periodTotal: Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }

    private var isCurrentPeriod: Bool {
        let now = Date()
        switch selectedPeriod {
        case .day:
            return calendar.isDate(selectedDate, inSameDayAs: now)
        case .week:
            return calendar.component(.weekOfYear, from: selectedDate) == calendar.component(.weekOfYear, from: now)
                && calendar.component(.yearForWeekOfYear, from: selectedDate) == calendar.component(.yearForWeekOfYear, from: now)
        case .month:
            return calendar.isDate(selectedDate, equalTo: now, toGranularity: .month)
        }
    }

    private var periodLabel: String {
        switch selectedPeriod {
        case .day:
            return Self.dayFormatter(locale: localization.locale).string(from: selectedDate)
        case .week:
            guard let interval = calendar.dateInterval(of: .weekOfYear, for: selectedDate) else {
                return L10n.History.week
            }
            let start = Self.shortFormatter(locale: localization.locale).string(from: interval.start)
            let end = Self.shortFormatter(locale: localization.locale).string(from: calendar.date(byAdding: .day, value: 6, to: interval.start) ?? interval.end)
            return "\(start) - \(end)"
        case .month:
            return Self.monthFormatter(locale: localization.locale).string(from: selectedDate).capitalized
        }
    }

    private var emptyStateLabel: String {
        switch selectedPeriod {
        case .day:
            return dayHeader(selectedDate)
        case .week:
            return L10n.History.emptyWeek
        case .month:
            return Self.monthFormatter(locale: localization.locale).string(from: selectedDate).lowercased()
        }
    }

    private var periodNavigator: some View {
        HStack {
            Button {
                shiftPeriod(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }

            Spacer()

            Text(periodLabel)
                .font(.subheadline.weight(.semibold))

            Spacer()

            Button {
                shiftPeriod(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(isCurrentPeriod)
        }
        .padding(.horizontal)
    }

    private var totalRow: some View {
        HStack {
            Text(L10n.History.total)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(vm.format(periodTotal))
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal)
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryChip(nil, label: L10n.Common.all)
                ForEach(ExpenseCategory.allCases) { category in
                    categoryChip(category, label: category.title)
                }
            }
            .padding(.horizontal)
        }
    }

    private var impulseToggle: some View {
        Toggle(isOn: $showOnlyImpulse) {
            Label(L10n.History.onlyImpulse, systemImage: "bolt.fill")
                .font(.subheadline)
        }
        .padding(.horizontal)
    }

    private func categoryChip(_ category: ExpenseCategory?, label: String) -> some View {
        let isSelected = selectedCategory == category
        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                selectedCategory = category
            }
        } label: {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .foregroundColor(isSelected ? .white : .primary)
                .background(isSelected ? Color.indigo : Color(.secondarySystemBackground))
                .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    private func shiftPeriod(by value: Int) {
        switch selectedPeriod {
        case .day:
            selectedDate = calendar.date(byAdding: .day, value: value, to: selectedDate) ?? selectedDate
        case .week:
            selectedDate = calendar.date(byAdding: .weekOfYear, value: value, to: selectedDate) ?? selectedDate
        case .month:
            selectedDate = calendar.date(byAdding: .month, value: value, to: selectedDate) ?? selectedDate
        }
    }

    private static func dayFormatter(locale: Locale) -> DateFormatter {
        let f = DateFormatter()
        f.locale = locale
        f.dateFormat = "d MMMM, EEEE"
        return f
    }

    private static func shortFormatter(locale: Locale) -> DateFormatter {
        let f = DateFormatter()
        f.locale = locale
        f.dateFormat = "d MMM"
        return f
    }

    private static func monthFormatter(locale: Locale) -> DateFormatter {
        let f = DateFormatter()
        f.locale = locale
        f.dateFormat = "LLLL yyyy"
        return f
    }

    private func dayHeader(_ date: Date) -> String {
        Self.dayFormatter(locale: localization.locale).string(from: date)
    }
}
