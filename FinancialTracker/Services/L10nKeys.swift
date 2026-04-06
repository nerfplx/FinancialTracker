import Foundation

enum L10n {
    static func tr(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }
    
    enum Tabs {
        static var today: String { tr("tab_today") }
        static var analytics: String { tr("tab_analytics") }
        static var add: String { tr("tab_add") }
        static var history: String { tr("tab_history") }
        static var settings: String { tr("tab_settings") }
    }
    
    enum Titles {
        static var dashboard: String { tr("title_dashboard") }
        static var analytics: String { tr("title_analytics") }
        static var addExpense: String { tr("title_add_expense") }
        static var history: String { tr("title_history") }
        static var settings: String { tr("title_settings") }
        static var editExpense: String { tr("title_edit_expense") }
    }
    
    enum Common {
        static var cancel: String { tr("common_cancel") }
        static var save: String { tr("common_save") }
        static var delete: String { tr("common_delete") }
        static var reset: String { tr("common_reset") }
        static var all: String { tr("common_all") }
        static var emptyNote: String { tr("common_empty_note") }
    }
    
    enum Goals {
        static var saveMore: String { tr("goal_save_more") }
        static var control: String { tr("goal_control") }
        static var saveMoreDesc: String { tr("goal_save_more_desc") }
        static var controlDesc: String { tr("goal_control_desc") }
    }
    
    enum Categories {
        static var food: String { tr("category_food") }
        static var transport: String { tr("category_transport") }
        static var shopping: String { tr("category_shopping") }
        static var entertainment: String { tr("category_entertainment") }
        static var health: String { tr("category_health") }
        static var subscriptions: String { tr("category_subscriptions") }
    }
    
    enum Onboarding {
        static var titleBudget: String { tr("onb_title_budget") }
        static var titleGoal: String { tr("onb_title_goal") }
        static var incomeLabel: String { tr("onb_income_label") }
        static var incomePlaceholder: String { tr("onb_income_placeholder") }
        static var next: String { tr("onb_next") }
        static var start: String { tr("onb_start") }
        static var hint: String { tr("onb_hint") }
    }
    
    enum Dashboard {
        static var sectionTodayExpenses: String { tr("dash_section_today_expenses") }
        static var noExpenses: String { tr("dash_no_expenses") }
        static var month: String { tr("dash_month") }
        static func daysLeft(_ value: Int) -> String { String(format: tr("dash_days_left_fmt"), value) }
        static var dailyLimit: String { tr("dash_daily_limit") }
        static func overrunPercent(_ value: Int) -> String { String(format: tr("dash_overrun_fmt"), value) }
        static func impulseSpent(_ formatted: String) -> String { String(format: tr("dash_impulse_spent_fmt"), formatted) }
        static var menuEdit: String { tr("dash_menu_edit") }
        static var menuDelete: String { tr("dash_menu_delete") }
    }
    
    enum AddExpense {
        static var amount: String { tr("add_amount") }
        static var category: String { tr("add_category") }
        static var note: String { tr("add_note") }
        static var impulseToggle: String { tr("add_impulse_toggle") }
        static var aiTitle: String { tr("add_ai_title") }
        static var save: String { tr("add_save") }
    }
    
    enum EditExpense {
        static var amount: String { tr("edit_amount") }
        static var category: String { tr("edit_category") }
        static var note: String { tr("edit_note") }
        static var impulseToggle: String { tr("edit_impulse_toggle") }
    }
    
    enum Analytics {
        static var period: String { tr("analytics_period") }
        static var week: String { tr("analytics_week") }
        static var month: String { tr("analytics_month") }
        static var year: String { tr("analytics_year") }
        
        static func periodYear(year: Int, count: Int) -> String { String(format: tr("analytics_period_year_fmt"), year, count) }
        static func periodMonth(_ monthTitle: String, count: Int) -> String { String(format: tr("analytics_period_month_fmt"), monthTitle, count) }
        static func periodWeekFallback(count: Int) -> String { String(format: tr("analytics_period_week_fallback_fmt"), count) }
        static func periodWeek(start: String, end: String, count: Int) -> String { String(format: tr("analytics_period_week_fmt"), start, end, count) }
        
        static var totalTitle: String { tr("analytics_total_title") }
        static func limitWeekPercent(_ value: Int) -> String { String(format: tr("analytics_limit_week_fmt"), value) }
        static func limitMonthPercent(_ value: Int) -> String { String(format: tr("analytics_limit_month_fmt"), value) }
        static func limitYearPercent(_ value: Int) -> String { String(format: tr("analytics_limit_year_fmt"), value) }
        
        static var categories: String { tr("analytics_categories") }
        static var impulseTitle: String { tr("analytics_impulse_title") }
        static func impulseValue(count: Int, totalFormatted: String) -> String { String(format: tr("analytics_impulse_value_fmt"), count, totalFormatted) }
        
        static var insights: String { tr("analytics_insights") }
        static var insightMostFrequent: String { tr("analytics_insight_most_frequent") }
        static var insightMostExpensive: String { tr("analytics_insight_most_expensive") }
        static var insightAvgPerDay: String { tr("analytics_insight_avg_per_day") }
        static var insightImpulseShare: String { tr("analytics_insight_impulse_share") }
        
        static var chartWeek: String { tr("analytics_chart_week") }
        static var chartMonth: String { tr("analytics_chart_month") }
        static var chartYear: String { tr("analytics_chart_year") }
        static func weekShort(_ index: Int) -> String { String(format: tr("analytics_week_short_fmt"), index) }
        
        static var emptyTitle: String { tr("analytics_empty_title") }
        static var emptySubtitle: String { tr("analytics_empty_subtitle") }
    }
    
    enum History {
        static var period: String { tr("history_period") }
        static var day: String { tr("history_day") }
        static var week: String { tr("history_week") }
        static var month: String { tr("history_month") }
        static var total: String { tr("history_total") }
        static var onlyImpulse: String { tr("history_only_impulse") }
        static func emptyDay(_ label: String) -> String { String(format: tr("history_empty_day_fmt"), label) }
        static var emptyWeek: String { tr("history_empty_week") }
    }
    
    enum Settings {
        static var incomeSection: String { tr("settings_income_section") }
        static var incomeField: String { tr("settings_income_field") }
        static var recalcToggle: String { tr("settings_recalc_toggle") }
        static func recommended(_ formatted: String) -> String { String(format: tr("settings_recommended_fmt"), formatted) }
        
        static var limitsSection: String { tr("settings_limits_section") }
        static var monthlyLimitField: String { tr("settings_monthly_limit_field") }
        static var dailyManualToggle: String { tr("settings_daily_manual_toggle") }
        static var dailyLimitField: String { tr("settings_daily_limit_field") }
        static func dailyLimitValue(_ formatted: String) -> String { String(format: tr("settings_daily_limit_value_fmt"), formatted) }
        
        static var currencySection: String { tr("settings_currency_section") }
        static var currencyPicker: String { tr("settings_currency_picker") }
        
        static var notificationsSection: String { tr("settings_notifications_section") }
        static var notifyOverrun: String { tr("settings_notify_overrun") }
        static var notifySummary: String { tr("settings_notify_summary") }
        static var notifyImpulse: String { tr("settings_notify_impulse") }
        
        static var onboardingSection: String { tr("settings_onboarding_section") }
        static var resetOnboarding: String { tr("settings_reset_onboarding") }
        static var dataSection: String { tr("settings_data_section") }
        static var deleteAll: String { tr("settings_delete_all") }
        
        static var confirmReset: String { tr("settings_confirm_reset") }
        static var confirmDelete: String { tr("settings_confirm_delete") }
        
        static func validationMonthMin(currency: String) -> String { String(format: tr("settings_validation_month_min_fmt"), currency) }
        static var validationLimitOverIncome: String { tr("settings_validation_limit_over_income") }
        static func validationDayMin(currency: String) -> String { String(format: tr("settings_validation_day_min_fmt"), currency) }
        
        static var languagePicker: String { tr("settings_language_picker") }
    }
    
    enum Advisor {
        static var noLimit: String { tr("advisor_no_limit") }
        static var largePurchase: String { tr("advisor_large_purchase") }
        static func alreadyToday(_ formatted: String, overrunPercent: Int) -> String {
            String(format: tr("advisor_already_today_fmt"), formatted, overrunPercent)
        }
        static func overLimit(overrunPercent: Int) -> String {
            String(format: tr("advisor_over_limit_fmt"), overrunPercent)
        }
        static var ok: String { tr("advisor_ok") }
    }
    
    enum Notifications {
        static var dailySummaryTitle: String { tr("notif_daily_summary_title") }
        static var dailySummaryBody: String { tr("notif_daily_summary_body") }
        static var overrunTitle: String { tr("notif_overrun_title") }
        static var overrunBody: String { tr("notif_overrun_body") }
        static var impulseTitle: String { tr("notif_impulse_title") }
        static var impulseBody: String { tr("notif_impulse_body") }
    }
}

