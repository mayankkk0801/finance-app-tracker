//
//  Finance_app_trackerApp.swift
//  Finance app tracker
//

import SwiftUI
import CoreData

@main
struct Finance_app_trackerApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var settings = AppSettings.shared
    @StateObject private var transactionViewModel = TransactionViewModel()
    @StateObject private var budgetViewModel = BudgetViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(settings)
                .environmentObject(transactionViewModel)
                .environmentObject(budgetViewModel)
                .onAppear {
                    persistenceController.seedDefaultCategoriesIfNeeded()
                    configureNotifications()
                    wireViewModels()
                }
        }
    }

    private func wireViewModels() {
        transactionViewModel.onTransactionsChanged = {
            budgetViewModel.fetchBudgets()
        }
    }

    private func configureNotifications() {
        if settings.weeklyRemindersEnabled {
            NotificationManager.shared.scheduleWeeklyExpenseReminder()
        }
        if settings.billRemindersEnabled {
            BillReminderStore.shared.rescheduleAllNotifications()
        }
    }
}
