//
//  BudgetViewModel.swift
//  Finance app tracker
//

import Foundation
import CoreData
import Combine

class BudgetViewModel: ObservableObject {
    @Published var budgets: [Budget] = []
    @Published var categories: [Category] = []

    private let persistenceController = PersistenceController.shared
    private static var warnedBudgetIDs = Set<String>()

    init() {
        fetchBudgets()
        fetchCategories()
    }

    func fetchBudgets() {
        let request: NSFetchRequest<Budget> = Budget.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Budget.name, ascending: true)]

        do {
            budgets = try persistenceController.container.viewContext.fetch(request)
            updateBudgetSpending()
        } catch {
            print("Error fetching budgets: \(error)")
        }
    }

    func fetchCategories() {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Category.name, ascending: true)]

        do {
            categories = try persistenceController.container.viewContext.fetch(request)
        } catch {
            print("Error fetching categories: \(error)")
        }
    }

    func addBudget(name: String, amount: Double, categoryID: UUID, month: Int, year: Int) {
        let context = persistenceController.container.viewContext
        let budget = Budget(context: context)

        budget.id = UUID()
        budget.name = name
        budget.amount = amount
        budget.categoryID = categoryID
        budget.month = Int16(month)
        budget.year = Int16(year)
        budget.spent = 0
        budget.createdAt = Date()

        persistenceController.save()
        fetchBudgets()
        HapticManager.shared.successNotification()
    }

    func updateBudget(_ budget: Budget, name: String, amount: Double, categoryID: UUID) {
        budget.name = name
        budget.amount = amount
        budget.categoryID = categoryID

        persistenceController.save()
        fetchBudgets()
        HapticManager.shared.lightImpact()
    }

    func deleteBudget(_ budget: Budget) {
        let context = persistenceController.container.viewContext
        context.delete(budget)
        persistenceController.save()
        fetchBudgets()
        HapticManager.shared.mediumImpact()
    }

    private func updateBudgetSpending() {
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)

        for budget in budgets {
            if Int(budget.month) == currentMonth && Int(budget.year) == currentYear {
                guard let categoryID = budget.categoryID else { continue }
                let spent = getSpentAmountForCategory(
                    categoryID: categoryID,
                    month: currentMonth,
                    year: currentYear
                )
                budget.spent = spent
                checkBudgetAlerts(for: budget)
            }
        }

        persistenceController.save()
    }

    static func notifyBudgetChecksIfNeeded() {
        let enabled = UserDefaults.standard.object(forKey: "budget_alerts_enabled") as? Bool ?? true
        guard enabled else { return }
        BudgetViewModel().fetchBudgets()
    }

    private func checkBudgetAlerts(for budget: Budget) {
        let alertsEnabled = UserDefaults.standard.object(forKey: "budget_alerts_enabled") as? Bool ?? true
        guard alertsEnabled,
              let budgetID = budget.id,
              budget.amount > 0 else { return }

        let key = budgetID.uuidString
        let progress = getBudgetProgress(budget)
        guard progress >= 0.8 else { return }
        guard !Self.warnedBudgetIDs.contains(key) else { return }

        Self.warnedBudgetIDs.insert(key)
        NotificationManager.shared.scheduleBudgetWarning(
            budgetName: budget.name ?? "Budget",
            spent: budget.spent,
            limit: budget.amount,
            budgetID: budgetID
        )
    }

    private func getSpentAmountForCategory(categoryID: UUID, month: Int, year: Int) -> Double {
        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        let calendar = Calendar.current

        let startOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date()
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) ?? Date()

        request.predicate = NSPredicate(
            format: "categoryID == %@ AND type == %@ AND date >= %@ AND date <= %@",
            categoryID as CVarArg, "expense", startOfMonth as NSDate, endOfMonth as NSDate
        )

        do {
            let transactions = try persistenceController.container.viewContext.fetch(request)
            return transactions.reduce(0) { $0 + $1.amount }
        } catch {
            print("Error fetching transactions for budget: \(error)")
            return 0
        }
    }

    func getBudgetProgress(_ budget: Budget) -> Double {
        guard budget.amount > 0 else { return 0 }
        return min(budget.spent / budget.amount, 1.0)
    }

    func getBudgetStatus(_ budget: Budget) -> BudgetStatus {
        let progress = getBudgetProgress(budget)

        if progress >= 1.0 {
            return .exceeded
        } else if progress >= 0.8 {
            return .warning
        } else {
            return .onTrack
        }
    }
}

enum BudgetStatus {
    case onTrack
    case warning
    case exceeded

    var color: String {
        switch self {
        case .onTrack: return "green"
        case .warning: return "orange"
        case .exceeded: return "red"
        }
    }
}
