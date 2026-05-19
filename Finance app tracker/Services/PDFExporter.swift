//
//  PDFExporter.swift
//  Finance app tracker
//

import UIKit
import CoreData

enum PDFExporter {
    static func createReport(
        transactions: [Transaction],
        categories: [Category],
        title: String = "Finance Tracker Report"
    ) -> Data? {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 48
        let lineHeight: CGFloat = 18
        var y = margin

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        let income = transactions.filter { $0.type == "income" }.reduce(0) { $0 + $1.amount }
        let expenses = transactions.filter { $0.type == "expense" }.reduce(0) { $0 + $1.amount }

        let categoryLookup = Dictionary(uniqueKeysWithValues: categories.compactMap { cat in
            cat.id.map { ($0, cat) }
        })

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        return renderer.pdfData { context in
            func beginPageIfNeeded(requiredHeight: CGFloat) {
                if y + requiredHeight > pageHeight - margin {
                    context.beginPage()
                    y = margin
                }
            }

            func draw(_ text: String, font: UIFont, color: UIColor = .label) {
                let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
                let size = (text as NSString).size(withAttributes: attrs)
                beginPageIfNeeded(requiredHeight: size.height + 4)
                (text as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: attrs)
                y += size.height + 6
            }

            context.beginPage()

            draw(title, font: .boldSystemFont(ofSize: 22))
            draw(Date().formatted(date: .abbreviated, time: .shortened), font: .systemFont(ofSize: 11), color: .secondaryLabel)
            y += 8

            draw("Summary", font: .boldSystemFont(ofSize: 14))
            draw("Transactions: \(transactions.count)", font: .systemFont(ofSize: 12))
            draw("Total Income: \(CurrencyFormatter.string(from: income))", font: .systemFont(ofSize: 12), color: .systemGreen)
            draw("Total Expenses: \(CurrencyFormatter.string(from: expenses))", font: .systemFont(ofSize: 12), color: .systemRed)
            draw("Net: \(CurrencyFormatter.string(from: income - expenses))", font: .boldSystemFont(ofSize: 12))
            y += 12

            draw("Transactions", font: .boldSystemFont(ofSize: 14))

            let sorted = transactions.sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
            for transaction in sorted {
                beginPageIfNeeded(requiredHeight: lineHeight * 4)
                let categoryName = transaction.categoryID.flatMap { categoryLookup[$0]?.name } ?? "Unknown"
                let typeLabel = transaction.type?.capitalized ?? "Unknown"
                let dateText = dateFormatter.string(from: transaction.date ?? Date())
                draw("\(transaction.title ?? "Untitled") — \(CurrencyFormatter.string(from: transaction.amount))", font: .boldSystemFont(ofSize: 11))
                draw("\(dateText) · \(categoryName) · \(typeLabel)", font: .systemFont(ofSize: 10), color: .secondaryLabel)
                if let notes = transaction.notes, !notes.isEmpty {
                    draw(notes, font: .italicSystemFont(ofSize: 10), color: .secondaryLabel)
                }
                y += 4
            }
        }
    }
}
