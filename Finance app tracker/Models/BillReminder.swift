//
//  BillReminder.swift
//  Finance app tracker
//

import Foundation
import UserNotifications

struct BillReminder: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var amount: Double
    var dueDate: Date
    var isEnabled: Bool

    init(id: UUID = UUID(), title: String, amount: Double, dueDate: Date, isEnabled: Bool = true) {
        self.id = id
        self.title = title
        self.amount = amount
        self.dueDate = dueDate
        self.isEnabled = isEnabled
    }
}

@MainActor
final class BillReminderStore: ObservableObject {
    static let shared = BillReminderStore()

    @Published private(set) var reminders: [BillReminder] = []

    private let storageKey = "bill_reminders"

    private init() {
        load()
    }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([BillReminder].self, from: data) else {
            reminders = []
            return
        }
        reminders = decoded.sorted { $0.dueDate < $1.dueDate }
    }

    func save(_ reminder: BillReminder) {
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[index] = reminder
        } else {
            reminders.append(reminder)
        }
        persist()
        rescheduleNotificationsIfNeeded()
    }

    func delete(_ reminder: BillReminder) {
        reminders.removeAll { $0.id == reminder.id }
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [notificationID(for: reminder.id)]
        )
        persist()
    }

    func rescheduleAllNotifications() {
        for reminder in reminders {
            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers: [notificationID(for: reminder.id)]
            )
        }
        let enabled = UserDefaults.standard.object(forKey: "bill_reminders_enabled") as? Bool ?? false
        guard enabled else { return }
        for reminder in reminders where reminder.isEnabled {
            NotificationManager.shared.scheduleBillReminder(
                id: notificationID(for: reminder.id),
                title: reminder.title,
                amount: reminder.amount,
                dueDate: reminder.dueDate
            )
        }
    }

    private func rescheduleNotificationsIfNeeded() {
        let enabled = UserDefaults.standard.object(forKey: "bill_reminders_enabled") as? Bool ?? false
        guard enabled else { return }
        rescheduleAllNotifications()
    }

    private func notificationID(for id: UUID) -> String {
        "bill-reminder-\(id.uuidString)"
    }

    private func persist() {
        reminders.sort { $0.dueDate < $1.dueDate }
        if let data = try? JSONEncoder().encode(reminders) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
