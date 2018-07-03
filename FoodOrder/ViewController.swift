//
//  ViewController.swift
//  FoodOrder
//
//  Created by Irina Rozhnovskaya on 6/9/18.
//  Copyright © 2018 Irina Rozhnovskaya. All rights reserved.
//

import UIKit
import GoogleSignIn
import GoogleAPIClientForREST

class ViewController: UIViewController, GIDSignInDelegate, GIDSignInUIDelegate
{
    // If modifying these scopes, delete your previously saved credentials by
    // resetting the iOS simulator or uninstall the app.
    private let scopes = [kGTLRAuthScopeSheetsSpreadsheetsReadonly]
    
    private let spreadsheetId = "15biNTqtYhv57WmJFA6p2St3a3guPKhd9O4SlbsybWoU"
    
    private let service = GTLRSheetsService()
    
    let signInButton = GIDSignInButton()
    
    let outputTextView = UITextView()
    
    weak private var username: UITextField?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure Google Sign-in.
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().scopes = scopes
        GIDSignIn.sharedInstance().signInSilently()
        
        // Add the sign-in button.
        signInButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(signInButton)
        signInButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        signInButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        if (GIDSignIn.sharedInstance().hasAuthInKeychain())
        {
            signInButton.isHidden = true
        }
        
        // Add a UITextView to display output.
        view.addSubview(outputTextView);
        outputTextView.translatesAutoresizingMaskIntoConstraints = false
        let views = ["textView": outputTextView]
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[textView]-0-|", options: NSLayoutFormatOptions.init(rawValue: 0), metrics: nil, views: views))
        outputTextView.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor).isActive = true
        outputTextView.bottomAnchor.constraint(equalTo: self.bottomLayoutGuide.topAnchor).isActive = true
        outputTextView.isEditable = false
        outputTextView.contentInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        outputTextView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        outputTextView.isHidden = true
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!,
              withError error: Error!) {
        if let error = error
        {
            signInButton.isHidden = false
            showAlert(title: "Authentication Error", message: error.localizedDescription)
            self.service.authorizer = nil
        }
        else
        {
            signInButton.isHidden = true
            self.service.authorizer = user.authentication.fetcherAuthorizer()
            if UserManager.username != nil
            {
                self.outputTextView.isHidden = false
                fetchUserData()
            }
            else
            {
                askUserName()
            }
        }
    }
    
    func fetchUserData() {
        outputTextView.text = "Getting sheet data..."
        
        let day = getStringDescriptionOfToday()
        let range = "\(day)!A2:M"
        let query = GTLRSheetsQuery_SpreadsheetsValuesGet
            .query(withSpreadsheetId: spreadsheetId, range:range)
        service.executeQuery(query,
                             delegate: self,
                             didFinish: #selector(displayResult(ticket:finishedWithObject:error:))
        )
    }
    
    // Process the response and display output
    @objc func displayResult(ticket: GTLRServiceTicket, finishedWithObject result: GTLRSheets_ValueRange, error : NSError?)
    {
        if let error = error {
            showAlert(title: "Error", message: error.localizedDescription)
            return
        }
        
        // Get users and check if username is correct
        let rows = result.values!
        let allUsers = rows.compactMap { (row) -> String? in
            if let strings = row as? [String], let un = strings.first, un.count > 0
            {
                return un
            }
            return nil
        }
        
        guard let un = UserManager.username, let index = allUsers.index(of: un) else
        {
            let alert = UIAlertController(title: "Your name wasn't found", message: nil, preferredStyle: .alert)
            let okButton = UIAlertAction(title: "Try again", style: .default) { (action) in
                self.askUserName()
            }
            alert.addAction(okButton)
            present(alert, animated: true, completion: nil)
            return
        }
        
        guard var dishes = rows.first as? [String] else
        {
            showDataInconsistencyError()
            return
        }
        dishes.removeFirst()
        
        guard var userData = rows[index + 1] as? [String] else
        {
            showDataInconsistencyError()
            return
        }
        userData.removeFirst()
        
        var userMenu = NSMutableAttributedString()
        var boldFontAttributes = [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 15)]
        var regularFontAttributes = [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14)]
        for (index, choice) in userData.enumerated()
        {
            if choice.count > 0
            {
                let group = dishesGroup(index: index)
                let dish = dishes[index]
                userMenu.append(NSAttributedString(string: "\(group)\n", attributes: boldFontAttributes))
                userMenu.append(NSAttributedString(string: "\(dish)\n\n", attributes: regularFontAttributes))
            }
        }
        outputTextView.attributedText = userMenu
    }
    
    // Helper for showing an alert
    func showAlert(title : String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: UIAlertControllerStyle.alert
        )
        let ok = UIAlertAction(
            title: "OK",
            style: UIAlertActionStyle.default,
            handler: nil
        )
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
    
    func getStringDescriptionOfToday() -> String
    {
        let date = Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru")
        formatter.dateFormat = "EEEE"
        let dayInWeek = formatter.string(from: date)
        return dayInWeek.capitalized
    }
    
    func dishesGroup(index: Int) -> String
    {
        switch index {
        case let x where x <= 2:
            return "Салат"
            
        case let x where x <= 5:
            return "Суп"
            
        case let x where x <= 8:
            return "Основное блюдо"
            
        case let x where x <= 11:
            return "Гарнир"
            
        default:
           return "Незнакомое блюдо"
        }
    }
    
    func askUserName()
    {
        let alert = UIAlertController(title: "Enter your name", message: nil, preferredStyle: .alert)
        alert.addTextField { (textField) in
            self.username = textField
        }
        let okButton = UIAlertAction(title: "OK", style: .default) { (action) in
            if let textfield = self.username
            {
                if let un = textfield.text?.trimmingCharacters(in: CharacterSet.whitespaces), un.count > 0
                {
                    UserManager.username = un
                    self.outputTextView.isHidden = false
                    self.fetchUserData()
                }
                else
                {
                    self.askUserName()
                }
            }
        }
        alert.addAction(okButton)
        present(alert, animated: true, completion: nil)
    }
    
    func showDataInconsistencyError()
    {
        let alert = UIAlertController(title: "Internal app data inconsistency, please restart the app", message: nil, preferredStyle: .alert)
        present(alert, animated: true, completion: nil)
    }
}
