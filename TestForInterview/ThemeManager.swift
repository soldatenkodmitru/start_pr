//
//  ThemeManager.swift
//  TestForInterview
//
//  Created by Dmytro Soldatenko on 11.09.2025.
//

import UIKit

enum ThemeSetting: Int { case light = 0, dark = 1 }

enum ThemeManager {
    private static let key = "selectedTheme"

    static var current: ThemeSetting {
        if let saved = UserDefaults.standard.value(forKey: key) as? Int,
           let t = ThemeSetting(rawValue: saved) {
            return t
        }
        return .light // default if nothing saved
    }

    static func apply(to window: UIWindow?) {
        guard let window else { return }
        switch current {
        case .light: window.overrideUserInterfaceStyle = .light
        case .dark:  window.overrideUserInterfaceStyle = .dark
        }
    }

    static func set(_ theme: ThemeSetting, for window: UIWindow?) {
        UserDefaults.standard.set(theme.rawValue, forKey: key)
        apply(to: window)
    }

    /// Convenience to locate the key window on iOS 13+
    static var keyWindow: UIWindow? {
        UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}
