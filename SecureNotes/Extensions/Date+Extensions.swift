//
//  DateExtensions.swift
//  SecureNotes
//
//

import Foundation

extension Date {
    func toString(withFormat: String) -> String {
        let dateformat = DateFormatter()
        dateformat.dateFormat = withFormat
        return dateformat.string(from: self)
    }

    func timeString() -> String {
        return self.toString(withFormat: "yyyy-MM-dd h:mm a")
    }
}
