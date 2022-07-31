//
//  Note.swift
//  SecureNotes
//
//

import UIKit

struct Note {
    var id: Int64?
    var title: String
    var content: String
    var encryptedTitle: Data
    var encryptedContent: Data
    let created: Date
    var lastModified: Date

    var hasBeenModified: Bool = false

    init(noteId: Int64, encryptedTitle: Data, encryptedContent: Data, createdDate: Date, modifiedDate: Date) {
        self.id = noteId
        self.encryptedTitle = encryptedTitle
        self.encryptedContent = encryptedContent
        self.created = createdDate
        self.lastModified = modifiedDate
        
        self.title = ""
        self.content = ""
    }

    init() {
        self.title = "New Title"
        self.content = ""
        
        self.id = nil
        self.encryptedTitle = Data()
        self.encryptedContent = Data()
        self.created = Date()
        self.lastModified = Date()
    }
}

@propertyWrapper struct NewestFirst {
    var wrappedValue: [Note] {
        didSet {
            wrappedValue = wrappedValue.sorted(by: { (n0, n1) -> Bool in
                return n0.lastModified > n1.lastModified
            })
        }
    }
}
