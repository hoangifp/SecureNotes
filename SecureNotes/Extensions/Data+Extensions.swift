//
//  DataExtensions.swift
//  SecureNotes
//
//

import Foundation

extension Data {
    
    mutating func wipe() {
        guard count > 0 else {
            return
        }
        let length = count
        withUnsafeMutableBytes { ptr in
            if let mutableRawPtr = ptr.baseAddress {
                memset_s(mutableRawPtr, length, 0, length)
            }
        }
    }
    static func random16BytesData() -> Data {
        let data = (0..<16).map({ _ in UInt8.random(in: 0...UInt8.max) })
        return Data(bytes: data, count: data.count)
    }
    
    static func random32BytesData() -> Data {
        let data = (0..<32).map({ _ in UInt8.random(in: 0...UInt8.max) })
        return Data(bytes: data, count: data.count)
    }
}
