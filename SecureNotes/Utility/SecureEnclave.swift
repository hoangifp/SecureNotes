//
//  SecureEnclave.swift
//  SecureNotes
//
//

import Foundation
import LocalAuthentication
import IOSSecuritySuite

final class SecureEnclave {
    static let shared = SecureEnclave()
    
    private var privateKey: SecKey?
    private var publicKey: SecKey?
    private var context = LAContext()
    
    // echo -n "SECURE_NOTES_KEY_ALIAS" | openssl sha256
    let keyTag = "55be276f35466dd10e0dc411e44a4c2e4874f63f76d97af03ab76b4792cd7708"
    
    lazy var access =
    SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                    kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                    [.privateKeyUsage],
                                    nil)!   // Ignore error
    
    lazy var attributes: [String: Any] = {
        var attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeEC,
            kSecAttrKeySizeInBits as String: 256,
            kSecUseAuthenticationContext as String: context,
        ]
#if targetEnvironment(simulator)
        attributes[kSecPrivateKeyAttrs as String] = [
            kSecAttrIsPermanent as String: true,
            kSecAttrApplicationTag as String: keyTag,
        ]
#else
        attributes[kSecAttrTokenID as String] = kSecAttrTokenIDSecureEnclave
        attributes[kSecPrivateKeyAttrs as String] = [
            kSecAttrIsPermanent as String: true,
            kSecAttrApplicationTag as String: keyTag,
            kSecAttrAccessControl as String: access
        ]
#endif
        return attributes
    }()
    
    private func getKeys() {
#if !DEBUG
        IOSSecuritySuite.denyDebugger()
#endif
        do {
            try loadKey()
        } catch {
            do {
                try createKey()
            } catch {
    
            }
        }
    }
    
    func dropKeys() {
#if !DEBUG
        IOSSecuritySuite.denyDebugger()
#endif
        privateKey = nil
        publicKey = nil
        context = LAContext()
    }
    
    private func createKey() throws {
#if !DEBUG
        IOSSecuritySuite.denyDebugger()
#endif
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            throw error!.takeRetainedValue() as Error
        }
        
        publicKey = SecKeyCopyPublicKey(privateKey)
        self.privateKey = privateKey
    }
    
    private func loadKey() throws {
#if !DEBUG
        IOSSecuritySuite.denyDebugger()
#endif
        var key: CFTypeRef?
        let attributes: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyTag,
            kSecAttrKeyType as String: kSecAttrKeyTypeEC,
            kSecUseAuthenticationContext as String: context,
            kSecReturnRef as String: true,
            kSecAttrAccessControl as String: access
        ]
        let status = SecItemCopyMatching(attributes as CFDictionary, &key)
        
        guard status == errSecSuccess else {
            throw SecureEnclaveError.unableToLoadKey
        }
        
        let secKey = key as! SecKey
        publicKey = SecKeyCopyPublicKey(secKey)
        privateKey = secKey
    }
    
    @objc func encrypt(rawData: Data) throws -> Data {
#if !DEBUG
        IOSSecuritySuite.denyDebugger()
        let amIRuntimeHooked = IOSSecuritySuite.amIRuntimeHooked(dyldWhiteList: [],
                                                                 detectionClass: SecureEnclave.self,
                                                                 selector: #selector(SecureEnclave.encrypt(rawData:)),
                                                                 isClassMethod: false)
        if amIRuntimeHooked {
            abort()
        }
#endif
        if publicKey == nil {
            getKeys()
        }
        guard let publicKey = publicKey else { throw NSError() }
        var error: Unmanaged<CFError>?
        guard let cypherText = SecKeyCreateEncryptedData(publicKey,
                                                         .eciesEncryptionCofactorVariableIVX963SHA256AESGCM,
                                                         rawData as CFData,
                                                         &error) else {
            throw SecureEnclaveError.failedToDecrypt
        }
        
        return cypherText as Data
    }
    
    @objc func decrypt(cypher: Data) throws -> Data {
#if !DEBUG
        IOSSecuritySuite.denyDebugger()
        let amIRuntimeHooked = IOSSecuritySuite.amIRuntimeHooked(dyldWhiteList: [],
                                                                 detectionClass: SecureEnclave.self,
                                                                 selector: #selector(SecureEnclave.decrypt(cypher:)),
                                                                 isClassMethod: false)
        if amIRuntimeHooked {
            abort()
        }
#endif
        if privateKey == nil {
            getKeys()
        }
        guard let privateKey = privateKey else { throw NSError() }
        var error: Unmanaged<CFError>?
        guard let decryptData = SecKeyCreateDecryptedData( privateKey,
                                                           .eciesEncryptionCofactorVariableIVX963SHA256AESGCM,
                                                           cypher as CFData,
                                                           &error)
        else {
            throw SecureEnclaveError.failedToDecrypt
        }
        
        return decryptData as Data
    }
}
