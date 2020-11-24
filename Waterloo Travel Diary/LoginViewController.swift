//
//  LoginViewController.swift
//  Waterloo Travel Diary
//
//  Created by Eddy on 2020-11-23.
//  Copyright © 2020 Eddy. All rights reserved.
//
import UIKit
import Foundation

class LoginViewController: UIViewController, UITextFieldDelegate {

    override func viewDidLoad() {
        textfield.delegate = self
    }
    //MARK: Actions

    //MARK: Properties
    @IBOutlet weak var textfield: UITextField!
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        // User tapped outside the keyboard or was directed here by tapping on done.
        let email = textField.text
        return email != nil && email!.contains("@")
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        // Autocompleted emails have a space after them.
        let email = textField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let userDefaults = UserDefaults.standard
        userDefaults.set(email, forKey: "email")
        print(email)
        // Dismiss modal.
        self.dismiss(animated: true, completion: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // User pressed done button.
        if (self.textFieldShouldEndEditing(textfield)) {
            // Ends editing of the textfield. Normally done right after
            // textFieldShouldEndEditing returns true when the user taps somewhere else.
            textfield.resignFirstResponder()
        }
        return true
    }
}
