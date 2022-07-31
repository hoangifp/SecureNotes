//
//  KeychainBiometric.swift
//  SecureNotes
//
//

import Foundation
import LocalAuthentication
import IOSSecuritySuite

struct KeychainError: Error {
    var status: OSStatus
    
    var localizedDescription: String {
        return SecCopyErrorMessageString(status, nil) as String? ?? "Unknown error."
    }
}

final class KeychainBiometric {
    /// The server we are accessing with the credentials.
    let account = "com.example.account"
    
    // MARK: - Keychain Access
    @objc func addCredentials(_ data: Data, serviceId: Data) throws {
#if !DEBUG
        IOSSecuritySuite.denyDebugger()
        let amIRuntimeHooked = IOSSecuritySuite.amIRuntimeHooked(dyldWhiteList: [],
                                                                 detectionClass: KeychainBiometric.self,
                                                                 selector: #selector(KeychainBiometric.addCredentials(_:serviceId:)),
                                                                 isClassMethod: false)
        if amIRuntimeHooked {
            abort()
        }
#endif
        // Create an access control instance that dictates how the item can be read later.
        let access = SecAccessControlCreateWithFlags(nil, // Use the default allocator.
                                                     kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                                     .userPresence,
                                                     nil) // Ignore any error.
        
        let context = LAContext()
        
        // Build the query for use in the add operation.
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: account.sha256(),
                                    kSecAttrService as String: serviceId,
                                    kSecAttrAccessControl as String: access as Any,
                                    kSecUseAuthenticationContext as String: context,
                                    kSecValueData as String: data]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError(status: status) }
    }
    
    @objc func readCredentials(serviceId: Data) throws -> Data {
#if !DEBUG
        IOSSecuritySuite.denyDebugger()
        let amIRuntimeHooked = IOSSecuritySuite.amIRuntimeHooked(dyldWhiteList: [],
                                                                 detectionClass: KeychainBiometric.self,
                                                                 selector: #selector(KeychainBiometric.readCredentials(serviceId:)),
                                                                 isClassMethod: false)
        if amIRuntimeHooked {
            abort()
        }
#endif
        let context = LAContext()
        context.localizedReason = "Access your password on the keychain"
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: account.sha256(),
                                    kSecAttrService as String: serviceId,
                                    kSecMatchLimit as String: kSecMatchLimitOne,
                                    kSecReturnAttributes as String: true,
                                    kSecUseAuthenticationContext as String: context,
                                    kSecReturnData as String: true]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else { throw KeychainError(status: status) }
        
        guard let existingItem = item as? [String: Any],
              let biometricKey = existingItem[kSecValueData as String] as? Data
        else {
            throw KeychainError(status: errSecInternalError)
        }
        
        return biometricKey
    }
    
    func deleteCredentials(serviceId: Data) throws {
#if !DEBUG
        IOSSecuritySuite.denyDebugger()
#endif
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrService as String: serviceId,
                                    kSecAttrAccount as String: account.sha256()]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess else { throw KeychainError(status: status) }
    }
}
