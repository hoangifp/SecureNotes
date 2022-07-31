//
//  Global.swift
//  SecureNotes
//
//

import Foundation

struct Global {
    let encryptedHash: Data
    let encryptedSalt: Data
    let encryptedIV: Data
    let encryptedBiometrics: Data?
    let encryptedBioIV: Data?
    let encryptedBioServiceId: Data?
}
