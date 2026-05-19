//
//  AddTransactionView.swift
//  Finance app tracker
//
//  Created by MAYANK GAHLOT on 23/08/25.
//

import SwiftUI
import CoreData

struct AddTransactionView: View {
    @ObservedObject var viewModel: TransactionViewModel
    var initialType: TransactionType = .expense
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var amount = ""
    @State private var selectedType: TransactionType = .expense
    @State private var selectedCategory: Category?
    @State private var date = Date()
    @State private var notes = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private var filteredCategories: [Category] {
        viewModel.categories.filter { $0.type == selectedType.rawValue }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Transaction Details") {
                    TextField("Title", text: $title)
                    
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    
                    Picker("Type", selection: $selectedType) {
                        ForEach(TransactionType.allCases, id: \.self) { type in
                            Text(type.rawValue.capitalized).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: selectedType) {
                        selectedCategory = nil
                    }
                    
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section(selectedType == .income ? "Income Category" : "Expense Category") {
                    if filteredCategories.isEmpty {
                        Text("No \(selectedType.rawValue) categories available")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(filteredCategories, id: \.id) { category in
                            CategoryRow(
                                category: category,
                                isSelected: selectedCategory?.id == category.id
                            )
                            .onTapGesture {
                                selectedCategory = category
                            }
                        }
                    }
                }
                
                Section("Notes") {
                    TextField("Add notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(initialType == .income ? "Add Income" : "Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTransaction()
                    }
                    .disabled(!isFormValid)
                }
            }
            .onAppear {
                selectedType = initialType
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private var isFormValid: Bool {
        !title.isEmpty && !amount.isEmpty && selectedCategory != nil && Double(amount) != nil
    }
    
    private func saveTransaction() {
        guard let amountValue = Double(amount),
              let category = selectedCategory else {
            alertMessage = "Please fill in all required fields"
            showingAlert = true
            return
        }
        
        guard let categoryID = category.id else {
            alertMessage = "Invalid category selected"
            showingAlert = true
            return
        }
        
        viewModel.addTransaction(
            amount: amountValue,
            description: title,
            type: selectedType.rawValue,
            categoryID: categoryID,
            date: date,
            notes: notes.isEmpty ? nil : notes
        )
        
        dismiss()
    }
}

struct EditTransactionView: View {
    let transaction: Transaction
    @ObservedObject var viewModel: TransactionViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var amount = ""
    @State private var selectedType: TransactionType = .expense
    @State private var selectedCategory: Category?
    @State private var date = Date()
    @State private var notes = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private var filteredCategories: [Category] {
        viewModel.categories.filter { $0.type == selectedType.rawValue }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Transaction Details") {
                    TextField("Title", text: $title)
                    
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    
                    Picker("Type", selection: $selectedType) {
                        ForEach(TransactionType.allCases, id: \.self) { type in
                            Text(type.rawValue.capitalized).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: selectedType) {
                        if let transactionCategoryID = transaction.categoryID {
                            selectedCategory = filteredCategories.first { category in
                                category.id == transactionCategoryID
                            }
                        } else {
                            selectedCategory = nil
                        }
                    }
                    
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section(selectedType == .income ? "Income Category" : "Expense Category") {
                    if filteredCategories.isEmpty {
                        Text("No \(selectedType.rawValue) categories available")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(filteredCategories, id: \.id) { category in
                            CategoryRow(
                                category: category,
                                isSelected: selectedCategory?.id == category.id
                            )
                            .onTapGesture {
                                selectedCategory = category
                            }
                        }
                    }
                }
                
                Section("Notes") {
                    TextField("Add notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateTransaction()
                    }
                    .disabled(!isFormValid)
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                loadTransactionData()
            }
        }
    }
    
    private var isFormValid: Bool {
        !title.isEmpty && !amount.isEmpty && selectedCategory != nil && Double(amount) != nil
    }
    
    private func loadTransactionData() {
        title = transaction.title ?? ""
        amount = String(transaction.amount)
        selectedType = TransactionType(rawValue: transaction.type ?? "expense") ?? .expense
        date = transaction.date ?? Date()
        notes = transaction.notes ?? ""
        
        // Safely find the category by comparing optional UUIDs
        if let transactionCategoryID = transaction.categoryID {
            selectedCategory = viewModel.categories.first { category in
                category.id == transactionCategoryID
            }
        }
    }
    
    private func updateTransaction() {
        guard !title.isEmpty else {
            alertMessage = "Please enter a title"
            showingAlert = true
            return
        }
        
        guard let amountValue = Double(amount), amountValue > 0 else {
            alertMessage = "Please enter a valid amount"
            showingAlert = true
            return
        }
        
        guard let category = selectedCategory else {
            alertMessage = "Please select a category"
            showingAlert = true
            return
        }
        
        guard let categoryID = category.id else {
            alertMessage = "Invalid category selected"
            showingAlert = true
            return
        }
        
        viewModel.updateTransaction(
            transaction,
            title: title,
            amount: amountValue,
            type: selectedType.rawValue,
            categoryID: categoryID,
            date: date,
            notes: notes.isEmpty ? nil : notes
        )
        
        dismiss()
    }
}

struct CategoryRow: View {
    let category: Category
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Image(systemName: category.icon ?? "dollarsign.circle")
                .font(.title3)
                .foregroundColor(Color(category.color ?? "blue"))
                .frame(width: 30)
            
            Text(category.name ?? "Unknown Category")
                .font(.body)
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

enum TransactionType: String, CaseIterable {
    case income = "income"
    case expense = "expense"
}

#Preview {
    AddTransactionView(viewModel: TransactionViewModel())
}
