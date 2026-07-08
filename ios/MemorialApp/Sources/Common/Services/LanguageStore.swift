import SwiftUI

enum AppLanguage: String, CaseIterable {
    case en = "en"
    case zh = "zh"

    var label: String {
        switch self {
        case .en: return "English"
        case .zh: return "中文"
        }
    }
}

@MainActor
final class LanguageStore: ObservableObject {
    @Published private(set) var language: AppLanguage

    private static let key = "app_language"

    init() {
        let saved = UserDefaults.standard.string(forKey: Self.key)
        language = AppLanguage(rawValue: saved ?? "") ?? .en
    }

    func set(_ lang: AppLanguage) {
        language = lang
        UserDefaults.standard.set(lang.rawValue, forKey: Self.key)
    }

    var strings: Strings { Strings(language) }
}
