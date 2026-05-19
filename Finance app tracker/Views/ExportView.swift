//
//  ExportView.swift
//  Finance app tracker
//

import SwiftUI

struct ExportView: View {
    let transactions: [Transaction]
    let categories: [Category]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFormat: ExportFormat = .csv
    @State private var showingShareSheet = false
    @State private var exportURL: URL?

    private var categoryLookup: [UUID: Category] {
        Dictionary(uniqueKeysWithValues: categories.compactMap { cat in
            cat.id.map { ($0, cat) }
        })
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Export Format")
                        .font(.headline)
                        .fontWeight(.semibold)

                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        ExportFormatRow(format: format, isSelected: selectedFormat == format)
                            .onTapGesture { selectedFormat = format }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Export Summary")
                        .font(.headline)
                        .fontWeight(.semibold)

                    HStack {
                        Text("Total Transactions:")
                        Spacer()
                        Text("\(transactions.count)")
                            .fontWeight(.medium)
                    }

                    HStack {
                        Text("Date Range:")
                        Spacer()
                        Text(dateRangeText)
                            .fontWeight(.medium)
                    }

                    HStack {
                        Text("File Format:")
                        Spacer()
                        Text(selectedFormat.rawValue.uppercased())
                            .fontWeight(.medium)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                Spacer()

                Button(action: exportData) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export Data")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .disabled(transactions.isEmpty)
            }
            .padding()
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }

    private var dateRangeText: String {
        guard !transactions.isEmpty else { return "No transactions" }

        let dates = transactions.compactMap(\.date).sorted()
        guard let earliest = dates.first, let latest = dates.last else { return "Unknown" }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        if Calendar.current.isDate(earliest, inSameDayAs: latest) {
            return formatter.string(from: earliest)
        }
        return "\(formatter.string(from: earliest)) - \(formatter.string(from: latest))"
    }

    private func exportData() {
        switch selectedFormat {
        case .csv: exportToCSV()
        case .pdf: exportToPDF()
        }
        HapticManager.shared.successNotification()
    }

    private func exportToCSV() {
        let csvContent = generateCSVContent()
        let fileName = "finance_transactions_\(fileNameDate()).csv"
        writeAndShare(content: csvContent, fileName: fileName)
    }

    private func exportToPDF() {
        guard let data = PDFExporter.createReport(transactions: transactions, categories: categories) else { return }
        let fileName = "finance_report_\(fileNameDate()).pdf"
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
        do {
            try data.write(to: url)
            exportURL = url
            showingShareSheet = true
        } catch {
            print("Error exporting PDF: \(error)")
        }
    }

    private func writeAndShare(content: String, fileName: String) {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            exportURL = url
            showingShareSheet = true
        } catch {
            print("Error exporting file: \(error)")
        }
    }

    private func fileNameDate() -> String {
        Date().formatted(.dateTime.year().month().day())
    }

    private func generateCSVContent() -> String {
        var csvContent = "Date,Title,Category,Type,Amount,Notes\n"
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short

        for transaction in transactions.sorted(by: { ($0.date ?? Date()) > ($1.date ?? Date()) }) {
            let date = formatter.string(from: transaction.date ?? Date())
            let title = (transaction.title ?? "").replacingOccurrences(of: ",", with: ";")
            let category = transaction.categoryID.flatMap { categoryLookup[$0]?.name } ?? "Unknown"
            let type = transaction.type?.capitalized ?? ""
            let amount = String(transaction.amount)
            let notes = (transaction.notes ?? "").replacingOccurrences(of: ",", with: ";")
            csvContent += "\(date),\(title),\(category),\(type),\(amount),\(notes)\n"
        }
        return csvContent
    }
}

struct ExportFormatRow: View {
    let format: ExportFormat
    let isSelected: Bool

    var body: some View {
        HStack {
            Image(systemName: format.icon)
                .font(.title3)
                .foregroundColor(format.color)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(format.title)
                    .font(.headline)
                Text(format.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .blue : .secondary)
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(8)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

enum ExportFormat: String, CaseIterable {
    case csv
    case pdf

    var title: String {
        switch self {
        case .csv: return "CSV File"
        case .pdf: return "PDF Report"
        }
    }

    var description: String {
        switch self {
        case .csv: return "Comma-separated values"
        case .pdf: return "PDF document"
        }
    }

    var icon: String {
        switch self {
        case .csv: return "tablecells"
        case .pdf: return "doc.text"
        }
    }

    var color: Color {
        switch self {
        case .csv: return .green
        case .pdf: return .red
        }
    }
}
