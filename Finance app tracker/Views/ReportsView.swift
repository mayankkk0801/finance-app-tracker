//
//  ReportsView.swift
//  Finance app tracker
//
//  Created by MAYANK GAHLOT on 23/08/25.
//

import SwiftUI
import Charts

struct ReportsView: View {
    @EnvironmentObject private var transactionViewModel: TransactionViewModel
    @State private var selectedTimeframe: TimeFrame = .thisMonth
    @State private var showingExportSheet = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Timeframe Picker
                    timeframePicker
                    
                    // Summary Cards
                    summaryCards
                    
                    // Income vs Expenses Chart
                    incomeExpensesChart
                    
                    // Category Breakdown Chart
                    categoryBreakdownChart
                    
                    // Monthly Trend Chart
                    monthlyTrendChart
                    
                    // Export Options
                    exportSection
                }
                .padding()
            }
            .navigationTitle("Reports")
            .refreshable {
                transactionViewModel.fetchTransactions()
                transactionViewModel.fetchCategories()
            }
            .onAppear {
                transactionViewModel.fetchTransactions()
                transactionViewModel.fetchCategories()
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportView(
                    transactions: filteredTransactions,
                    categories: transactionViewModel.categories
                )
            }
        }
    }
    
    private var timeframePicker: some View {
        Picker("Timeframe", selection: $selectedTimeframe) {
            ForEach(TimeFrame.allCases, id: \.self) { timeframe in
                Text(timeframe.rawValue).tag(timeframe)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }
    
    private var summaryCards: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                SummaryCard(
                    title: "Total Income",
                    amount: totalIncome,
                    color: .green,
                    icon: "arrow.up.circle.fill"
                )
                
                SummaryCard(
                    title: "Total Expenses",
                    amount: totalExpenses,
                    color: .red,
                    icon: "arrow.down.circle.fill"
                )
            }
            
            SummaryCard(
                title: "Net Income",
                amount: totalIncome - totalExpenses,
                color: totalIncome - totalExpenses >= 0 ? .green : .red,
                icon: "dollarsign.circle.fill"
            )
        }
    }
    
    private var incomeExpensesChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Income vs Expenses")
                .font(.headline)
                .fontWeight(.semibold)
            
            Chart {
                BarMark(
                    x: .value("Type", "Income"),
                    y: .value("Amount", totalIncome)
                )
                .foregroundStyle(.green)
                
                BarMark(
                    x: .value("Type", "Expenses"),
                    y: .value("Amount", totalExpenses)
                )
                .foregroundStyle(.red)
            }
            .frame(height: 200)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var categoryBreakdownChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Expenses by Category")
                .font(.headline)
                .fontWeight(.semibold)
            
            let categoryData = getCategorySpending()
            
            if categoryData.isEmpty {
                EmptyStateView(
                    icon: "chart.pie.fill",
                    title: "No Data",
                    subtitle: "Add some transactions to see category breakdown"
                )
            } else {
                Chart(categoryData, id: \.category.id) { data in
                    SectorMark(
                        angle: .value("Amount", data.amount),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(Color(data.category.color ?? "blue"))
                    .opacity(0.8)
                }
                .frame(height: 200)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Legend
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(categoryData.prefix(6), id: \.category.id) { data in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(data.category.color ?? "blue"))
                                .frame(width: 12, height: 12)
                            
                            Text(data.category.name ?? "Unknown")
                                .font(.caption)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text(data.amount.formatted(.currency(code: "USD")))
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
    
    private var monthlyTrendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monthly Trend")
                .font(.headline)
                .fontWeight(.semibold)
            
            let monthlyData = getMonthlyData()
            
            if monthlyData.isEmpty {
                EmptyStateView(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "No Data",
                    subtitle: "Add transactions over multiple months to see trends"
                )
            } else {
                Chart(monthlyData, id: \.month) { data in
                    LineMark(
                        x: .value("Month", data.month),
                        y: .value("Income", data.income)
                    )
                    .foregroundStyle(.green)
                    .symbol(Circle())
                    
                    LineMark(
                        x: .value("Month", data.month),
                        y: .value("Expenses", data.expenses)
                    )
                    .foregroundStyle(.red)
                    .symbol(Circle())
                }
                .frame(height: 200)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
    
    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Export Data")
                .font(.headline)
                .fontWeight(.semibold)
            
            Button(action: { showingExportSheet = true }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Export Reports")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var filteredTransactions: [Transaction] {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedTimeframe {
        case .thisWeek:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            return transactionViewModel.transactions.filter { transaction in
                guard let date = transaction.date else { return false }
                return date >= startOfWeek
            }
            
        case .thisMonth:
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            return transactionViewModel.transactions.filter { transaction in
                guard let date = transaction.date else { return false }
                return date >= startOfMonth
            }
            
        case .thisYear:
            let startOfYear = calendar.dateInterval(of: .year, for: now)?.start ?? now
            return transactionViewModel.transactions.filter { transaction in
                guard let date = transaction.date else { return false }
                return date >= startOfYear
            }
            
        case .allTime:
            return transactionViewModel.transactions
        }
    }
    
    private var totalIncome: Double {
        filteredTransactions.filter { $0.type == "income" }.reduce(0) { $0 + $1.amount }
    }
    
    private var totalExpenses: Double {
        filteredTransactions.filter { $0.type == "expense" }.reduce(0) { $0 + $1.amount }
    }
    
    private func getCategorySpending() -> [(category: Category, amount: Double)] {
        let expenseTransactions = filteredTransactions.filter { $0.type == "expense" }
        var categorySpending: [UUID: Double] = [:]
        
        for transaction in expenseTransactions {
            guard let categoryID = transaction.categoryID else { continue }
            categorySpending[categoryID, default: 0] += transaction.amount
        }
        
        return transactionViewModel.categories.compactMap { category in
            guard let categoryID = category.id else { return nil }
            if let spending = categorySpending[categoryID], spending > 0 {
                return (category: category, amount: spending)
            }
            return nil
        }.sorted { $0.amount > $1.amount }
    }
    
    private func getMonthlyData() -> [MonthlyData] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: transactionViewModel.transactions) { transaction in
            let components = calendar.dateComponents([.year, .month], from: transaction.date ?? Date())
            return "\(components.year ?? 0)-\(String(format: "%02d", components.month ?? 0))"
        }
        
        return grouped.map { key, transactions in
            let income = transactions.filter { $0.type == "income" }.reduce(0) { $0 + $1.amount }
            let expenses = transactions.filter { $0.type == "expense" }.reduce(0) { $0 + $1.amount }
            return MonthlyData(month: key, income: income, expenses: expenses)
        }.sorted { $0.month < $1.month }
    }
}

struct SummaryCard: View {
    let title: String
    let amount: Double
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
            }
            
            Text(amount.formatted(.currency(code: "USD")))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MonthlyData {
    let month: String
    let income: Double
    let expenses: Double
}

enum TimeFrame: String, CaseIterable {
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case thisYear = "This Year"
    case allTime = "All Time"
}

#Preview {
    ReportsView()
        .environmentObject(TransactionViewModel())
}
