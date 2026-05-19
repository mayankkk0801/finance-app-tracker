//
//  AuthenticationViewModel.swift
//  Finance app tracker
//

import Foundation
import LocalAuthentication
import Combine

@MainActor
class AuthenticationViewModel: ObservableObject {
    static let shared = AuthenticationViewModel()

    @Published var isAuthenticated = false
    @Published var authenticationError: String?
    @Published var biometricType: LABiometryType = .none

    private let context = LAContext()

    private init() {
        checkBiometricAvailability()
        isAuthenticated = !AppSettings.shared.biometricsEnabled
    }

    func checkBiometricAvailability() {
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometricType = context.biometryType
        } else {
            biometricType = .none
        }
    }

    func authenticate() {
        guard AppSettings.shared.biometricsEnabled else {
            isAuthenticated = true
            authenticationError = nil
            return
        }

        let policy: LAPolicy = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
            ? .deviceOwnerAuthenticationWithBiometrics
            : .deviceOwnerAuthentication

        let reason = "Authenticate to access your financial data"

        context.evaluatePolicy(policy, localizedReason: reason) { [weak self] success, error in
            Task { @MainActor in
                if success {
                    self?.isAuthenticated = true
                    self?.authenticationError = nil
                    HapticManager.shared.successNotification()
                } else {
                    self?.authenticationError = error?.localizedDescription ?? "Authentication failed"
                    self?.isAuthenticated = false
                    HapticManager.shared.errorNotification()
                }
            }
        }
    }

    func logout() {
        isAuthenticated = false
        authenticationError = nil
        HapticManager.shared.lightImpact()
    }

    func refreshLockState() {
        if AppSettings.shared.biometricsEnabled {
            isAuthenticated = false
        } else {
            isAuthenticated = true
        }
    }

    var biometricTypeString: String {
        switch biometricType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default: return "Passcode"
        }
    }

    var biometricIcon: String {
        switch biometricType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        default: return "lock.fill"
        }
    }
}
