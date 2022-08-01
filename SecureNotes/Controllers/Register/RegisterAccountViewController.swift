//
//  CreateAccountViewController.swift
//  SecureNotes
//
//

import Foundation
import UIKit
import ProgressHUD
import IOSSecuritySuite

class RegisterAccountViewController: UIViewController {
    let minimumPinLength = 6
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var pinTextField: UITextField!
    @IBOutlet weak var confirmPinTextField: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        usernameTextField.text = ""
        pinTextField.text = ""
        confirmPinTextField.text = ""
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if IOSSecuritySuite.amIJailbroken() {
            showAlert("This device appears to be jailbroken. Please keep in mind that jailbreaking weakens the security of the application.")
        }
    }

    @IBAction func registerButtonTapped(_ sender: Any) {
        if validateTextFields() {
            errorLabel.isHidden = true
            registerAccountWithCryptoService()
        }
        view.endEditing(true)
    }

    func validateTextFields() -> Bool {
        if (usernameTextField.text?.isEmpty)! {
            showErrorMessage("The username can't be empty")
            return false
        } else if (pinTextField.text?.isEmpty)! || pinTextField.text!.count < minimumPinLength {
            showErrorMessage("The pin length can not be less than \(minimumPinLength)")
            return false
        } else if pinTextField.text != confirmPinTextField.text {
            showErrorMessage("The numeric pin are mismatch")
            return false
        }
        return true
    }

    @objc func registerAccountWithCryptoService() {
        do {
#if !DEBUG
            IOSSecuritySuite.denyDebugger()
            let amIRuntimeHooked = IOSSecuritySuite.amIRuntimeHooked(dyldWhiteList: [],
                                                                     detectionClass: RegisterAccountViewController.self,
                                                                     selector: #selector(RegisterAccountViewController.registerAccountWithCryptoService),
                                                                     isClassMethod: false)
            if amIRuntimeHooked {
                abort()
            }
#endif
            guard var userNameData = usernameTextField.text?.data(using: .utf8),
                    var numericPin = pinTextField.text?.data(using: .utf8) else {
                showErrorMessage("Invalid input fields")
                return
            }
            ProgressHUD.show("Registering new account")
            try NoteService.shared.registerUserAccount(with: &userNameData, numericPin: &numericPin)
            ProgressHUD.dismiss()

            let storyBoard = UIStoryboard(name: "main", bundle: nil)
            let enableBiometricVC = storyBoard.instantiateViewController(
                withIdentifier: "EnableBiometricViewController")
            enableBiometricVC.modalPresentationStyle = .fullScreen
            present(enableBiometricVC, animated: true) {
                self.usernameTextField.text = ""
                self.pinTextField.text = ""
                self.confirmPinTextField.text = ""
            }
        } catch let error {
            showAlert("\(error.localizedDescription)")
        }
    }

    func showErrorMessage(_ message: String) {
        errorLabel.isHidden = false
        errorLabel.text = message
    }
}
