//
//  FontExtensions.swift
//  SecureNotes
//
//

import Foundation
import UIKit

extension UIFont {
    static func defaultTitleFont() -> UIFont {
        return UIFont.systemFont(ofSize: 22)
    }

    static func defaultSubTitleFont() -> UIFont {
        return UIFont.systemFont(ofSize: 12)
    }

    static func defaultBodyFont() -> UIFont {
        return UIFont.systemFont(ofSize: 16)
    }
}
