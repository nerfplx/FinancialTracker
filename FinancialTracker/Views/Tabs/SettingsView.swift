import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var vm: SmartSpendViewModel
    @EnvironmentObject private var localization: LocalizationManager
    @FocusState private var focusedField: Field?
    
    @State private var incomeText = ""
    @State private var limitText = ""
    @State private var dailyLimitText = ""
    @State private var currency = "$"
    @State private var autoRecalc = true
    @State private var customDailyLimit = false
    
    @State private var notifyDailyOverrun = false
    @State private var notifyDailySummary = false
    @State private var notifyImpulse = false
    
    @State private var hasChanges = false
    @State private var isLoading = false
    @State private var showResetOnboardingConfirm = false
    @State private var showDeleteDataConfirm = false

    private static let incomeFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        f.usesGroupingSeparator = false
        return f
    }()
    
    private enum Field {
        case income
        case monthlyLimit
        case dailyLimit
    }
    
    private var parsedIncome: Double { vm.parseAmount(incomeText) ?? 0 }
    private var parsedMonthlyLimit: Double { vm.parseAmount(limitText) ?? 0 }
    private var parsedDailyLimit: Double? { vm.parseAmount(dailyLimitText) }
    
    private var recommendedLimit: String {
        vm.format(vm.recommendedMonthlyLimit(for: parsedIncome))
    }
    
    private var limitValidation: String? {
        if parsedMonthlyLimit < 100 {
            return L10n.Settings.validationMonthMin(currency: currency)
        }
        if parsedIncome > 0 && parsedMonthlyLimit > parsedIncome {
            return L10n.Settings.validationLimitOverIncome
        }
        if customDailyLimit, let daily = parsedDailyLimit, daily < 10 {
            return L10n.Settings.validationDayMin(currency: currency)
        }
        return nil
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        focusedField = nil
                        dismissKeyboard()
                    }
                
                Form {
                    Section(L10n.Settings.incomeSection) {
                        HStack {
                            TextField(L10n.Settings.incomeField, text: $incomeText)
                                .keyboardType(.decimalPad)
                                .focused($focusedField, equals: .income)
                                .onChange(of: incomeText) { newValue in
                                    guard !isLoading else { return }
                                    let sanitized = vm.sanitizedAmount(newValue)
                                    if sanitized != newValue {
                                        incomeText = sanitized
                                    }
                                    hasChanges = true
                                }
                            Text(currency).foregroundColor(.secondary)
                        }
                        
                        Toggle(L10n.Settings.recalcToggle, isOn: $autoRecalc)
                            .onChange(of: autoRecalc) { newValue in
                                guard !isLoading else { return }
                                if newValue {
                                    let recommended = vm.recommendedMonthlyLimit(for: parsedIncome)
                                    limitText = String(Int(recommended))
                                }
                                hasChanges = true
                            }
                        
                        Text(L10n.Settings.recommended(recommendedLimit))
                            .foregroundColor(.secondary)
                        
                    }
                    
                    Section(L10n.Settings.limitsSection) {
                        TextField(L10n.Settings.monthlyLimitField, text: $limitText)
                            .keyboardType(.numberPad)
                            .disabled(autoRecalc)
                            .focused($focusedField, equals: .monthlyLimit)
                            .onChange(of: limitText) { newValue in
                                guard !isLoading else { return }
                                let sanitized = vm.sanitizedDigits(newValue)
                                if sanitized != newValue {
                                    limitText = sanitized
                                }
                                hasChanges = true
                            }
                        
                        Toggle(L10n.Settings.dailyManualToggle, isOn: $customDailyLimit)
                            .onChange(of: customDailyLimit) { _ in
                                guard !isLoading else { return }
                                hasChanges = true
                            }
                        
                        if customDailyLimit {
                            TextField(L10n.Settings.dailyLimitField, text: $dailyLimitText)
                                .keyboardType(.numberPad)
                                .focused($focusedField, equals: .dailyLimit)
                                .onChange(of: dailyLimitText) { newValue in
                                    guard !isLoading else { return }
                                    let sanitized = vm.sanitizedDigits(newValue)
                                    if sanitized != newValue {
                                        dailyLimitText = sanitized
                                    }
                                    hasChanges = true
                                }
                        } else {
                            Text(L10n.Settings.dailyLimitValue(vm.format(vm.profile.dailyLimit)))
                                .foregroundColor(.secondary)
                        }
                        
                        if let warning = limitValidation {
                            Text(warning)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    Section(L10n.Settings.currencySection) {
                        Picker(L10n.Settings.currencyPicker, selection: $currency) {
                            Text("€").tag("€")
                            Text("$").tag("$")
                            Text("₽").tag("₽")
                        }
                        .pickerStyle(.segmented)
                        .padding(.vertical, 4)
                        .listRowBackground(Color(.secondarySystemBackground))
                        .onChange(of: currency) { _ in
                            guard !isLoading else { return }
                            hasChanges = true
                        }
                    }
                    
                    Section(L10n.Settings.notificationsSection) {
                        Toggle(L10n.Settings.notifyOverrun, isOn: $notifyDailyOverrun)
                            .onChange(of: notifyDailyOverrun) { _ in
                                guard !isLoading else { return }
                                hasChanges = true
                            }
                        Toggle(L10n.Settings.notifySummary, isOn: $notifyDailySummary)
                            .onChange(of: notifyDailySummary) { _ in
                                guard !isLoading else { return }
                                hasChanges = true
                            }
                        Toggle(L10n.Settings.notifyImpulse, isOn: $notifyImpulse)
                            .onChange(of: notifyImpulse) { _ in
                                guard !isLoading else { return }
                                hasChanges = true
                            }
                    }

                    Section(L10n.Settings.onboardingSection) {
                        Button(L10n.Settings.resetOnboarding, role: .destructive) {
                            focusedField = nil
                            dismissKeyboard()
                            showResetOnboardingConfirm = true
                        }
                    }
                    
                    Section(L10n.Settings.dataSection) {
                        Button(L10n.Settings.deleteAll, role: .destructive) {
                            focusedField = nil
                            dismissKeyboard()
                            showDeleteDataConfirm = true
                        }
                    }
                }
            }
            .navigationTitle(L10n.Titles.settings)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if hasChanges {
                        Button(L10n.Common.save) { saveChanges() }
                            .bold()
                            .disabled(limitValidation != nil)
                    }

                    Menu {
                        ForEach(AppLanguage.allCases) { lang in
                            Button {
                                localization.setLanguage(lang)
                            } label: {
                                if localization.language == lang {
                                    Label(lang.displayName, systemImage: "checkmark")
                                } else {
                                    Text(lang.displayName)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "globe")
                    }
                    .accessibilityLabel(L10n.Settings.languagePicker)
                }
            }
            .confirmationDialog(L10n.Settings.confirmReset, isPresented: $showResetOnboardingConfirm) {
                Button(L10n.Common.reset, role: .destructive) {
                    vm.resetOnboarding()
                }
                Button(L10n.Common.cancel, role: .cancel) {}
            }
            .confirmationDialog(L10n.Settings.confirmDelete, isPresented: $showDeleteDataConfirm) {
                Button(L10n.Common.delete, role: .destructive) {
                    vm.deleteAllExpenses()
                }
                Button(L10n.Common.cancel, role: .cancel) {}
            }
            .onAppear {
                isLoading = true
                if vm.profile.monthlyIncome == 0 {
                    incomeText = ""
                } else {
                    incomeText = Self.incomeFormatter.string(from: NSNumber(value: vm.profile.monthlyIncome))
                        ?? vm.sanitizedAmount(String(vm.profile.monthlyIncome))
                }
                limitText = String(Int(vm.profile.monthlyLimit))
                dailyLimitText = String(Int(vm.profile.dailyLimit))
                currency = vm.profile.currency
                autoRecalc = vm.profile.autoRecalculateLimit
                customDailyLimit = vm.profile.usesCustomDailyLimit
                
                notifyDailyOverrun = vm.notificationSettings.notifyDailyOverrun
                notifyDailySummary = vm.notificationSettings.notifyDailySummary
                notifyImpulse = vm.notificationSettings.notifyImpulse
                isLoading = false
                hasChanges = false
            }
        }
    }
    
    private func saveChanges() {
        focusedField = nil
        dismissKeyboard()
        vm.updateSettings(
            income: max(parsedIncome, 1),
            monthlyLimit: max(parsedMonthlyLimit, 100),
            dailyLimit: parsedDailyLimit,
            useCustomDailyLimit: customDailyLimit,
            autoRecalculateLimit: autoRecalc,
            currency: currency
        )
        vm.updateNotificationSettings(
            NotificationSettings(
                notifyDailyOverrun: notifyDailyOverrun,
                notifyDailySummary: notifyDailySummary,
                notifyImpulse: notifyImpulse
            )
        )
        hasChanges = false
    }
}
