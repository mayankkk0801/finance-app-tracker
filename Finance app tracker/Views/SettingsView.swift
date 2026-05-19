//
//  SettingsView.swift
//  Finance app tracker
//
//  Created by MAYANK GAHLOT on 23/08/25.
//

import SwiftUI
import CoreData

struct SettingsView: View {
    @ObservedObject private var authViewModel = AuthenticationViewModel.shared
    @ObservedObject private var settings = AppSettings.shared
    @State private var showingClearDataAlert = false
    @State private var showingAbout = false

    var body: some View {
        NavigationStack {
            List {
                Section("Appearance") {
                    Picker("Theme", selection: $settings.appearance) {
                        ForEach(AppAppearance.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                }

                Section("Security") {
                    Toggle(isOn: $settings.biometricsEnabled) {
                        HStack {
                            Image(systemName: authViewModel.biometricIcon)
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            VStack(alignment: .leading) {
                                Text(authViewModel.biometricTypeString)
                                Text("Require unlock when opening the app")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onChange(of: settings.biometricsEnabled) {
                        authViewModel.refreshLockState()
                    }

                    if settings.biometricsEnabled {
                        Button(action: { authViewModel.logout() }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .foregroundColor(.red)
                                    .frame(width: 30)
                                Text("Lock App")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }

                Section("Notifications") {
                    Toggle(isOn: $settings.billRemindersEnabled) {
                        Label("Bill Reminders", systemImage: "bell.fill")
                    }
                    .onChange(of: settings.billRemindersEnabled) { _, enabled in
                        if enabled {
                            handleNotificationToggle(true) {
                                BillReminderStore.shared.rescheduleAllNotifications()
                            }
                        } else {
                            BillReminderStore.shared.rescheduleAllNotifications()
                        }
                    }

                    NavigationLink {
                        BillRemindersView()
                    } label: {
                        Label("Manage Bills", systemImage: "calendar.badge.clock")
                    }

                    Toggle(isOn: $settings.budgetAlertsEnabled) {
                        Label("Budget Alerts", systemImage: "chart.pie.fill")
                    }

                    Toggle(isOn: $settings.weeklyRemindersEnabled) {
                        Label("Weekly Check-in", systemImage: "clock.arrow.circlepath")
                    }
                    .onChange(of: settings.weeklyRemindersEnabled) { _, enabled in
                        if enabled {
                            handleNotificationToggle(true) {
                                NotificationManager.shared.scheduleWeeklyExpenseReminder()
                            }
                        } else {
                            NotificationManager.shared.removeWeeklyExpenseReminder()
                        }
                    }
                }
                
                // Data Management Section
                Section("Data Management") {
                    NavigationLink(destination: CategoryManagementView()) {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading) {
                                Text("Manage Categories")
                                Text("Add, edit, or remove transaction categories")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Button(action: { showingClearDataAlert = true }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading) {
                                Text("Clear All Data")
                                    .foregroundColor(.red)
                                Text("Permanently delete all transactions and budgets")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // App Information Section
                Section("About") {
                    Button(action: { showingAbout = true }) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                                .frame(width: 30)

                            VStack(alignment: .leading) {
                                Text("About")
                                    .foregroundColor(.primary)
                                Text("Version 1.0.0")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.secondary)
                            .frame(width: 30)
                        Text("Data is stored on this device only.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Clear All Data", isPresented: $showingClearDataAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear Data", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("This action cannot be undone. All your transactions, budgets, and categories will be permanently deleted.")
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
        }
    }

    private func handleNotificationToggle(_ enabled: Bool, onGranted: @escaping () -> Void) {
        guard enabled else { return }
        NotificationManager.shared.requestPermission { granted in
            if granted {
                onGranted()
            } else {
                settings.billRemindersEnabled = false
                settings.weeklyRemindersEnabled = false
            }
        }
    }
    
    private func clearAllData() {
        let context = PersistenceController.shared.container.viewContext
        
        do {
            // Clear all transactions
            let transactionRequest: NSFetchRequest<NSFetchRequestResult> = Transaction.fetchRequest()
            let deleteTransactionsRequest = NSBatchDeleteRequest(fetchRequest: transactionRequest)
            try context.execute(deleteTransactionsRequest)
            
            // Clear all budgets
            let budgetRequest: NSFetchRequest<NSFetchRequestResult> = Budget.fetchRequest()
            let deleteBudgetsRequest = NSBatchDeleteRequest(fetchRequest: budgetRequest)
            try context.execute(deleteBudgetsRequest)
            
            // Reset the context to reflect the changes
            context.reset()
            try context.save()
        } catch {
            print("Error clearing data: \(error)")
        }
    }
}

struct CategoryManagementView: View {
    @EnvironmentObject private var transactionViewModel: TransactionViewModel
    @State private var showingAddCategory = false
    @State private var selectedCategory: Category?
    
    var body: some View {
        List {
            Section("Income Categories") {
                ForEach(incomeCategories, id: \.objectID) { category in
                    CategoryManagementRow(category: category)
                        .onTapGesture {
                            selectedCategory = category
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("Delete", role: .destructive) {
                                deleteCategory(category)
                            }
                        }
                }
            }
            
            Section("Expense Categories") {
                ForEach(expenseCategories, id: \.objectID) { category in
                    CategoryManagementRow(category: category)
                        .onTapGesture {
                            selectedCategory = category
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("Delete", role: .destructive) {
                                deleteCategory(category)
                            }
                        }
                }
            }
        }
        .navigationTitle("Categories")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddCategory = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddCategory) {
            AddCategoryView(viewModel: transactionViewModel)
        }
        .sheet(item: $selectedCategory) { category in
            EditCategoryView(category: category, viewModel: transactionViewModel)
        }
        .onAppear {
            transactionViewModel.fetchCategories()
        }
    }
    
    private var incomeCategories: [Category] {
        transactionViewModel.categories.filter { $0.type == "income" }
    }
    
    private var expenseCategories: [Category] {
        transactionViewModel.categories.filter { $0.type == "expense" }
    }
    
    private func deleteCategory(_ category: Category) {
        let context = PersistenceController.shared.container.viewContext
        context.delete(category)
        PersistenceController.shared.save()
        transactionViewModel.fetchCategories()
    }
}

struct CategoryManagementRow: View {
    let category: Category
    
    var body: some View {
        HStack {
            Image(systemName: category.icon ?? "dollarsign.circle")
                .font(.title3)
                .foregroundColor(Color(category.color ?? "blue"))
                .frame(width: 30)
            
            Text(category.name ?? "Unknown Category")
                .font(.body)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct AddCategoryView: View {
    @ObservedObject var viewModel: TransactionViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var selectedIcon = "dollarsign.circle"
    @State private var selectedColor = "blue"
    @State private var selectedType: TransactionType = .expense
    
    private let availableIcons = [
        "dollarsign.circle", "creditcard.fill", "banknote.fill", "cart.fill",
        "fork.knife", "car.fill", "house.fill", "gamecontroller.fill",
        "book.fill", "heart.fill", "airplane", "gift.fill"
    ]
    
    private let availableColors = [
        "blue", "green", "red", "orange", "purple", "pink",
        "yellow", "indigo", "cyan", "mint", "teal", "brown"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Category Details") {
                    TextField("Category Name", text: $name)
                    
                    Picker("Type", selection: $selectedType) {
                        ForEach(TransactionType.allCases, id: \.self) { type in
                            Text(type.rawValue.capitalized).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Button(action: { selectedIcon = icon }) {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundColor(selectedIcon == icon ? .white : Color(selectedColor))
                                    .frame(width: 40, height: 40)
                                    .background(selectedIcon == icon ? Color(selectedColor) : Color(selectedColor).opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
                        ForEach(availableColors, id: \.self) { color in
                            Button(action: { selectedColor = color }) {
                                Circle()
                                    .fill(Color(color))
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 2)
                                    )
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Add Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCategory()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveCategory() {
        let context = PersistenceController.shared.container.viewContext
        let category = NSEntityDescription.insertNewObject(forEntityName: "Category", into: context) as! Category
        
        category.setValue(UUID(), forKey: "id")
        category.setValue(name, forKey: "name")
        category.setValue(selectedIcon, forKey: "icon")
        category.setValue(selectedColor, forKey: "color")
        category.setValue(selectedType.rawValue, forKey: "type")
        
        PersistenceController.shared.save()
        viewModel.fetchCategories()
        dismiss()
    }
}

struct EditCategoryView: View {
    let category: Category
    @ObservedObject var viewModel: TransactionViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var selectedIcon = "dollarsign.circle"
    @State private var selectedColor = "blue"
    
    private let availableIcons = [
        "dollarsign.circle", "creditcard.fill", "banknote.fill", "cart.fill",
        "fork.knife", "car.fill", "house.fill", "gamecontroller.fill",
        "book.fill", "heart.fill", "airplane", "gift.fill"
    ]
    
    private let availableColors = [
        "blue", "green", "red", "orange", "purple", "pink",
        "yellow", "indigo", "cyan", "mint", "teal", "brown"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Category Details") {
                    TextField("Category Name", text: $name)
                    
                    HStack {
                        Text("Type")
                        Spacer()
                        Text(category.type?.capitalized ?? "Unknown")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Button(action: { selectedIcon = icon }) {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundColor(selectedIcon == icon ? .white : Color(selectedColor))
                                    .frame(width: 40, height: 40)
                                    .background(selectedIcon == icon ? Color(selectedColor) : Color(selectedColor).opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
                        ForEach(availableColors, id: \.self) { color in
                            Button(action: { selectedColor = color }) {
                                Circle()
                                    .fill(Color(color))
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 2)
                                    )
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateCategory()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                loadCategoryData()
            }
        }
    }
    
    private func loadCategoryData() {
        name = category.value(forKey: "name") as? String ?? ""
        selectedIcon = category.value(forKey: "icon") as? String ?? "dollarsign.circle"
        selectedColor = category.value(forKey: "color") as? String ?? "blue"
    }
    
    private func updateCategory() {
        category.setValue(name, forKey: "name")
        category.setValue(selectedIcon, forKey: "icon")
        category.setValue(selectedColor, forKey: "color")
        
        PersistenceController.shared.save()
        viewModel.fetchCategories()
        dismiss()
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Spacer()

                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.tint)

                Text("Finance Tracker")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Version 1.0.0")
                    .foregroundStyle(.secondary)

                Text("Track income, expenses, budgets, and reports.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
