//
//  EnableBiometricViewController.swift
//  SecureNotes
//
//

import UIKit
import ProgressHUD

class EnableBiometricViewController: UIViewController {

    @IBOutlet weak var enableBiometricButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        #if targetEnvironment(simulator)
        enableBiometricButton.isHidden = true
        #endif
    }
    
    @IBAction func enableBiometricLogin(_ sender: Any) {
        ProgressHUD.load()
        do {
            try NoteService.shared.enableLoginWithBiometrics()
            let listNoteVC = UINavigationController.init(rootViewController: ListNoteViewController())
            UIApplication.shared.windows.first?.rootViewController = listNoteVC
            UIApplication.shared.windows.first?.makeKeyAndVisible()
            ProgressHUD.dismiss()
        } catch {
            ProgressHUD.dismiss()
            showAlert(error.localizedDescription)
        }
    }
    
    @IBAction func skipBiometricLogin(_ sender: Any) {
        let listNoteVC = UINavigationController.init(rootViewController: ListNoteViewController())
        UIApplication.shared.windows.first?.rootViewController = listNoteVC
        UIApplication.shared.windows.first?.makeKeyAndVisible()
    }
}
