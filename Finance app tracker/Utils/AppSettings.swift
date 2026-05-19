//
//  AppSettings.swift
//  Finance app tracker
//

import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var appearance: AppAppearance {
        didSet { UserDefaults.standard.set(appearance.rawValue, forKey: Keys.appearance) }
    }

    @Published var biometricsEnabled: Bool {
        didSet { UserDefaults.standard.set(biometricsEnabled, forKey: Keys.biometricsEnabled) }
    }

    @Published var billRemindersEnabled: Bool {
        didSet { UserDefaults.standard.set(billRemindersEnabled, forKey: Keys.billRemindersEnabled) }
    }

    @Published var budgetAlertsEnabled: Bool {
        didSet { UserDefaults.standard.set(budgetAlertsEnabled, forKey: Keys.budgetAlertsEnabled) }
    }

    @Published var weeklyRemindersEnabled: Bool {
        didSet { UserDefaults.standard.set(weeklyRemindersEnabled, forKey: Keys.weeklyRemindersEnabled) }
    }

    private enum Keys {
        static let appearance = "app_appearance"
        static let biometricsEnabled = "biometrics_enabled"
        static let billRemindersEnabled = "bill_reminders_enabled"
        static let budgetAlertsEnabled = "budget_alerts_enabled"
        static let weeklyRemindersEnabled = "weekly_reminders_enabled"
    }

    private init() {
        let defaults = UserDefaults.standard
        appearance = AppAppearance(rawValue: defaults.string(forKey: Keys.appearance) ?? "") ?? .system
        biometricsEnabled = defaults.object(forKey: Keys.biometricsEnabled) as? Bool ?? true
        billRemindersEnabled = defaults.object(forKey: Keys.billRemindersEnabled) as? Bool ?? false
        budgetAlertsEnabled = defaults.object(forKey: Keys.budgetAlertsEnabled) as? Bool ?? true
        weeklyRemindersEnabled = defaults.object(forKey: Keys.weeklyRemindersEnabled) as? Bool ?? false
    }
}
