//
//  BillRemindersView.swift
//  Finance app tracker
//

import SwiftUI

struct BillRemindersView: View {
    @ObservedObject private var store = BillReminderStore.shared
    @State private var showingAddReminder = false
    @State private var editingReminder: BillReminder?

    var body: some View {
        List {
            if store.reminders.isEmpty {
                ContentUnavailableView(
                    "No Bill Reminders",
                    systemImage: "bell.slash",
                    description: Text("Tap + to add a bill reminder.")
                )
            } else {
                ForEach(store.reminders) { reminder in
                    BillReminderRow(reminder: reminder)
                        .contentShape(Rectangle())
                        .onTapGesture { editingReminder = reminder }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button("Delete", role: .destructive) {
                                store.delete(reminder)
                                HapticManager.shared.mediumImpact()
                            }
                        }
                }
            }
        }
        .navigationTitle("Bill Reminders")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddReminder = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddReminder) {
            BillReminderFormView(reminder: nil)
        }
        .sheet(item: $editingReminder) { reminder in
            BillReminderFormView(reminder: reminder)
        }
    }
}

struct BillReminderRow: View {
    let reminder: BillReminder

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: reminder.isEnabled ? "bell.fill" : "bell.slash")
                .foregroundColor(reminder.isEnabled ? .orange : .secondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.headline)
                Text(reminder.dueDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(CurrencyFormatter.string(from: reminder.amount))
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 4)
    }
}

struct BillReminderFormView: View {
    let reminder: BillReminder?
    @ObservedObject private var store = BillReminderStore.shared
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var amount = ""
    @State private var dueDate = Date().addingTimeInterval(86400)
    @State private var isEnabled = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Bill") {
                    TextField("Title", text: $title)
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                }
                Section {
                    Toggle("Enabled", isOn: $isEnabled)
                }
            }
            .navigationTitle(reminder == nil ? "Add Reminder" : "Edit Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(title.isEmpty || Double(amount) == nil)
                }
            }
            .onAppear { load() }
        }
    }

    private func load() {
        guard let reminder else { return }
        title = reminder.title
        amount = String(reminder.amount)
        dueDate = reminder.dueDate
        isEnabled = reminder.isEnabled
    }

    private func save() {
        guard let amountValue = Double(amount) else { return }
        let item = BillReminder(
            id: reminder?.id ?? UUID(),
            title: title,
            amount: amountValue,
            dueDate: dueDate,
            isEnabled: isEnabled
        )
        store.save(item)
        HapticManager.shared.successNotification()
        dismiss()
    }
}
