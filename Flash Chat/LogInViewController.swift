//
//  LogInViewController.swift
//  Flash Chat
//
//  This is the view controller where users login


import UIKit
import Firebase
import SVProgressHUD

class LogInViewController: UIViewController {

    @IBOutlet var emailTextfield: UITextField!
    @IBOutlet var passwordTextfield: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let currentUser = Auth.auth().currentUser {
            // if there is already a current user, sign them out, fill in the email field and set focus to the password field
            signOut()
            emailTextfield.text = currentUser.email!
            passwordTextfield.becomeFirstResponder()
        } else {
            // no current user, so focus on email
            emailTextfield.becomeFirstResponder()
        }
        // ensure the password field is clear
        passwordTextfield.text = ""
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func logInPressed(_ sender: AnyObject) {
        
        SVProgressHUD.show(withStatus: "Logging in")
        
        // attempt to sign in with provided email and password
        Auth.auth().signIn(withEmail: emailTextfield.text!, password: passwordTextfield.text!) { (user, err) in
            
            if err != nil {
                SVProgressHUD.dismiss()
                self.showError(err!)
            } else if !user!.isEmailVerified {
                SVProgressHUD.dismiss()
                
                // alert user that their email has not yet been verified - login cannot proceed
                let alert = UIAlertController(title: "Email Address Not Verified",
                                              message: "Please check your email and follow the instructions to verify your email address before logging in.",
                                              preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                
                // allow the user to resend email verification
                alert.addAction(UIAlertAction(title: "Resend", style: UIAlertActionStyle.default) { _ in
                    SVProgressHUD.show()
                    user!.sendEmailVerification() { err in
                        if err != nil {
                            SVProgressHUD.dismiss()
                            self.showError(err!)
                        } else {
                            SVProgressHUD.showSuccess(withStatus: "Email Sent!")
                            SVProgressHUD.dismiss(withDelay: 2)
                        }
                    }
                })
                self.present(alert, animated: true, completion: nil)
            } else {
                // successful login and email has been verified - send user to the chat screen
                SVProgressHUD.showSuccess(withStatus: "Success!")
                SVProgressHUD.dismiss(withDelay: 0.5)
                self.performSegue(withIdentifier: "goToChat", sender: self)
            }
            // reset password field and focus
            self.passwordTextfield.text = ""
            self.passwordTextfield.becomeFirstResponder()
        }
    }
    
    func showError(_ err: Error) {
        print(err)
        let alert = UIAlertController(title: "Error", message: err.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    func signOut() {
        // sign out of Firebase
        do {
            try Auth.auth().signOut()
        } catch let err as NSError {
            print("Error signing out: \(err)")
        }
    }
}
