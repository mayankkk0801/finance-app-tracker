//
//  MainTabView.swift
//  Finance app tracker
//

import SwiftUI

struct MainTabView: View {
    @ObservedObject private var authViewModel = AuthenticationViewModel.shared
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                TabView {
                    DashboardView()
                        .tabItem {
                            Image(systemName: "house.fill")
                            Text("Dashboard")
                        }

                    TransactionListView()
                        .tabItem {
                            Image(systemName: "list.bullet")
                            Text("Transactions")
                        }

                    BudgetListView()
                        .tabItem {
                            Image(systemName: "chart.pie.fill")
                            Text("Budgets")
                        }

                    ReportsView()
                        .tabItem {
                            Image(systemName: "chart.bar.fill")
                            Text("Reports")
                        }

                    SettingsView()
                        .tabItem {
                            Image(systemName: "gear")
                            Text("Settings")
                        }
                }
                .tint(.blue)
            } else {
                AuthenticationView()
            }
        }
        .preferredColorScheme(settings.appearance.colorScheme)
        .onAppear {
            if settings.biometricsEnabled && !authViewModel.isAuthenticated {
                authViewModel.authenticate()
            }
        }
        .onChange(of: settings.biometricsEnabled) {
            authViewModel.refreshLockState()
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(TransactionViewModel())
        .environmentObject(BudgetViewModel())
        .environmentObject(AppSettings.shared)
}
