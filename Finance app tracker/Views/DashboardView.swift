//
//  DashboardView.swift
//  Finance app tracker
//
//  Created by MAYANK GAHLOT on 23/08/25.
//

import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject private var transactionViewModel: TransactionViewModel
    @EnvironmentObject private var budgetViewModel: BudgetViewModel
    @State private var showingAddIncome = false
    @State private var showingAddExpense = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Balance Overview Cards
                    balanceOverviewSection
                    
                    // Quick Actions
                    quickActionsSection
                    
                    // Spending Chart
                    spendingChartSection
                    
                    // Budget Progress
                    budgetProgressSection
                    
                    // Recent Transactions
                    recentTransactionsSection
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .refreshable {
                transactionViewModel.fetchTransactions()
                budgetViewModel.fetchBudgets()
            }
            .sheet(isPresented: $showingAddIncome) {
                AddTransactionView(viewModel: transactionViewModel, initialType: .income)
            }
            .sheet(isPresented: $showingAddExpense) {
                AddTransactionView(viewModel: transactionViewModel, initialType: .expense)
            }
        }
        .onAppear {
            transactionViewModel.fetchTransactions()
            transactionViewModel.fetchCategories()
            budgetViewModel.fetchBudgets()
        }
    }
    
    private var balanceOverviewSection: some View {
        VStack(spacing: 16) {
            // Main Balance Card
            BalanceCard(
                title: "Total Balance",
                amount: transactionViewModel.currentBalance,
                color: transactionViewModel.currentBalance >= 0 ? .green : .red,
                icon: "dollarsign.circle.fill"
            )
            
            HStack(spacing: 16) {
                // Income Card
                BalanceCard(
                    title: "Income",
                    amount: transactionViewModel.totalIncome,
                    color: .green,
                    icon: "arrow.up.circle.fill"
                )
                
                // Expenses Card
                BalanceCard(
                    title: "Expenses",
                    amount: transactionViewModel.totalExpenses,
                    color: .red,
                    icon: "arrow.down.circle.fill"
                )
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                QuickActionButton(
                    title: "Add Income",
                    icon: "plus.circle.fill",
                    color: .green
                ) {
                    showingAddIncome = true
                }

                QuickActionButton(
                    title: "Add Expense",
                    icon: "minus.circle.fill",
                    color: .red
                ) {
                    showingAddExpense = true
                }

                NavigationLink(destination: ReportsView()) {
                    QuickActionButton(
                        title: "View Reports",
                        icon: "chart.bar.fill",
                        color: .blue
                    ) {}
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var spendingChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending Overview")
                .font(.headline)
                .fontWeight(.semibold)
            
            SpendingChart(categorySpending: transactionViewModel.getCategorySpending())
                .frame(height: 200)
                .background(Color(.systemGray6))
                .cornerRadius(12)
        }
    }
    
    private var budgetProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Budget Progress")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                NavigationLink("View All") {
                    BudgetListView()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if budgetViewModel.budgets.isEmpty {
                EmptyStateView(
                    icon: "chart.pie.fill",
                    title: "No Budgets",
                    subtitle: "Create your first budget to track spending"
                )
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(Array(budgetViewModel.budgets.prefix(3)), id: \.id) { budget in
                        BudgetProgressRow(budget: budget, viewModel: budgetViewModel)
                    }
                }
            }
        }
    }
    
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Transactions")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                NavigationLink("View All") {
                    TransactionListView()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if transactionViewModel.transactions.isEmpty {
                EmptyStateView(
                    icon: "list.bullet.rectangle.fill",
                    title: "No Transactions",
                    subtitle: "Add your first transaction to get started"
                )
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(Array(transactionViewModel.transactions.prefix(5)), id: \.id) { transaction in
                        TransactionRow(transaction: transaction, categories: transactionViewModel.categories)
                    }
                }
            }
        }
    }
}

struct BalanceCard: View {
    let title: String
    let amount: Double
    let color: Color
    let icon: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(amount.formatted(.currency(code: "USD")))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            Spacer()
            
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}


struct BudgetProgressRow: View {
    let budget: Budget
    let viewModel: BudgetViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(budget.name ?? "Unknown Budget")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(budget.spent.formatted(.currency(code: "USD"))) / \(budget.amount.formatted(.currency(code: "USD")))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: viewModel.getBudgetProgress(budget))
                .progressViewStyle(LinearProgressViewStyle(tint: Color(viewModel.getBudgetStatus(budget).color)))
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    let categories: [Category]
    
    private var category: Category? {
        categories.first { $0.id == transaction.categoryID }
    }
    
    var body: some View {
        HStack {
            // Category Icon
            Image(systemName: category?.icon ?? "dollarsign.circle")
                .font(.title3)
                .foregroundColor(Color(category?.color ?? "blue"))
                .frame(width: 40, height: 40)
                .background(Color(category?.color ?? "blue").opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.title ?? "Unknown Transaction")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(category?.name ?? "Unknown Category")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text((transaction.type == "income" ? "+" : "-") + transaction.amount.formatted(.currency(code: "USD")))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(transaction.type == "income" ? .green : .red)
                
                Text(transaction.date?.formatted(date: .abbreviated, time: .omitted) ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    DashboardView()
        .environmentObject(TransactionViewModel())
        .environmentObject(BudgetViewModel())
}
