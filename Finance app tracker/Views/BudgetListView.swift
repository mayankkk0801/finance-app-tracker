//
//  BudgetListView.swift
//  Finance app tracker
//
//  Created by MAYANK GAHLOT on 23/08/25.
//

import SwiftUI

struct BudgetListView: View {
    @EnvironmentObject private var viewModel: BudgetViewModel
    @EnvironmentObject private var transactionViewModel: TransactionViewModel
    @State private var showingAddBudget = false
    @State private var selectedBudget: Budget?
    
    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.budgets.isEmpty {
                    Spacer()
                    EmptyStateView(
                        icon: "chart.pie.fill",
                        title: "No Budgets",
                        subtitle: "Create a budget for an expense category. Expenses you add will update progress here."
                    )
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.budgets, id: \.id) { budget in
                            BudgetCardView(budget: budget, viewModel: viewModel)
                                .onTapGesture {
                                    selectedBudget = budget
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button("Delete", role: .destructive) {
                                        withAnimation {
                                            viewModel.deleteBudget(budget)
                                        }
                                    }
                                    
                                    Button("Edit") {
                                        selectedBudget = budget
                                    }
                                    .tint(.blue)
                                }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Budgets")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddBudget = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddBudget) {
                AddBudgetView(viewModel: viewModel)
            }
            .sheet(item: $selectedBudget) { budget in
                EditBudgetView(budget: budget, viewModel: viewModel)
            }
            .refreshable {
                transactionViewModel.fetchTransactions()
                viewModel.fetchBudgets()
            }
            .onAppear {
                transactionViewModel.fetchTransactions()
                viewModel.fetchBudgets()
                viewModel.fetchCategories()
            }
        }
    }
}

struct BudgetCardView: View {
    let budget: Budget
    let viewModel: BudgetViewModel
    
    private var progress: Double {
        viewModel.getBudgetProgress(budget)
    }
    
    private var status: BudgetStatus {
        viewModel.getBudgetStatus(budget)
    }
    
    private var remainingAmount: Double {
        max(0, budget.amount - budget.spent)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(budget.name ?? "Unknown Budget")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Budget for \(monthYearString)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(budget.amount.formatted(.currency(code: "USD")))
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("Budget")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress Bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Spent: \(budget.spent.formatted(.currency(code: "USD")))")
                        .font(.subheadline)
                        .foregroundColor(Color(status.color))
                    
                    Spacer()
                    
                    Text("Remaining: \(remainingAmount.formatted(.currency(code: "USD")))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color(status.color)))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                
                HStack {
                    Text("\(Int(progress * 100))% used")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    statusBadge
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let date = Calendar.current.date(from: DateComponents(year: Int(budget.year), month: Int(budget.month))) ?? Date()
        return formatter.string(from: date)
    }
    
    private var statusBadge: some View {
        Text(statusText)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(status.color).opacity(0.2))
            .foregroundColor(Color(status.color))
            .cornerRadius(8)
    }
    
    private var statusText: String {
        switch status {
        case .onTrack:
            return "On Track"
        case .warning:
            return "Warning"
        case .exceeded:
            return "Exceeded"
        }
    }
}

struct AddBudgetView: View {
    @ObservedObject var viewModel: BudgetViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var amount = ""
    @State private var selectedCategory: Category?
    @State private var selectedMonth = Calendar.current.component(.month, from: Date())
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private var expenseCategories: [Category] {
        viewModel.categories.filter { $0.type == "expense" }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Budget Details") {
                    TextField("Budget Name", text: $name)
                    
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                }
                
                Section("Period") {
                    Picker("Month", selection: $selectedMonth) {
                        ForEach(1...12, id: \.self) { month in
                            Text(monthName(month)).tag(month)
                        }
                    }
                    
                    Picker("Year", selection: $selectedYear) {
                        ForEach(2023...2030, id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }
                }
                
                Section("Category") {
                    if expenseCategories.isEmpty {
                        Text("No expense categories available")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(expenseCategories, id: \.id) { category in
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
            }
            .navigationTitle("Add Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveBudget()
                    }
                    .disabled(!isFormValid)
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty && !amount.isEmpty && selectedCategory != nil && Double(amount) != nil
    }
    
    private func saveBudget() {
        guard let amountValue = Double(amount),
              let category = selectedCategory else {
            alertMessage = "Please fill in all required fields"
            showingAlert = true
            return
        }
        
        viewModel.addBudget(
            name: name,
            amount: amountValue,
            categoryID: category.id!,
            month: selectedMonth,
            year: selectedYear
        )
        
        dismiss()
    }
    
    private func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        let date = Calendar.current.date(from: DateComponents(month: month)) ?? Date()
        return formatter.string(from: date)
    }
}

struct EditBudgetView: View {
    let budget: Budget
    @ObservedObject var viewModel: BudgetViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var amount = ""
    @State private var selectedCategory: Category?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private var expenseCategories: [Category] {
        viewModel.categories.filter { $0.type == "expense" }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Budget Details") {
                    TextField("Budget Name", text: $name)
                    
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                }
                
                Section("Period") {
                    HStack {
                        Text("Month")
                        Spacer()
                        Text(monthName(Int(budget.month)))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Year")
                        Spacer()
                        Text(String(budget.year))
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Category") {
                    if expenseCategories.isEmpty {
                        Text("No expense categories available")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(expenseCategories, id: \.id) { category in
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
            }
            .navigationTitle("Edit Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateBudget()
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
                loadBudgetData()
            }
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty && !amount.isEmpty && selectedCategory != nil && Double(amount) != nil
    }
    
    private func loadBudgetData() {
        name = budget.name ?? ""
        amount = String(budget.amount)
        selectedCategory = viewModel.categories.first { $0.id == budget.categoryID }
    }
    
    private func updateBudget() {
        guard let amountValue = Double(amount),
              let category = selectedCategory else {
            alertMessage = "Please fill in all required fields"
            showingAlert = true
            return
        }
        
        viewModel.updateBudget(
            budget,
            name: name,
            amount: amountValue,
            categoryID: category.id!
        )
        
        dismiss()
    }
    
    private func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        let date = Calendar.current.date(from: DateComponents(month: month)) ?? Date()
        return formatter.string(from: date)
    }
}

#Preview {
    BudgetListView()
        .environmentObject(BudgetViewModel())
        .environmentObject(TransactionViewModel())
}
