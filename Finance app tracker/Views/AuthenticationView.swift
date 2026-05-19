//
//  AuthenticationView.swift
//  Finance app tracker
//

import SwiftUI

struct AuthenticationView: View {
    @ObservedObject var authViewModel = AuthenticationViewModel.shared

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tint)

            VStack(spacing: 8) {
                Text("Finance Tracker")
                    .font(.title)
                    .fontWeight(.semibold)

                Text("Unlock to view your data")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: { authViewModel.authenticate() }) {
                Label("Unlock with \(authViewModel.biometricTypeString)", systemImage: authViewModel.biometricIcon)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 32)

            if let error = authViewModel.authenticationError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    AuthenticationView()
}
