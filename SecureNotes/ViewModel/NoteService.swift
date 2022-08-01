//
//  CryptoService.swift
//  SecureNotes
//
//

import Foundation
import CryptoSwift
import IOSSecuritySuite

final class NoteService {
    static let shared = NoteService()
    private let database = Database.shared
    private let secureEnclave = SecureEnclave.shared
    private lazy var keychainBiometric = KeychainBiometric()
    
    private var encryptedKey: Data?
    private var encryptedIV: Data?
    
    init() {
        try? database.setupDatabase()
    }
    
    // MARK: REGISTER AND LOGIN
    
    func registerUserAccount(with username: inout Data, numericPin: inout Data) throws {
#if !DEBUG
        IOSSecuritySuite.denyDebugger()
#endif
        // Generate AES-GCM key using salt + username + pin
        var salt = Data.random32BytesData()
        var data = Data()
        data.append(contentsOf: salt)
        data.append(contentsOf: username.bytes)
        data.append(contentsOf: numericPin.bytes)
        
        // Generate random IV value to re-generate AES-GCM instance
        var iv = Data.random32BytesData()
        
        do {
            defer {
                // Clean up sensitive data before leaving the function
                username.wipe()
                numericPin.wipe()
                data.wipe()
                iv.wipe()
                salt.wipe()
            }
            // Encrypt key and iv in Secure Enclave to be stored during current active session.
            // When system need to encrypt/decrypt notes, just regenerate AES-GCM using key and iv that are decrypted from secure enclave
            encryptedKey = try secureEnclave.encrypt(rawData: data.sha256())
            encryptedIV = try secureEnclave.encrypt(rawData: iv)
            
            // Other important data will be encrypted with Secure Enclave before storing to the database
            // Store salt+username+pin sha512 hash for next login comparison
            var encryptedSalt = try secureEnclave.encrypt(rawData: salt)
            var encryptedHash = try secureEnclave.encrypt(rawData: data.sha512())
            
            try database.createGlobalData(encryptedHash: encryptedHash,
                                          encryptedSalt: encryptedSalt,
                                          encryptedIV: encryptedIV!)
            
            encryptedSalt.wipe()
            encryptedHash.wipe()
        } catch {
            if let error = error as? SecureEnclaveError {
                throw NoteServiceError.cryptoError(error.localizedDescription)
            } else {
                throw NoteServiceError.databaseError
            }
        }
    }
    
    func login(with username: inout Data, numericPin: inout Data) throws {
        // First, we need to compare username and numeric pin with hash data
#if !DEBUG
        IOSSecuritySuite.denyDebugger()
#endif
        do {
            defer {
                username.wipe()
                numericPin.wipe()
            }
            var global = try database.queryGlobalData()
            if let global = global {
                var salt = try secureEnclave.decrypt(cypher: global.encryptedSalt)
                var data = Data()
                data.append(contentsOf: salt)
                data.append(contentsOf: username.bytes)
                data.append(contentsOf: numericPin.bytes)
                
                let previousHash = try secureEnclave.decrypt(cypher: global.encryptedHash)
                if data.sha512().elementsEqual(previousHash) {
                    // Can login
                    encryptedIV = global.encryptedIV
                    encryptedKey = try secureEnclave.encrypt(rawData: data.sha256())
                } else {
                    throw NoteServiceError.wrongUserOrPassword
                }
                data.wipe()
                salt.wipe()
            } else {
                throw NoteServiceError.userNotRegistered
            }
            global = nil
        } catch {
            if let error = error as? SecureEnclaveError {
                throw NoteServiceError.cryptoError(error.localizedDescription)
            } else {
                throw error
            }
        }
    }
    
    func isRegistered() -> Bool {
        do {
            return try database.hasGlobalData()
        } catch {
            return false
        }
    }
    
    // MARK: BIOMETRICS HELPERS
    func isBiometricEnabled() -> Bool {
        do {
            return try database.hasBiometricData()
        } catch {
            return false
        }
    }
    
    func authenticateWithBiometric() throws {
#if !DEBUG
        IOSSecuritySuite.denyDebugger()
#endif
        do {
            // Check value in database should exists
            var global = try database.queryGlobalData()
            guard let encryptedBioServiceId = global?.encryptedBioServiceId,
                  let encryptedMasterKey = global?.encryptedBiometrics,
                  let encryptedBioIV = global?.encryptedBioIV
            else {
                throw NoteServiceError.logicError
            }
            
            // Authenticate user to get the AES-CBC key from keychain
            var bioServiceId = try secureEnclave.decrypt(cypher: encryptedBioServiceId)
            var encryptedBioKey = try keychainBiometric.readCredentials(serviceId: bioServiceId)
            
            var bioKey = try secureEnclave.decrypt(cypher: encryptedBioKey)
            var bioIV = try secureEnclave.decrypt(cypher: encryptedBioIV)
            // Construct AES-CBC with bioKey from keychain and bioIV from database
            let aes = try AES(key: bioIV.bytes, blockMode: CBC(iv: bioKey.bytes), padding: .pkcs7)
            // Decrypt master key from database using AES-CBC
            var masterKeyBytes = try aes.decrypt(encryptedMasterKey.bytes)
            encryptedKey = Data(bytes: masterKeyBytes, count: masterKeyBytes.count)
            encryptedIV = global?.encryptedIV
            global = nil
            encryptedBioKey.wipe()
            bioServiceId.wipe()
            bioKey.wipe()
            bioIV.wipe()
            masterKeyBytes.removeAll()
        } catch {
            if let error = error as? SecureEnclaveError {
                throw NoteServiceError.cryptoError(error.localizedDescription)
            } else if let error = error as? KeychainError {
                throw NoteServiceError.keychainError(error.localizedDescription)
            } else {
                throw error
            }
        }
    }
    
    func enableLoginWithBiometrics() throws {
#if !DEBUG
        IOSSecuritySuite.denyDebugger()
#endif
        do {
            if isBiometricEnabled() {
                throw NoteServiceError.logicError
            } else {
                // Generate random AES-CBC key and iv to protect master key data
                // The AES-CBC key will be stored in keychain, and only accessible with user's presence
                // The AES-CBC IV will be stored in database for later access
                // Both will be encrypted with secure enclave before storing
                guard var masterKey = encryptedKey else {
                    throw NoteServiceError.userNotLogin
                }
                var bioIV = Data.random16BytesData()
                var bioKey = Data.random16BytesData()
                var bioServiceId = Data.random32BytesData()
                
                let aes = try AES(key: bioIV.bytes, blockMode: CBC(iv: bioKey.bytes), padding: .pkcs7)
                
                // Encrypt master key with AES-CBC
                var encryptedMasterKey = try aes.encrypt(masterKey.bytes)
                
                // Store biometric key to keychain biometric with bioServiceId
                var encryptedBioKey = try secureEnclave.encrypt(rawData: bioKey)
                try keychainBiometric.addCredentials(encryptedBioKey, serviceId: bioServiceId)
                
                // Store encrypted master key and bio IV and bio serviceId to database
                var encryptedBioIV = try secureEnclave.encrypt(rawData: bioIV)
                var encryptedBioServiceId = try secureEnclave.encrypt(rawData: bioServiceId)
                try database.storeBiometricData(encryptedBiometrics: Data(bytes: encryptedMasterKey,
                                                                          count: encryptedMasterKey.count),
                                                encryptedBioIV: encryptedBioIV,
                                                encryptedBioServiceId: encryptedBioServiceId)
                
                masterKey.wipe()
                bioIV.wipe()
                bioKey.wipe()
                encryptedMasterKey.removeAll()
                encryptedBioIV.wipe()
                encryptedBioKey.wipe()
                bioServiceId.wipe()
                encryptedBioServiceId.wipe()
            }
        } catch {
            if let error = error as? SecureEnclaveError {
                throw NoteServiceError.cryptoError(error.localizedDescription)
            } else if let error = error as? KeychainError {
                throw NoteServiceError.keychainError(error.localizedDescription)
            } else {
                throw error
            }
        }
    }
    
    // MARK: ENCRYPT / DECRYPT DATA USING CACHE KEYS
    
    func decrypt(cypher: Data) throws -> Data? {
#if !DEBUG
        IOSSecuritySuite.denyDebugger()
#endif
        guard let keyEC = encryptedIV, let ivEC = encryptedIV else {
            throw NoteServiceError.userNotLogin
        }
        do {
            var key = try secureEnclave.decrypt(cypher: keyEC)
            var iv = try secureEnclave.decrypt(cypher: ivEC)
            defer {
                key.wipe()
                iv.wipe()
            }
            // In combined mode, the authentication tag is appended to the encrypted message. This is usually what you want.
            let gcm = GCM(iv: iv.bytes, mode: .combined)
            let aes = try AES(key: key.bytes, blockMode: gcm, padding: .noPadding)
            
            let data = try aes.decrypt(cypher.bytes)
            return Data(bytes: data, count: data.count)
        } catch {
            throw NoteServiceError.cryptoError(error.localizedDescription)
        }
    }
    
    func encrypt(rawData: Data) throws -> Data? {
#if !DEBUG
        IOSSecuritySuite.denyDebugger()
#endif
        guard let keyEC = encryptedIV, let ivEC = encryptedIV else {
            throw NoteServiceError.userNotLogin
        }
        do {
            var key = try secureEnclave.decrypt(cypher: keyEC)
            var iv = try secureEnclave.decrypt(cypher: ivEC)
            defer {
                key.wipe()
                iv.wipe()
            }
            // In combined mode, the authentication tag is appended to the encrypted message. This is usually what you want.
            let gcm = GCM(iv: iv.bytes, mode: .combined)
            let aes = try AES(key: key.bytes, blockMode: gcm, padding: .noPadding)
            let data = try aes.encrypt(rawData.bytes)
            return Data(bytes: data, count: data.count)
        } catch {
            throw NoteServiceError.cryptoError(error.localizedDescription)
        }
    }
    
    // MARK: NOTES
    
    func getNotes() throws -> [Note] {
#if !DEBUG
        IOSSecuritySuite.denyDebugger()
#endif
        var notes = [Note]()
        guard let keyEC = encryptedIV, let ivEC = encryptedIV else {
            throw NoteServiceError.userNotLogin
        }
        
        do {
            var encryptedNotes = try database.getAllEncryptedNotes()
            // Decrypt notes
            var key = try secureEnclave.decrypt(cypher: keyEC)
            var iv = try secureEnclave.decrypt(cypher: ivEC)
            defer {
                key.wipe()
                iv.wipe()
            }
            // In combined mode, the authentication tag is appended to the encrypted message. This is usually what you want.
            let gcm = GCM(iv: iv.bytes, mode: .combined)
            let aes = try AES(key: key.bytes, blockMode: gcm, padding: .noPadding)
            try encryptedNotes.forEach({ aNote in
                var plainNote = aNote
                let titleData = try aes.decrypt(aNote.encryptedTitle.bytes)
                plainNote.title = String(data: Data(bytes: titleData, count: titleData.count),
                                         encoding: .utf8)!
                
                let contentData = try aes.decrypt(aNote.encryptedTitle.bytes)
                plainNote.content = String(data: Data(bytes: contentData, count: titleData.count),
                                           encoding: .utf8)!
                
                notes.append(plainNote)
            })
            key.wipe()
            iv.wipe()
            encryptedNotes.removeAll()
        } catch {
            throw NoteServiceError.cryptoError(error.localizedDescription)
        }
        return notes
    }
    
    func insertNote(_ note: Note) throws -> Int64 {
#if !DEBUG
        IOSSecuritySuite.denyDebugger()
#endif
        do {
            guard let cypherTitle = try encrypt(rawData: note.title.data(using: .utf8)!),
                  let cypherContent = try encrypt(rawData: note.content.data(using: .utf8)!)else {
                throw NoteServiceError.cryptoError("")
            }
            let noteId = try database.insertNote(encryptedTitle: Data(bytes: cypherTitle.bytes, count: cypherTitle.count),
                                                 encryptedContent: Data(bytes: cypherContent.bytes, count: cypherContent.count),
                                                 createdDate: note.created,
                                                 modifiedDate: Date())
            return noteId
        } catch {
            if let error = error as? SecureEnclaveError {
                throw NoteServiceError.cryptoError(error.localizedDescription)
            } else {
                throw error
            }
        }
    }
    
    func updateNote(_ note: Note) throws {
#if !DEBUG
        IOSSecuritySuite.denyDebugger()
#endif
        do {
            guard let cypherTitle = try encrypt(rawData: note.title.data(using: .utf8)!),
                  let cypherContent = try encrypt(rawData: note.content.data(using: .utf8)!),
                  let noteId = note.id else {
                throw NoteServiceError.cryptoError("")
            }
            try database.updateNote(noteId: noteId,
                                    encryptedTitle: Data(bytes: cypherTitle.bytes, count: cypherTitle.count),
                                    encryptedContent: Data(bytes: cypherContent.bytes, count: cypherContent.count),
                                    modifiedDate: Date())
        } catch {
            if let error = error as? SecureEnclaveError {
                throw NoteServiceError.cryptoError(error.localizedDescription)
            } else {
                throw error
            }
        }
    }
    
    func deleteNote(nodeId: Int64) throws {
#if !DEBUG
        IOSSecuritySuite.denyDebugger()
#endif
        do {
            try database.deleteNote(noteId: nodeId)
        } catch {
            throw NoteServiceError.databaseError
        }
    }
    
    // MARK: CLEAR CACHE DATA, THE USER HAS TO LOGIN AGAIN
    func clearCacheData() {
#if !DEBUG
        IOSSecuritySuite.denyDebugger()
#endif
        encryptedIV?.wipe()
        encryptedKey?.wipe()
    }
}
