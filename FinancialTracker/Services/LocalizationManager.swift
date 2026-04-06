import Foundation
import SwiftUI
import ObjectiveC

enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case ru
    case en

    var id: String { rawValue }

    var localeIdentifier: String {
        switch self {
        case .ru: return "ru_RU"
        case .en: return "en_US"
        }
    }

    var displayName: String {
        switch self {
        case .ru: return "Русский"
        case .en: return "English"
        }
    }
}

final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published private(set) var language: AppLanguage

    var locale: Locale { Locale(identifier: language.localeIdentifier) }

    private let key = "app_language_override"

    private init() {
        if let raw = UserDefaults.standard.string(forKey: key),
           let lang = AppLanguage(rawValue: raw) {
            language = lang
        } else {
            language = .en
        }
        Bundle.setLanguage(language.rawValue)
    }

    func setLanguage(_ newValue: AppLanguage) {
        guard newValue != language else { return }
        language = newValue
        UserDefaults.standard.set(newValue.rawValue, forKey: key)
        Bundle.setLanguage(newValue.rawValue)
        objectWillChange.send()
    }
}

private final class LocalizedBundle: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        guard let lang = objc_getAssociatedObject(self, &Bundle.associatedLanguageKey) as? String,
              let path = Bundle.main.path(forResource: lang, ofType: "lproj"),
              let bundle = Bundle(path: path)
        else {
            return super.localizedString(forKey: key, value: value, table: tableName)
        }
        return bundle.localizedString(forKey: key, value: value, table: tableName)
    }
}

extension Bundle {
    fileprivate static var associatedLanguageKey: UInt8 = 0

    static func setLanguage(_ language: String) {
        objc_setAssociatedObject(Bundle.main, &associatedLanguageKey, language, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        object_setClass(Bundle.main, LocalizedBundle.self)
    }
}

