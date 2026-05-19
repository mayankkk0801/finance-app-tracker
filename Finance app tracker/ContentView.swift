//
//  ContentView.swift
//  Finance app tracker
//
//  Created by MAYANK GAHLOT on 23/08/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .environmentObject(TransactionViewModel())
        .environmentObject(BudgetViewModel())
        .environmentObject(AppSettings.shared)
}
