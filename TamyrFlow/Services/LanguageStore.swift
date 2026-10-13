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

    var bundleCode: String { rawValue }
}

@MainActor
final class LanguageStore: ObservableObject {
    static let defaultsKey = "tamyrflow.app.language"

    @Published private(set) var code: AppLanguageCode {
        didSet { apply(code) }
    }

    var bundle: Bundle {
        if let path = Bundle.main.path(forResource: code.bundleCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        return .main
    }

    init() {
        if let saved = UserDefaults.standard.string(forKey: Self.defaultsKey),
           let code = AppLanguageCode(rawValue: saved) {
            self.code = code
        } else {
            let preferred = Locale.preferredLanguages.first ?? "ru"
            if preferred.hasPrefix("kk") {
                self.code = .kk
            } else if preferred.hasPrefix("en") {
                self.code = .en
            } else {
                self.code = .ru
            }
        }
        apply(code)
    }

    func set(_ code: AppLanguageCode) {
        guard self.code != code else { return }
        self.code = code
    }

    private func apply(_ code: AppLanguageCode) {
        UserDefaults.standard.set(code.rawValue, forKey: Self.defaultsKey)
        UserDefaults.standard.set([code.bundleCode], forKey: "AppleLanguages")
        LanguageStoreBootstrap.bundle = bundle
        objectWillChange.send()
    }
}
