//
//  Database.swift
//  SecureNotes
//
//
import SQLite

final class Database {
    static let shared = Database()
    
    private let global = Table("Global")
    private let kEncryptedHash = Expression<Data>("encryptedHash")
    private let kEncryptedSalt = Expression<Data>("encryptedSalt")
    private let kEncryptedIV = Expression<Data>("encryptedIV")
    private let kEncryptedBiometrics = Expression<Data?>("encryptedBiometrics")
    private let kEncryptedBioIV = Expression<Data?>("encryptedBioIV")
    private let kEncryptedBioServiceId = Expression<Data?>("encryptedBioServiceId")
    
    private let notes = Table("Notes")
    private let kNoteId = Expression<Int64>("noteId")
    private let kEncryptedTitle = Expression<Data>("encryptedTitle")
    private let kEncryptedContent = Expression<Data>("encryptedContent")
    private let kCreatedDate = Expression<Date>("createdDate")
    private let kModifiedDate = Expression<Date>("modifiedDate")
    
    let path: String = {
        var path: String = ""
        path = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true
        ).first!
        return "\(path)/db.sqlite3"
    }()
    
    private init() {
    }
    
    func setupDatabase() throws {
        do {
            // create parent directory if it doesn’t exist
            let db = try Connection(path)
            try db.run(global.create(ifNotExists: true) { table in
                table.column(kEncryptedHash, unique: true)
                table.column(kEncryptedSalt)
                table.column(kEncryptedIV)
                table.column(kEncryptedBiometrics)
                table.column(kEncryptedBioIV)
                table.column(kEncryptedBioServiceId)
            })

            try db.run(notes.create(ifNotExists: true) { table in
                table.column(kNoteId, primaryKey: .autoincrement)
                table.column(kEncryptedTitle)
                table.column(kEncryptedContent)
                table.column(kCreatedDate)
                table.column(kModifiedDate)
            })

        } catch {
            throw DatabaseError.dbError(error.localizedDescription)
        }
    }
    
    // MARK: NOTES QUERY, INSERT, UPDATE, DELETE
    func getAllEncryptedNotes() throws -> [Note] {
        var encryptedNotes = [Note]()
        do {
            let db = try Connection(path)
            for note in try db.prepare(notes) {
                let aNote = Note.init(noteId: note[kNoteId],
                                      encryptedTitle: note[kEncryptedTitle],
                                      encryptedContent: note[kEncryptedContent],
                                      createdDate: note[kCreatedDate],
                                      modifiedDate: note[kModifiedDate])
                encryptedNotes.append(aNote)
            }
        } catch {
            throw DatabaseError.dbError(error.localizedDescription)
        }
        return encryptedNotes
    }
    
    func insertNote(encryptedTitle: Data, encryptedContent: Data,
                    createdDate: Date, modifiedDate: Date) throws -> Int64 {
        do {
            let db = try Connection(path)
            let insert = notes.insert(kEncryptedTitle <- encryptedTitle,
                                      kEncryptedContent <- encryptedContent,
                                      kCreatedDate <- createdDate,
                                      kModifiedDate <- modifiedDate)
            let rowId = try db.run(insert)
            return rowId
        } catch {
            throw DatabaseError.dbError(error.localizedDescription)
        }
    }
    
    func updateNote(noteId: Int64, encryptedTitle: Data, encryptedContent: Data, modifiedDate: Date) throws {
        do {
            let db = try Connection(path)
            let updateNote = notes.filter(kNoteId == noteId)
            let updateDB = updateNote.update(kEncryptedTitle <- encryptedTitle,
                                             kEncryptedContent <- encryptedContent,
                                             kModifiedDate <- modifiedDate)
            _ = try db.run(updateDB)
        } catch {
            throw DatabaseError.dbError(error.localizedDescription)
        }
    }
    
    func deleteNote(noteId: Int64) throws {
        do {
            let db = try Connection(path)
            let deleteNote = notes.filter(kNoteId == noteId)
            _ = try db.run(deleteNote.delete())
        } catch {
            throw DatabaseError.dbError(error.localizedDescription)
        }
    }
    
    // MARK: STORE SENSITIVE DATA
    func createGlobalData(encryptedHash: Data, encryptedSalt: Data, encryptedIV: Data) throws {
        do {
            let db = try Connection(path)
            let insert = global.insert(kEncryptedHash <- encryptedHash,
                                       kEncryptedSalt <- encryptedSalt,
                                       kEncryptedIV <- encryptedIV)
            _ = try db.run(insert)
        } catch {
            throw DatabaseError.dbError(error.localizedDescription)
        }
    }
    
    func queryGlobalData() throws -> Global? {
        // We can pluck the first row by passing a query to the pluck function on a database connection.
        do {
            let db = try Connection(path)
            if let data = try db.pluck(global) {
                return Global(encryptedHash: data[kEncryptedHash],
                              encryptedSalt: data[kEncryptedSalt],
                              encryptedIV: data[kEncryptedIV],
                              encryptedBiometrics: data[kEncryptedBiometrics],
                              encryptedBioIV: data[kEncryptedBioIV],
                              encryptedBioServiceId: data[kEncryptedBioServiceId])
            }
        } catch {
            throw DatabaseError.dbError(error.localizedDescription)
        }
        return nil
    }
    
    func hasGlobalData() throws -> Bool {
        do {
            let db = try Connection(path)
            if try db.pluck(global) != nil {
                return true
            }
        } catch {
            throw DatabaseError.dbError(error.localizedDescription)
        }
        return false
    }
    
    func storeBiometricData(encryptedBiometrics: Data, encryptedBioIV: Data, encryptedBioServiceId: Data) throws {
        do {
            let db = try Connection(path)
            if try db.pluck(global) != nil {
                try db.run(global.update(kEncryptedBiometrics <- encryptedBiometrics,
                                         kEncryptedBioIV <- encryptedBioIV,
                                         kEncryptedBioServiceId <- encryptedBioServiceId))
            }
        } catch {
            throw DatabaseError.dbError(error.localizedDescription)
        }
    }
    
    func hasBiometricData() throws -> Bool {
        do {
            let db = try Connection(path)
            if let data = try db.pluck(global) {
                return data[kEncryptedBiometrics] != nil
            }
        } catch {
            throw DatabaseError.dbError(error.localizedDescription)
        }
        return false
    }
}
