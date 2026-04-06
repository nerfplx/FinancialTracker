import SwiftUI

private enum AnalyticsPeriod: String, CaseIterable, Identifiable {
    case week = "week"
    case month = "month"
    case year = "year"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .week: return L10n.Analytics.week
        case .month: return L10n.Analytics.month
        case .year: return L10n.Analytics.year
        }
    }
}

struct AnalyticsView: View {
    @EnvironmentObject private var vm: SmartSpendViewModel
    @EnvironmentObject private var localization: LocalizationManager
    @State private var selectedPeriod: AnalyticsPeriod = .month
    @State private var selectedBarIndex: Int?

    @State private var cachedFilteredExpenses: [Expense] = []
    @State private var cachedTotalSpent: Double = 0
    @State private var cachedCategorySpend: [(ExpenseCategory, Double)] = []
    @State private var cachedChartData: [(String, Double)] = []

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Picker(L10n.Analytics.period, selection: $selectedPeriod) {
                        ForEach(AnalyticsPeriod.allCases) { period in
                            Text(period.title).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)

                    if cachedFilteredExpenses.isEmpty {
                        emptyState
                    } else {
                        periodInfoCard
                        totalCard
                        impulseCard

                        Text(L10n.Analytics.categories)
                            .font(.headline)

                        ForEach(cachedCategorySpend, id: \.0.id) { category, amount in
                            let percent = cachedTotalSpent > 0 ? Int((amount / cachedTotalSpent) * 100) : 0
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Image(systemName: category.icon)
                                        .foregroundColor(.indigo)
                                        .frame(width: 20)
                                    Text(category.title)
                                    Spacer()
                                    Text(vm.format(amount)).bold()
                                    Text("\(percent)%")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                GeometryReader { geo in
                                    let maxValue = cachedCategorySpend.first?.1 ?? 1
                                    let width = maxValue > 0 ? (amount / maxValue) * geo.size.width : 0
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(Color.gray.opacity(0.2))
                                        Capsule().fill(Color.blue).frame(width: width)
                                    }
                                }
                                .frame(height: 10)
                            }
                        }

                        chartCard
                        insightsCard
                    }
                }
                .padding()
            }
            .navigationTitle(L10n.Titles.analytics)
            .onAppear {
                recalculatePeriodData()
            }
            .onChange(of: selectedPeriod) { _ in
                selectedBarIndex = nil
                recalculatePeriodData()
            }
            .onReceive(vm.$expenses) { _ in
                recalculatePeriodData()
            }
        }
    }

    private var mondayCalendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        return calendar
    }

    private var impulseMetrics: (count: Int, total: Double) {
        let impulse = cachedFilteredExpenses.filter(\.isImpulse)
        return (impulse.count, impulse.reduce(0) { $0 + $1.amount })
    }

    private var mostFrequentCategory: ExpenseCategory? {
        Dictionary(grouping: cachedFilteredExpenses, by: { $0.category })
            .max { $0.value.count < $1.value.count }?.key
    }

    private var mostExpensiveCategory: ExpenseCategory? {
        cachedCategorySpend.first?.0
    }

    private var averagePerDay: Double {
        let days: Double
        switch selectedPeriod {
        case .week:
            days = 7
        case .month:
            days = 30
        case .year:
            days = 365
        }
        return cachedTotalSpent / days
    }

    private var impulseSharePercent: Int {
        guard cachedTotalSpent > 0 else { return 0 }
        return Int(((impulseMetrics.total / cachedTotalSpent) * 100).rounded())
    }

    private var periodDescription: String {
        let now = Date()
        let calendar = mondayCalendar
        switch selectedPeriod {
        case .year:
            let year = calendar.component(.year, from: now)
            return L10n.Analytics.periodYear(year: year, count: cachedFilteredExpenses.count)
        case .month:
            return L10n.Analytics.periodMonth(
                Self.monthFormatter(locale: localization.locale).string(from: now).capitalized,
                count: cachedFilteredExpenses.count
            )
        case .week:
            guard let interval = calendar.dateInterval(of: .weekOfYear, for: now) else {
                return L10n.Analytics.periodWeekFallback(count: cachedFilteredExpenses.count)
            }
            let start = Self.shortFormatter(locale: localization.locale).string(from: interval.start)
            let end = Self.shortFormatter(locale: localization.locale).string(from: calendar.date(byAdding: .day, value: 6, to: interval.start) ?? interval.end)
            return L10n.Analytics.periodWeek(start: start, end: end, count: cachedFilteredExpenses.count)
        }
    }

    private var limitComparisonText: String {
        switch selectedPeriod {
        case .week:
            let weeklyLimit = vm.profile.monthlyLimit / 4.33
            guard weeklyLimit > 0 else { return "—" }
            let pct = Int(((cachedTotalSpent / weeklyLimit) * 100).rounded())
            return L10n.Analytics.limitWeekPercent(pct)
        case .month:
            guard vm.profile.monthlyLimit > 0 else { return "—" }
            let pct = Int(((cachedTotalSpent / vm.profile.monthlyLimit) * 100).rounded())
            return L10n.Analytics.limitMonthPercent(pct)
        case .year:
            let yearlyLimit = vm.profile.monthlyLimit * 12
            guard yearlyLimit > 0 else { return "—" }
            let pct = Int(((cachedTotalSpent / yearlyLimit) * 100).rounded())
            return L10n.Analytics.limitYearPercent(pct)
        }
    }

    private var periodInfoCard: some View {
        Text(periodDescription)
            .font(.subheadline)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(14)
    }

    private var totalCard: some View {
        VStack(spacing: 4) {
            Text(L10n.Analytics.totalTitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(vm.format(cachedTotalSpent))
                .font(.title.bold())
            Text(limitComparisonText)
                .font(.caption)
                .foregroundColor(.orange)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }

    private var impulseCard: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(L10n.Analytics.impulseTitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(L10n.Analytics.impulseValue(count: impulseMetrics.count, totalFormatted: vm.format(impulseMetrics.total)))
                    .font(.headline)
                    .foregroundColor(.red)
            }
            Spacer()
            Image(systemName: "bolt.fill")
                .foregroundColor(.red)
        }
        .padding()
        .background(Color.red.opacity(0.08))
        .cornerRadius(14)
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(chartTitle)
                .font(.headline)

            GeometryReader { geo in
                barChart(geo: geo)
            }
            .frame(height: 130)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }

    private var insightsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.Analytics.insights)
                .font(.headline)
            insightRow(
                icon: "repeat.circle",
                label: L10n.Analytics.insightMostFrequent,
                value: mostFrequentCategory?.title ?? "—"
            )
            insightRow(
                icon: "arrow.up.circle",
                label: L10n.Analytics.insightMostExpensive,
                value: mostExpensiveCategory?.title ?? "—"
            )
            insightRow(
                icon: "calendar.day.timeline.left",
                label: L10n.Analytics.insightAvgPerDay,
                value: vm.format(averagePerDay)
            )
            insightRow(
                icon: "bolt.circle",
                label: L10n.Analytics.insightImpulseShare,
                value: "\(impulseSharePercent)%"
            )
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.4))
            Text(L10n.Analytics.emptyTitle)
                .font(.headline)
            Text(L10n.Analytics.emptySubtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private func insightRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundColor(.indigo)
            Text(label).foregroundColor(.secondary)
            Spacer()
            Text(value).fontWeight(.semibold)
        }
    }

    private func barChart(geo: GeometryProxy) -> some View {
        let maxValue = cachedChartData.map(\.1).max() ?? 1
        let labelHeight: CGFloat = 14
        let valueHeight: CGFloat = 14
        let spacing: CGFloat = 6
        let count = max(CGFloat(cachedChartData.count), 1)
        let columnWidth = max((geo.size.width - spacing * (count - 1)) / count, 10)
        let barWidth = max(min(columnWidth * 0.75, 20), 8)
        let barAreaHeight = max(geo.size.height - labelHeight - valueHeight - 12, 1)
        return HStack(alignment: .bottom, spacing: spacing) {
            ForEach(Array(cachedChartData.enumerated()), id: \.offset) { index, item in
                let height = maxValue > 0 ? (item.1 / maxValue) * barAreaHeight : 0
                VStack(spacing: 6) {
                    Text(selectedBarIndex == index && item.1 > 0 ? vm.format(item.1) : " ")
                        .font(.caption2)
                        .foregroundColor(.indigo)
                        .lineLimit(1)
                        .frame(height: valueHeight)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.indigo.opacity(0.85))
                        .frame(width: barWidth, height: max(height, 2))
                        .onTapGesture { selectedBarIndex = index }
                    Text(item.0)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(width: columnWidth, height: labelHeight)
                }
                .frame(width: columnWidth)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    private var chartTitle: String {
        switch selectedPeriod {
        case .week: return L10n.Analytics.chartWeek
        case .month: return L10n.Analytics.chartMonth
        case .year: return L10n.Analytics.chartYear
        }
    }

    private func recalculatePeriodData() {
        let filtered = makeFilteredExpenses()
        cachedFilteredExpenses = filtered
        cachedTotalSpent = filtered.reduce(0) { $0 + $1.amount }
        cachedCategorySpend = Dictionary(grouping: filtered, by: { $0.category })
            .map { ($0.key, $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.1 > $1.1 }
        cachedChartData = makeChartData(from: filtered)
    }

    private func makeFilteredExpenses() -> [Expense] {
        let now = Date()
        let calendar = mondayCalendar
        switch selectedPeriod {
        case .year:
            return vm.expenses.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .year) }
        case .month:
            return vm.expenses.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
        case .week:
            guard let interval = calendar.dateInterval(of: .weekOfYear, for: now) else { return [] }
            return vm.expenses.filter { interval.contains($0.date) }
        }
    }

    private func makeChartData(from filtered: [Expense]) -> [(String, Double)] {
        switch selectedPeriod {
        case .week:
            return weeklyData(from: filtered)
        case .month:
            return monthlyByWeek(from: filtered)
        case .year:
            return byMonthInYear(from: filtered)
        }
    }

    private func weeklyData(from filtered: [Expense]) -> [(String, Double)] {
        let calendar = mondayCalendar
        let today = Date()
        guard let week = calendar.dateInterval(of: .weekOfYear, for: today) else { return [] }
        let start = week.start
        return (0..<7).map { idx in
            let date = calendar.date(byAdding: .day, value: idx, to: start) ?? start
            let total = filtered
                .filter { calendar.isDate($0.date, inSameDayAs: date) }
                .reduce(0) { $0 + $1.amount }
            return (Self.weekdayFormatter(locale: localization.locale).string(from: date).uppercased(), total)
        }
    }

    private func monthlyByWeek(from filtered: [Expense]) -> [(String, Double)] {
        let calendar = mondayCalendar
        let now = Date()
        guard let month = calendar.dateInterval(of: .month, for: now) else { return [] }
        var cursor = month.start
        var result: [(String, Double)] = []
        var weekIndex = 1
        while cursor < month.end {
            guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: cursor) else { break }
            let start = max(weekInterval.start, month.start)
            let end = min(weekInterval.end, month.end)
            let total = filtered
                .filter { $0.date >= start && $0.date < end }
                .reduce(0) { $0 + $1.amount }
            result.append((L10n.Analytics.weekShort(weekIndex), total))
            weekIndex += 1
            cursor = end
        }
        return result
    }

    private func byMonthInYear(from filtered: [Expense]) -> [(String, Double)] {
        let calendar = mondayCalendar
        let now = Date()
        let year = calendar.component(.year, from: now)
        var result: [(String, Double)] = []
        for month in 1...12 {
            var comps = DateComponents()
            comps.year = year
            comps.month = month
            comps.day = 1
            let date = calendar.date(from: comps) ?? now
            let total = filtered
                .filter { calendar.isDate($0.date, equalTo: date, toGranularity: .month) }
                .reduce(0) { $0 + $1.amount }
            let raw = Self.monthShortFormatter(locale: localization.locale).string(from: date)
            let label = raw.replacingOccurrences(of: ".", with: "").capitalized
            result.append((label, total))
        }
        return result
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

    private static func weekdayFormatter(locale: Locale) -> DateFormatter {
        let f = DateFormatter()
        f.locale = locale
        f.dateFormat = "EEEEE"
        return f
    }

    private static func monthShortFormatter(locale: Locale) -> DateFormatter {
        let f = DateFormatter()
        f.locale = locale
        f.dateFormat = "LLL"
        return f
    }
}
