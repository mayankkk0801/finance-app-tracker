//
//  TransactionViewModel.swift
//  Finance app tracker
//

import Foundation
import CoreData
import Combine

class TransactionViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var categories: [Category] = []
    @Published var totalIncome: Double = 0
    @Published var totalExpenses: Double = 0
    @Published var currentBalance: Double = 0

    var onTransactionsChanged: (() -> Void)?

    private let persistenceController = PersistenceController.shared

    init() {
        fetchTransactions()
        fetchCategories()
        calculateTotals()
    }

    func fetchTransactions() {
        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)]

        do {
            transactions = try persistenceController.container.viewContext.fetch(request)
            calculateTotals()
            onTransactionsChanged?()
        } catch {
            print("Error fetching transactions: \(error)")
        }
    }

    func calculateTotals() {
        totalIncome = transactions.filter { $0.type == "income" }.reduce(0) { $0 + $1.amount }
        totalExpenses = transactions.filter { $0.type == "expense" }.reduce(0) { $0 + $1.amount }
        currentBalance = totalIncome - totalExpenses
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

    func addTransaction(
        amount: Double,
        description: String,
        type: String,
        categoryID: UUID,
        date: Date = Date(),
        notes: String? = nil
    ) {
        let context = persistenceController.container.viewContext
        let transaction = Transaction(context: context)

        transaction.id = UUID()
        transaction.amount = amount
        transaction.title = description
        transaction.date = date
        transaction.createdAt = Date()
        transaction.type = type
        transaction.categoryID = categoryID
        transaction.notes = notes

        persistenceController.save()
        fetchTransactions()
        HapticManager.shared.successNotification()
    }

    func updateTransaction(
        _ transaction: Transaction,
        title: String,
        amount: Double,
        type: String,
        categoryID: UUID,
        date: Date,
        notes: String?
    ) {
        transaction.title = title
        transaction.amount = amount
        transaction.type = type
        transaction.categoryID = categoryID
        transaction.date = date
        transaction.notes = notes

        persistenceController.save()
        fetchTransactions()
        HapticManager.shared.lightImpact()
    }

    func deleteTransaction(_ transaction: Transaction) {
        let context = persistenceController.container.viewContext
        context.delete(transaction)
        persistenceController.save()
        fetchTransactions()
        HapticManager.shared.mediumImpact()
    }

    func getTransactionsForCurrentMonth() -> [Transaction] {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end ?? now

        return transactions.filter { transaction in
            guard let date = transaction.date else { return false }
            return date >= startOfMonth && date <= endOfMonth
        }
    }

    func getCategorySpending() -> [(Category, Double)] {
        let expenseTransactions = transactions.filter { $0.type == "expense" }
        var categorySpending: [UUID: Double] = [:]

        for transaction in expenseTransactions {
            guard let categoryID = transaction.categoryID else { continue }
            categorySpending[categoryID, default: 0] += transaction.amount
        }

        return categories.compactMap { category in
            guard let categoryID = category.id else { return nil }
            if let spending = categorySpending[categoryID], spending > 0 {
                return (category, spending)
            }
            return nil
        }.sorted { $0.1 > $1.1 }
    }

    func getTransactionsForCategory(_ categoryID: UUID) -> [Transaction] {
        transactions.filter { $0.categoryID == categoryID }
    }

    func getTransactionsForDateRange(start: Date, end: Date) -> [Transaction] {
        transactions.filter { transaction in
            guard let date = transaction.date else { return false }
            return date >= start && date <= end
        }
    }

    func categoryName(for categoryID: UUID?) -> String {
        guard let categoryID else { return "Unknown" }
        return categories.first { $0.id == categoryID }?.name ?? "Unknown"
    }
}
