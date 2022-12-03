//  DetailViewController.swift
//  Challenge7 myNotes
//  Created by Ahmed Shaban on 01/09/2022.
/*
 CHALLENGE:
 1- Add a Done button as a navigation bar item that causes the app to re-lock immediately rather than waiting for the user to quit. This should only be shown when the app is unlocked. DONE
 
 2- Create a password system for your app so that the Touch ID/Face ID fallback is more useful. You'll need to use an alert controller with a text field like we did in project 5, and I suggest you save the password in the keychain! DONE
 
 3- Go back to project 10 (Names to Faces) and add biometric authentication so the user’s pictures are shown only when they have unlocked the app. You’ll need to give some thought to how you can hide the pictures – perhaps leave the array empty until they are authenticated?
 */

import LocalAuthentication
import UIKit

class ViewController: UIViewController {
    //MARK: Properties
    var note = Note(title: "", text: "")
    @IBOutlet var noteText: UITextView!
    
    //MARK: View Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        textAlwaysUp()
        noteText.text = note.text
        let notificationCenter = NotificationCenter.default
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Options",style: .plain, target: self, action: #selector(optionsView))
        notificationCenter.addObserver(self, selector: #selector(saveSecretMessage), name: UIApplication.willResignActiveNotification, object: nil) // to save the date when the users puts the app in the background or multitasking
        
        /*
         One caveat that you must be careful of: when we're told whether Touch ID/Face ID was successful or not, it might not be on the main thread. This means we need to use async() to make sure we execute any user interface code on the main thread.
         */

    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.saveNote()
    }
    
    //MARK: Operational Methods
    func saveNote() {
        note.text = self.noteText.text
    }
  
    @objc func saveSecretMessage() {
        guard noteText.isHidden == false else { return }
        KeychainWrapper.standard.set(noteText.text, forKey: "SecretNote")
        noteText.resignFirstResponder() // You should call this method when you want the user to stop editing a text field or text view.
        noteText.isHidden = true
    }
    func unlockSecretMessage() {
        noteText.isHidden = false
        if let text = KeychainWrapper.standard.string(forKey: "SecretNote") {
            noteText.text = text
        }
    }
        
    //MARK: Assistant Methods
    func textAlwaysUp() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        if notification.name == UIResponder.keyboardWillHideNotification {
            noteText.contentInset = .zero
        } else {
            noteText.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        }
        noteText.scrollIndicatorInsets = noteText.contentInset
        let selectedRange = noteText.selectedRange
        noteText.scrollRangeToVisible(selectedRange)
    }
    
    
    
    //MARK: Alert Action Methods
    @objc func optionsView() {
        let ac = UIAlertController(title: "Options", message: nil, preferredStyle: .actionSheet)
        let lockAction = UIAlertAction(title: "Lock", style: .default, handler: lockNote)
        let unlockAction = UIAlertAction(title: "Unlock", style: .default, handler: unlockNote)
        let shareAction = UIAlertAction(title: "Share", style: .default, handler: shareNote)
        if noteText.isHidden == false {ac.addAction(lockAction)}
        ac.addAction(unlockAction)
        ac.addAction(shareAction)
        present(ac, animated: true)
    }
    func lockNote(_ action: UIAlertAction) {
        saveNote()
        saveSecretMessage()
        noteText.isHidden = true
    }
    func unlockNote(_ action: UIAlertAction) {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Who are you?"
            //Face ID is handled slightly differently – open Info.plist, then add a new key called “Privacy - Face ID Usage Description”
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
                [weak self] success, authenticationError in
                
                DispatchQueue.main.async {
                    if success {
                        self?.unlockSecretMessage()
                    } else {
                        let ac = UIAlertController(title: "Authentication failed", message: "You could not be verified; please try again.", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        self?.present(ac, animated: true)
                    }
                }
            }
        } else {
            let ac = UIAlertController(title: "Biometry unavailable", message: "Your device is not configured for biometric authentication.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(ac, animated: true)
        }
    }
    func shareNote(_ action: UIAlertAction) {
        guard let text = self.noteText.text else {
            print("No text found")
            return
        }
        let vc = UIActivityViewController(activityItems: [text], applicationActivities: [])
        vc.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem // for iPad
        present(vc, animated: true)
    }



   
}
