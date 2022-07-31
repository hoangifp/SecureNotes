//
//  NoteError.swift
//  SecureNotes
//
//

import Foundation

enum NoteServiceError: Error {
    case wrongUserOrPassword
    case userNotLogin
    case userNotRegistered
    case logicError
    case cryptoError(String)
    case databaseError
    case keychainError(String)
}

extension NoteServiceError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .wrongUserOrPassword:
            return "Wrong Username or Pin"
        case .userNotLogin:
            return "Please login again"
        case .userNotRegistered:
            return "Something went wrong, please relaunch the application"
        case .logicError:
            return "Something went wrong, please relaunch the application"
        case .cryptoError(let string):
            return "Crypto computing error. \(string)"
        case .databaseError:
            return "Error connecting database, please relaunch the application"
        case .keychainError(let string):
            return "Keychain error. \(string)"
        }
    }
}

enum SecureEnclaveError: Error {
    case failedToDecrypt
    case failedToEncrypt
    case unableToLoadKey
}

extension SecureEnclaveError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .failedToDecrypt:
            return "Failed to decrypt"
        case .failedToEncrypt:
            return "Failed to encrypt"
        case .unableToLoadKey:
            return "Unable to load key"
        }
    }
}

enum DatabaseError: Error {
    case dbError(String)
}

extension DatabaseError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .dbError(let string):
            return "Database error \(string)"
        }
    }
}
