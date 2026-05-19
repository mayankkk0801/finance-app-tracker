//
//  TransactionListView.swift
//  Finance app tracker
//

import SwiftUI

struct TransactionListView: View {
    @EnvironmentObject private var viewModel: TransactionViewModel
    @State private var showingAddTransaction = false
    @State private var addTransactionType: TransactionType = .expense
    @State private var selectedTransaction: Transaction?
    @State private var searchText = ""
    @State private var selectedFilter: TransactionFilter = .all
    @State private var editingTransaction: Transaction?
    @State private var editAmount: String = ""

    var filteredTransactions: [Transaction] {
        var transactions = viewModel.transactions

        if !searchText.isEmpty {
            transactions = transactions.filter { transaction in
                (transaction.title?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (transaction.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        switch selectedFilter {
        case .income:
            transactions = transactions.filter { $0.type == "income" }
        case .expenses:
            transactions = transactions.filter { $0.type == "expense" }
        case .all:
            break
        }

        return transactions
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(TransactionFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                if filteredTransactions.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        EmptyStateView(
                            icon: "list.bullet.rectangle.fill",
                            title: searchText.isEmpty ? "No Transactions" : "No Results",
                            subtitle: searchText.isEmpty
                                ? "Add income or expenses to track your finances"
                                : "Try adjusting your search or filter"
                        )

                        if searchText.isEmpty {
                            HStack(spacing: 12) {
                                Button(action: { presentAddSheet(type: .income) }) {
                                    Label("Add Income", systemImage: "plus.circle.fill")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.green)

                                Button(action: { presentAddSheet(type: .expense) }) {
                                    Label("Add Expense", systemImage: "minus.circle.fill")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.red)
                            }
                            .padding(.horizontal)
                        }
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(groupedTransactions, id: \.key) { dateGroup in
                            Section(header: Text(dateGroup.key).font(.subheadline).fontWeight(.semibold)) {
                                ForEach(dateGroup.value, id: \.id) { transaction in
                                    EditableTransactionRow(
                                        transaction: transaction,
                                        categories: viewModel.categories,
                                        viewModel: viewModel,
                                        editingTransaction: $editingTransaction,
                                        editAmount: $editAmount
                                    )
                                    .onTapGesture {
                                        selectedTransaction = transaction
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button("Delete", role: .destructive) {
                                            withAnimation {
                                                viewModel.deleteTransaction(transaction)
                                            }
                                        }

                                        Button("Edit Amount") {
                                            editingTransaction = transaction
                                            editAmount = String(transaction.amount)
                                        }
                                        .tint(.orange)

                                        Button("Edit") {
                                            selectedTransaction = transaction
                                        }
                                        .tint(.blue)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Transactions")
            .searchable(text: $searchText, prompt: "Search transactions...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { presentAddSheet(type: .income) }) {
                            Label("Add Income", systemImage: "arrow.up.circle.fill")
                        }
                        Button(action: { presentAddSheet(type: .expense) }) {
                            Label("Add Expense", systemImage: "arrow.down.circle.fill")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView(viewModel: viewModel, initialType: addTransactionType)
            }
            .sheet(item: $selectedTransaction) { transaction in
                EditTransactionView(transaction: transaction, viewModel: viewModel)
            }
            .refreshable {
                viewModel.fetchTransactions()
                viewModel.fetchCategories()
            }
            .onAppear {
                viewModel.fetchTransactions()
                viewModel.fetchCategories()
            }
        }
    }

    private func presentAddSheet(type: TransactionType) {
        addTransactionType = type
        showingAddTransaction = true
    }

    private var groupedTransactions: [(key: String, value: [Transaction])] {
        let grouped = Dictionary(grouping: filteredTransactions) { transaction in
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: transaction.date ?? Date())
        }

        return grouped.sorted { first, second in
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            let firstDate = formatter.date(from: first.key) ?? Date.distantPast
            let secondDate = formatter.date(from: second.key) ?? Date.distantPast
            return firstDate > secondDate
        }
    }
}

struct TransactionCardView: View {
    let transaction: Transaction
    let categories: [Category]

    private var category: Category? {
        categories.first { $0.id == transaction.categoryID }
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(category?.color ?? "blue").opacity(0.1))
                    .frame(width: 50, height: 50)

                Image(systemName: category?.icon ?? "dollarsign.circle")
                    .font(.title3)
                    .foregroundColor(Color(category?.color ?? "blue"))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.title ?? "Unknown Transaction")
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(category?.name ?? "Unknown Category")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let notes = transaction.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(CurrencyFormatter.signedString(
                    from: transaction.amount,
                    isIncome: transaction.type == "income"
                ))
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(transaction.type == "income" ? .green : .red)

                Text(transaction.date?.formatted(date: .abbreviated, time: .shortened) ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

enum TransactionFilter: String, CaseIterable {
    case all = "All"
    case income = "Income"
    case expenses = "Expenses"
}

#Preview {
    TransactionListView()
        .environmentObject(TransactionViewModel())
}
