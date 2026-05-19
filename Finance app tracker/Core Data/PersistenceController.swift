//
//  PersistenceController.swift
//  Finance app tracker
//

import CoreData
import Foundation

class PersistenceController: ObservableObject {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "FinanceTracker")

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Core Data error: \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    func save() {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Core Data save error: \(nsError), \(nsError.userInfo)")
            }
        }
    }

    func seedDefaultCategoriesIfNeeded() {
        let context = container.viewContext
        let request: NSFetchRequest<Category> = Category.fetchRequest()

        guard (try? context.count(for: request)) == 0 else { return }

        let expenseCategories = [
            ("Food & Dining", "fork.knife", "orange"),
            ("Transportation", "car.fill", "blue"),
            ("Shopping", "bag.fill", "purple"),
            ("Entertainment", "tv.fill", "pink"),
            ("Bills & Utilities", "bolt.fill", "red"),
            ("Healthcare", "cross.fill", "green"),
            ("Education", "book.fill", "indigo"),
            ("Travel", "airplane", "cyan")
        ]

        let incomeCategories = [
            ("Salary", "dollarsign.circle.fill", "green"),
            ("Freelance", "laptopcomputer", "blue"),
            ("Investment", "chart.line.uptrend.xyaxis", "purple"),
            ("Other Income", "plus.circle.fill", "orange")
        ]

        for (name, icon, color) in expenseCategories {
            let category = Category(context: context)
            category.id = UUID()
            category.name = name
            category.icon = icon
            category.color = color
            category.type = "expense"
        }

        for (name, icon, color) in incomeCategories {
            let category = Category(context: context)
            category.id = UUID()
            category.name = name
            category.icon = icon
            category.color = color
            category.type = "income"
        }

        save()
    }
}
