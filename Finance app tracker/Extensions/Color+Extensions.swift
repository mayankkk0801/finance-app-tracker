//
//  Color+Extensions.swift
//  Finance app tracker
//
//  Created by MAYANK GAHLOT on 23/08/25.
//

import SwiftUI

extension Color {
    init(_ colorName: String) {
        switch colorName.lowercased() {
        case "blue":
            self = .blue
        case "green":
            self = .green
        case "red":
            self = .red
        case "orange":
            self = .orange
        case "purple":
            self = .purple
        case "pink":
            self = .pink
        case "yellow":
            self = .yellow
        case "indigo":
            self = .indigo
        case "cyan":
            self = .cyan
        case "mint":
            self = .mint
        case "teal":
            self = .teal
        case "brown":
            self = .brown
        default:
            self = .blue
        }
    }
    
    // Custom colors for the app
    static let primaryBackground = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let cardBackground = Color(.systemGray6)
    
    // Income/Expense colors
    static let incomeGreen = Color.green
    static let expenseRed = Color.red
    
    // Budget status colors
    static let budgetOnTrack = Color.green
    static let budgetWarning = Color.orange
    static let budgetExceeded = Color.red
}

extension View {
    func cardStyle() -> some View {
        self
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}
