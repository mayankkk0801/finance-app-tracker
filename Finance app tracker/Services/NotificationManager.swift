//
//  NotificationManager.swift
//  Finance app tracker
//

import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    private init() {}

    func requestPermission(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
            DispatchQueue.main.async {
                completion?(granted)
            }
        }
    }

    func scheduleBillReminder(id: String, title: String, amount: Double, dueDate: Date) {
        guard dueDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Bill Reminder"
        content.body = "\(title) is due — \(amount.formatted(.currency(code: CurrencyFormatter.code)))"
        content.sound = .default

        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
        if components.hour == nil { components.hour = 9 }
        if components.minute == nil { components.minute = 0 }

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling bill reminder: \(error)")
            }
        }
    }

    func scheduleWeeklyExpenseReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Weekly Expense Check"
        content.body = "Review expenses for this week."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.weekday = 1
        dateComponents.hour = 18

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "weekly-reminder", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    func removeWeeklyExpenseReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["weekly-reminder"])
    }

    func scheduleBudgetWarning(budgetName: String, spent: Double, limit: Double, budgetID: UUID) {
        guard spent >= limit * 0.8 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Budget Alert"

        if spent >= limit {
            content.body = "You've exceeded your \(budgetName) budget. Spent: \(spent.formatted(.currency(code: CurrencyFormatter.code)))"
        } else {
            let percentage = Int((spent / limit) * 100)
            content.body = "You've used \(percentage)% of your \(budgetName) budget."
        }

        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "budget-warning-\(budgetID.uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}
