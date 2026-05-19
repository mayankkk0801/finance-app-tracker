//
//  CoreDataExtensions.swift
//  Finance app tracker
//
//  Created by MAYANK GAHLOT on 23/08/25.
//

import Foundation
import CoreData

// MARK: - Budget Extensions
extension Budget {
    var budgetProgress: Double {
        guard amount > 0 else { return 0 }
        return min(spent / amount, 1.0)
    }
    
    var remainingAmount: Double {
        return max(0, amount - spent)
    }
}

// MARK: - Transaction Extensions  
extension Transaction {
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    var isIncome: Bool {
        return type == "income"
    }
    
    var isExpense: Bool {
        return type == "expense"
    }
}

// MARK: - Category Extensions
extension Category {
    var budgetsArray: [Budget] {
        let set = budgets as? Set<Budget> ?? []
        return set.sorted { ($0.name ?? "") < ($1.name ?? "") }
    }
    
    var transactionsArray: [Transaction] {
        let set = transactions as? Set<Transaction> ?? []
        return set.sorted { ($0.date ?? Date.distantPast) > ($1.date ?? Date.distantPast) }
    }
}
