//
//  SpendingChart.swift
//  Finance app tracker
//
//  Created by MAYANK GAHLOT on 23/08/25.
//

import SwiftUI
import Charts

struct SpendingChart: View {
    let categorySpending: [(Category, Double)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if categorySpending.isEmpty {
                EmptyChartView()
            } else {
                HStack(spacing: 20) {
                    // Pie Chart
                    Chart(categorySpending, id: \.0.id) { category, amount in
                        SectorMark(
                            angle: .value("Amount", amount),
                            innerRadius: .ratio(0.4),
                            angularInset: 2
                        )
                        .foregroundStyle(ColorExtension.color(from: category.color ?? "blue"))
                        .opacity(0.8)
                    }
                    .frame(width: 120, height: 120)
                    .animation(.easeInOut(duration: 0.6), value: categorySpending.count)
                    
                    // Legend
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(categorySpending.prefix(5), id: \.0.id) { category, amount in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(ColorExtension.color(from: category.color ?? "blue"))
                                    .frame(width: 12, height: 12)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(category.name ?? "Unknown")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .lineLimit(1)
                                    
                                    Text(CurrencyFormatter.string(from: amount))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                        }
                        
                        if categorySpending.count > 5 {
                            Text("+ \(categorySpending.count - 5) more")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding()
    }
}

struct EmptyChartView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.pie.fill")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("No Expenses Yet")
                .font(.headline)
                .fontWeight(.medium)
            
            Text("Add some expense transactions to see your spending breakdown")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Color Helper
struct ColorExtension {
    static func color(from colorName: String) -> Color {
        switch colorName.lowercased() {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "cyan": return .cyan
        case "indigo": return .indigo
        default: return .blue
        }
    }
}

#Preview {
    let sampleCategories = [
        (Category(), 5000.0),
        (Category(), 3000.0),
        (Category(), 2000.0)
    ]
    
    SpendingChart(categorySpending: sampleCategories)
        .frame(height: 200)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding()
}
