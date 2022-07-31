//
//  UIViewControllerExtensions.swift
//  SecureNotes
//
//

import UIKit

extension UIViewController {
    func showAlert(_ message: String,
                   title: String = "Secure Notes",
                   okTitle: String = "OK",
                   cancelTitle: String? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: okTitle, style: .default)
        alert.addAction(okAction)
        if let cancelTitle = cancelTitle {
            let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel)
            alert.addAction(cancelAction)
        }
        present(alert, animated: true, completion: nil)
    }
}
