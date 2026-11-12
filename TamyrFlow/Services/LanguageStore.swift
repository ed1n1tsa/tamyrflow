import Combine
import Foundation
import SwiftUI

enum AppLanguageCode: String, CaseIterable, Identifiable {
    case kk
    case ru
    case en

    var id: String { rawValue }

    var shortLabel: String {
        switch self {
        case .kk: return "KZ"
        case .ru: return "RU"
        case .en: return "ENG"
        }
    }

    /// Always native — not localized — so the language picker is readable in any UI language.
    var nativeName: String {
        switch self {
        case .kk: return "Қазақша"
        case .ru: return "Русский"
        case .en: return "English"
        }
    }

    var bundleCode: String { rawValue }
}

@MainActor
final class LanguageStore: ObservableObject {
    static let defaultsKey = "tamyrflow.app.language"

    @Published private(set) var code: AppLanguageCode
    /// Bumped on every successful language change so views that ignore `code` still refresh.
    @Published private(set) var revision: Int = 0

    var bundle: Bundle {
        Self.bundle(for: code)
    }

    init() {
        let initial: AppLanguageCode
        if let saved = UserDefaults.standard.string(forKey: Self.defaultsKey),
           let code = AppLanguageCode(rawValue: saved) {
            initial = code
        } else {
            let preferred = Locale.preferredLanguages.first ?? "ru"
            if preferred.hasPrefix("kk") {
                initial = .kk
            } else if preferred.hasPrefix("en") {
                initial = .en
            } else {
                initial = .ru
            }
        }
        self.code = initial
        apply(initial, bumpRevision: false)
    }

    func set(_ code: AppLanguageCode) {
        guard self.code != code else { return }
        self.code = code
        apply(code, bumpRevision: true)
    }

    private func apply(_ code: AppLanguageCode, bumpRevision: Bool) {
        UserDefaults.standard.set(code.rawValue, forKey: Self.defaultsKey)
        UserDefaults.standard.set([code.bundleCode], forKey: "AppleLanguages")
        LanguageStoreBootstrap.bundle = Self.bundle(for: code)
        if bumpRevision {
            revision &+= 1
        }
        objectWillChange.send()
    }

    private static func bundle(for code: AppLanguageCode) -> Bundle {
        if let path = Bundle.main.path(forResource: code.bundleCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        return .main
    }
}
