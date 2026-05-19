//
//  EditableTransactionRow.swift
//  Finance app tracker
//
//  Created by MAYANK GAHLOT on 23/08/25.
//

import SwiftUI
import CoreData
import UIKit

struct EditableTransactionRow: View {
    let transaction: Transaction
    let categories: [Category]
    let viewModel: TransactionViewModel
    @Binding var editingTransaction: Transaction?
    @Binding var editAmount: String
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private var category: Category? {
        categories.first { $0.id == transaction.categoryID }
    }
    
    private var isEditing: Bool {
        editingTransaction?.objectID == transaction.objectID
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Category Icon
            if let category = category {
                Image(systemName: category.icon ?? "questionmark.circle")
                    .font(.title2)
                    .foregroundColor(Color(category.color ?? "blue"))
                    .frame(width: 40, height: 40)
                    .background(Color(category.color ?? "blue").opacity(0.1))
                    .clipShape(Circle())
            } else {
                Image(systemName: "questionmark.circle")
                    .font(.title2)
                    .foregroundColor(.gray)
                    .frame(width: 40, height: 40)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Transaction Title/Description
                Text(transaction.title ?? "No description")
                    .font(.headline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                // Category and Date
                HStack {
                    Text(category?.name ?? "Unknown Category")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let date = transaction.date {
                        Text(date, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Editable Amount
            VStack(alignment: .trailing, spacing: 4) {
                if isEditing {
                    HStack(spacing: 8) {
                        TextField("Amount", text: $editAmount)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                        
                        Button("Save") {
                            saveAmount()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                        
                        Button("Cancel") {
                            cancelEditing()
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                } else {
                    Text(CurrencyFormatter.signedString(
                        from: transaction.amount,
                        isIncome: transaction.type == "income"
                    ))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(transaction.type == "income" ? .green : .red)
                        .onTapGesture {
                            startEditing()
                        }
                    
                    Text(transaction.type?.capitalized ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .alert("Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func startEditing() {
        editingTransaction = transaction
        editAmount = String(transaction.amount)
    }
    
    private func cancelEditing() {
        editingTransaction = nil
        editAmount = ""
    }
    
    private func saveAmount() {
        guard let newAmount = Double(editAmount), newAmount > 0 else {
            alertMessage = "Please enter a valid amount"
            showingAlert = true
            return
        }
        
        // Update the transaction amount
        transaction.amount = newAmount
        
        // Save to Core Data
        do {
            try transaction.managedObjectContext?.save()
        } catch {
            print("Failed to save transaction: \(error)")
        }
        
        // Refresh data and calculations
        viewModel.fetchTransactions()
        viewModel.calculateTotals()
        
        // Clear editing state
        editingTransaction = nil
        editAmount = ""
        
        HapticManager.shared.mediumImpact()
    }
}

#Preview {
    EditableTransactionRow(
        transaction: Transaction(),
        categories: [Category()],
        viewModel: TransactionViewModel(),
        editingTransaction: .constant(nil as Transaction?),
        editAmount: .constant("")
    )
    .padding()
}
