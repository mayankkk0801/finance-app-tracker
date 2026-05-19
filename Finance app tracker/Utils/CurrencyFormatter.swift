//
//  CurrencyFormatter.swift
//  Finance app tracker
//

import Foundation

enum CurrencyFormatter {
    static let code = "USD"

    static func string(from amount: Double) -> String {
        amount.formatted(.currency(code: code))
    }

    static func signedString(from amount: Double, isIncome: Bool) -> String {
        let prefix = isIncome ? "+" : "-"
        return prefix + abs(amount).formatted(.currency(code: code))
    }
}
