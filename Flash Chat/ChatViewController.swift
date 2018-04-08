//
//  ViewController.swift
//  Flash Chat
//
//  Created by Angela Yu on 29/08/2015.
//  Copyright (c) 2015 London App Brewery. All rights reserved.
//

import UIKit
import Firebase

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

    @IBOutlet var heightConstraint: NSLayoutConstraint!
    @IBOutlet var messageTextfield: UITextField!
    @IBOutlet var messageTableView: UITableView!
    
    var messages: [Message] = [Message]()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow , object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide , object: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("Loaded with user \(Auth.auth().currentUser!.email!)")
        
        messageTextfield.delegate = self

        messageTableView.delegate = self
        messageTableView.dataSource = self
        messageTableView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tableViewTapped)))
        messageTableView.register(UINib(nibName: "MessageCell", bundle: nil), forCellReuseIdentifier: "customMessageCell")
        configureTableView()
        listenForMessages()
    }
    

    ///////////////////////////////////////////
    
    //MARK: - TableView DataSource Methods

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customMessageCell", for: indexPath) as! CustomMessageCell
        let message = messages[indexPath.row]
        cell.messageBody.text = message.messageBody
        cell.senderUsername.text = message.sender
        cell.avatarImageView.image = UIImage(named: "egg")
        return cell
    }

    @objc func tableViewTapped() {
        messageTextfield.endEditing(true)
    }

    func configureTableView() {
        messageTableView.rowHeight = UITableViewAutomaticDimension
        messageTableView.estimatedRowHeight = 100
        messageTableView.separatorStyle = UITableViewCellSeparatorStyle.none
    }
    
    func scrollTableViewToBottom() {
        if (messages.count > 0) {
            messageTableView.scrollToRow(at: IndexPath(item:messages.count - 1, section: 0), at: .bottom, animated: true)
        }
    }

    ///////////////////////////////////////////
    
    //MARK:- Keyboard Notification handlers
    
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        
        let keyboardHeight: CGFloat
        if #available(iOS 11.0, *) {
            keyboardHeight = keyboardFrame.cgRectValue.height - self.view.safeAreaInsets.bottom
        } else {
            keyboardHeight = keyboardFrame.cgRectValue.height
        }
        
        updateTextFieldHeight(50 + keyboardHeight)
        scrollTableViewToBottom()
    }
    
    @objc func keyboardWillHide(_: NSNotification) {
        updateTextFieldHeight(50)
    }
    
    func updateTextFieldHeight(_ height: CGFloat) {
        heightConstraint.constant = height
        view.layoutIfNeeded()
        scrollTableViewToBottom()
    }

    ///////////////////////////////////////////
    //MARK: - Send & Recieve from Firebase
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendMessage()
        return true
    }

    func sendMessage() {
        if messageTextfield.text!.count > 0 {

            let messageDb = Database.database().reference().child("Messages")
            let message = [ "Sender": Auth.auth().currentUser?.email, "MessageBody": messageTextfield.text ]
            
            messageTextfield.text = ""
            messageTextfield.becomeFirstResponder()
            
            messageDb.childByAutoId().setValue(message) { (err, ref) in
                if err != nil {
                    self.showError(err!)
                } else {
                    print("Message saved!")
                }
            }
        }
    }

    func listenForMessages() {
        let messageDb = Database.database().reference().child("Messages")
        messageDb.observe(.childAdded) { (snapshot) in
            print(snapshot)
            self.messageReceived(snapshot.value as! Dictionary<String, String>)
        }
    }
    
    func messageReceived(_ messageDict: Dictionary<String, String>) {
        let text = messageDict["MessageBody"]!
        let sender = messageDict["Sender"]!
        print("Received message from \(sender): \(text)")
        let message = Message(from: sender, withMessage: text)
        messages.append(message)
        self.configureTableView()
        messageTableView.reloadData()
        scrollTableViewToBottom()
    }

    ///////////////////////////////
    // MARK: - logout handling
    
    @IBAction func logOutPressed(_ sender: AnyObject) {
        if signOut() {
            navigationController?.popViewController(animated: true)
        }
    }
    
    func signOut() -> Bool {
        do {
            try Auth.auth().signOut()
            return true
        } catch let err as NSError {
            showError(err)
        }
        return false
    }
    
    func showError(_ err: Error) {
        print(err)
        let alert = UIAlertController(title: "Error", message: err.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
