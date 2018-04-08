//
//  Message.swift
//  Flash Chat
//
//  This is the model class that represents the blueprint for a message

class Message {
    
    var messageBody: String = ""
    var sender: String = ""
    
    init(from sender: String, withMessage message: String) {
        self.sender = sender
        self.messageBody = message
    }

}
