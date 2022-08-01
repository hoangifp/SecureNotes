//
//  LoginViewController.swift
//  SecureNotes
//
//

import UIKit
import ProgressHUD
import IOSSecuritySuite

class LoginViewController: UIViewController {
    let minimumPinLength = 6
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var numericPinTextField: UITextField!
    @IBOutlet weak var biometricLoginButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        biometricLoginButton.isHidden = !NoteService.shared.isBiometricEnabled()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if IOSSecuritySuite.amIJailbroken() {
            showAlert("This device appears to be jailbroken. Please keep in mind that jailbreaking weakens the security of the application.")
        }
    }
    
    @IBAction func loginButtonTapped(_ sender: Any) {
        if validateTextFields() {
            errorLabel.isHidden = true
            login()
        }
        view.endEditing(true)
    }
    
    func validateTextFields() -> Bool {
        if (usernameTextField.text?.isEmpty)! {
            showErrorMessage("The username can't be empty")
            return false
        } else if (numericPinTextField.text?.isEmpty)! || numericPinTextField.text!.count < minimumPinLength {
            showErrorMessage("The pin length can not be less than \(minimumPinLength)")
            return false
        }
        return true
    }
    
    @objc func login() {
        do {
#if !DEBUG
            IOSSecuritySuite.denyDebugger()
            let amIRuntimeHooked = IOSSecuritySuite.amIRuntimeHooked(dyldWhiteList: [],
                                                                     detectionClass: LoginViewController.self,
                                                                     selector: #selector(LoginViewController.login),
                                                                     isClassMethod: false)
            if amIRuntimeHooked {
                abort()
            }
#endif
            guard var userNameData = usernameTextField.text?.data(using: .utf8),
                  var numericPin = numericPinTextField.text?.data(using: .utf8) else {
                showErrorMessage("Invalid input fields")
                return
            }
            ProgressHUD.show()
            try NoteService.shared.login(with: &userNameData, numericPin: &numericPin)
            
            let listNoteVC = ListNoteViewController()
            listNoteVC.notes = try NoteService.shared.getNotes()
            
            UIApplication.shared.windows.first?.rootViewController =  UINavigationController.init(rootViewController:
                                                                                                    listNoteVC)
            UIApplication.shared.windows.first?.makeKeyAndVisible()
            ProgressHUD.dismiss()

            usernameTextField.text = ""
            numericPinTextField.text = ""

        } catch let error {
            ProgressHUD.dismiss()
            showAlert(error.localizedDescription)
        }
    }
    
    func showErrorMessage(_ message: String) {
        errorLabel.isHidden = false
        errorLabel.text = message
    }
    
    @IBAction func biometricButtonTapped(_ sender: Any) {
        do {
#if !DEBUG
            IOSSecuritySuite.denyDebugger()
            let amIRuntimeHooked = IOSSecuritySuite.amIRuntimeHooked(dyldWhiteList: [],
                                                                     detectionClass: LoginViewController.self,
                                                                     selector: #selector(LoginViewController.biometricButtonTapped(_:)),
                                                                     isClassMethod: false)
            if amIRuntimeHooked {
                abort()
            }
#endif
            ProgressHUD.show()
            try NoteService.shared.authenticateWithBiometric()
            let listNoteVC = ListNoteViewController()
            listNoteVC.notes = try NoteService.shared.getNotes()
            
            UIApplication.shared.windows.first?.rootViewController =  UINavigationController.init(rootViewController:
                                                                                                    listNoteVC)
            UIApplication.shared.windows.first?.makeKeyAndVisible()
            ProgressHUD.dismiss()
        } catch {
            ProgressHUD.dismiss()
            showAlert(error.localizedDescription)
        }
    }
}
