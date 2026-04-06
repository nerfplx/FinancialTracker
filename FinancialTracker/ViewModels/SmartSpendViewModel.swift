import Foundation
import UIKit
import UserNotifications

final class SmartSpendViewModel: ObservableObject {
    @Published var profile: UserProfile = .empty
    @Published var expenses: [Expense] = [] {
        didSet {
            recalculateDerivedData()
            if !isHydrating {
                expenseStore.saveDebounced(expenses)
            }
        }
    }
    @Published var hasCompletedOnboarding = false
    @Published var notificationSettings: NotificationSettings = .default

    @Published private(set) var todaySpent: Double = 0
    @Published private(set) var monthSpent: Double = 0
    @Published private(set) var todayExpenses: [Expense] = []
    @Published private(set) var categorySpend: [(ExpenseCategory, Double)] = []

    private let profileKey = "profile_key"
    private let onboardingKey = "onboarding_key"
    private let notificationKey = "notification_key"
    private let expenseStore = ExpenseStore()
    private let advisor = BudgetAdvisor()
    private var isHydrating = false
    private var dayChangeObserver: NSObjectProtocol?
    private var minuteTimer: Timer?
    private let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    init() {
        load()
        setupDayRefreshObservers()
        requestNotificationPermission()
        applyNotificationSettings()
    }

    deinit {
        if let observer = dayChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        minuteTimer?.invalidate()
    }

    var availableBalance: Double {
        max(profile.monthlyLimit - monthSpent, 0)
    }

    var todayOverrunPercent: Double {
        guard profile.dailyLimit > 0 else { return 0 }
        return max(((todaySpent - profile.dailyLimit) / profile.dailyLimit) * 100, 0)
    }

    var dailySummary: DailySummary {
        let impulse = todayExpenses.filter(\.isImpulse).reduce(0) { $0 + $1.amount }
        return DailySummary(total: todaySpent, impulse: impulse)
    }

    func onboardingFinish(income: Double, goal: SpendGoal) {
        profile.monthlyIncome = income
        profile.goal = goal
        profile.autoRecalculateLimit = true
        profile.usesCustomDailyLimit = false
        profile.monthlyLimit = BudgetCalculator.monthlyLimit(from: income, goal: goal)
        profile.dailyLimit = BudgetCalculator.dailyLimit(from: profile.monthlyLimit)
        hasCompletedOnboarding = true
        save()
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
        save()
    }

    func aiAdvice(for amount: Double, category: ExpenseCategory) -> String {
        advisor.advice(
            amount: amount,
            category: category,
            todayExpenses: todayExpenses,
            todaySpent: todaySpent,
            dailyLimit: profile.dailyLimit,
            formattedAmount: format
        )
    }

    func aiSeverity(for amount: Double, category: ExpenseCategory) -> AdviceSeverity {
        let alreadyToday = todayExpenses.filter { $0.category == category }.reduce(0) { $0 + $1.amount }
        let projected = todaySpent + amount
        if amount > profile.dailyLimit * 0.7 {
            return .high
        }
        if projected > profile.dailyLimit || alreadyToday > 0 {
            return .medium
        }
        return .normal
    }

    func addExpense(amount: Double, category: ExpenseCategory, note: String, isImpulse: Bool) {
        let projectedTodaySpent = todaySpent + amount
        let item = Expense(
            id: UUID(),
            amount: amount,
            category: category,
            note: note,
            date: Date(),
            isImpulse: isImpulse
        )
        expenses.insert(item, at: 0)
        triggerSmartAlerts(projectedTodaySpent: projectedTodaySpent, isImpulse: isImpulse)
    }

    func deleteExpense(id: UUID) {
        expenses.removeAll { $0.id == id }
    }

    func deleteAllExpenses() {
        expenses = []
    }

    func updateExpense(id: UUID, amount: Double, category: ExpenseCategory, note: String, isImpulse: Bool) {
        guard let index = expenses.firstIndex(where: { $0.id == id }) else { return }
        let previous = expenses[index]
        let updated = Expense(
            id: previous.id,
            amount: amount,
            category: category,
            note: note,
            date: previous.date,
            isImpulse: isImpulse
        )
        expenses[index] = updated
    }

    func updateSettings(
        income: Double,
        monthlyLimit: Double,
        dailyLimit: Double?,
        useCustomDailyLimit: Bool,
        autoRecalculateLimit: Bool,
        currency: String
    ) {
        profile.monthlyIncome = income
        profile.currency = currency
        profile.autoRecalculateLimit = autoRecalculateLimit
        profile.usesCustomDailyLimit = useCustomDailyLimit

        if autoRecalculateLimit {
            profile.monthlyLimit = BudgetCalculator.monthlyLimit(from: income, goal: profile.goal)
        } else {
            profile.monthlyLimit = monthlyLimit
        }

        if useCustomDailyLimit {
            profile.dailyLimit = max(dailyLimit ?? BudgetCalculator.dailyLimit(from: profile.monthlyLimit), 10)
        } else {
            profile.dailyLimit = BudgetCalculator.dailyLimit(from: profile.monthlyLimit)
        }
        save()
    }

    func updateNotificationSettings(_ settings: NotificationSettings) {
        notificationSettings = settings
        saveNotifications()
        applyNotificationSettings()
    }

    func recommendedMonthlyLimit(for income: Double) -> Double {
        BudgetCalculator.monthlyLimit(from: income, goal: profile.goal)
    }

    func sanitizedAmount(_ text: String) -> String {
        let separator = Locale.current.decimalSeparator ?? "."
        var hasSeparator = false

        return text.filter { char in
            if char.isNumber { return true }
            if String(char) == separator && !hasSeparator {
                hasSeparator = true
                return true
            }
            return false
        }
    }

    func sanitizedDigits(_ text: String) -> String {
        text.filter(\.isNumber)
    }

    func parseAmount(_ text: String) -> Double? {
        let normalized = text.replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }

    func format(_ value: Double) -> String {
        let number = formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
        return "\(number)\(profile.currency)"
    }

    private func load() {
        let defaults = UserDefaults.standard
        if let profileData = defaults.data(forKey: profileKey),
           let decoded = try? JSONDecoder().decode(UserProfile.self, from: profileData) {
            profile = decoded
        }
        hasCompletedOnboarding = defaults.bool(forKey: onboardingKey)

        if let notificationData = defaults.data(forKey: notificationKey),
           let decoded = try? JSONDecoder().decode(NotificationSettings.self, from: notificationData) {
            notificationSettings = decoded
        }

        isHydrating = true
        expenseStore.loadAsync { [weak self] loadedExpenses in
            guard let self else { return }
            self.expenses = loadedExpenses
            self.isHydrating = false
        }
    }

    private func save() {
        let defaults = UserDefaults.standard
        if let profileData = try? JSONEncoder().encode(profile) {
            defaults.set(profileData, forKey: profileKey)
        }
        defaults.set(hasCompletedOnboarding, forKey: onboardingKey)
    }

    private func saveNotifications() {
        let defaults = UserDefaults.standard
        if let notificationData = try? JSONEncoder().encode(notificationSettings) {
            defaults.set(notificationData, forKey: notificationKey)
        }
    }

    private func recalculateDerivedData() {
        let calendar = Calendar.current
        let now = Date()
        todayExpenses = expenses.filter { calendar.isDate($0.date, inSameDayAs: now) }
        todaySpent = todayExpenses.reduce(0) { $0 + $1.amount }
        monthSpent = expenses
            .filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
        categorySpend = Dictionary(grouping: expenses, by: { $0.category })
            .map { ($0.key, $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.1 > $1.1 }
    }

    private func setupDayRefreshObservers() {
        dayChangeObserver = NotificationCenter.default.addObserver(
            forName: .NSCalendarDayChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.recalculateDerivedData()
        }

        let timer = Timer(timeInterval: 60, repeats: true) { [weak self] _ in
            self?.recalculateDerivedData()
        }
        RunLoop.main.add(timer, forMode: .common)
        minuteTimer = timer
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    private func applyNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            guard let self, settings.authorizationStatus == .authorized else { return }
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: ["daily_summary_21"])
            if self.notificationSettings.notifyDailySummary {
                let content = UNMutableNotificationContent()
                content.title = L10n.Notifications.dailySummaryTitle
                content.body = L10n.Notifications.dailySummaryBody
                content.sound = .default

                var dateComponents = DateComponents()
                dateComponents.hour = 21
                dateComponents.minute = 0
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let request = UNNotificationRequest(
                    identifier: "daily_summary_21",
                    content: content,
                    trigger: trigger
                )
                center.add(request)
            }
        }
    }

    private func triggerSmartAlerts(projectedTodaySpent: Double, isImpulse: Bool) {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            guard let self, settings.authorizationStatus == .authorized else { return }
            if self.notificationSettings.notifyDailyOverrun && projectedTodaySpent > self.profile.dailyLimit {
                self.sendImmediateNotification(
                    identifier: "daily_overrun_\(UUID().uuidString)",
                    title: L10n.Notifications.overrunTitle,
                    body: L10n.Notifications.overrunBody
                )
            }
            if self.notificationSettings.notifyImpulse && isImpulse {
                self.sendImmediateNotification(
                    identifier: "impulse_\(UUID().uuidString)",
                    title: L10n.Notifications.impulseTitle,
                    body: L10n.Notifications.impulseBody
                )
            }
        }
    }

    private func sendImmediateNotification(identifier: String, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}

enum AdviceSeverity {
    case normal
    case medium
    case high
}
