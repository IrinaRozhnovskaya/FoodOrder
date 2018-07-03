//
//  AppDelegate.swift
//  FoodOrder
//
//  Created by Irina Rozhnovskaya on 6/9/18.
//  Copyright © 2018 Irina Rozhnovskaya. All rights reserved.
//

import UIKit
import GoogleSignIn

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Initialize Google sign-in.
        GIDSignIn.sharedInstance().clientID = "859029545104-31nu9v0f9o3je88jka426m2usjc69s79.apps.googleusercontent.com"
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        let sourceApplication = options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String
        let annotation = options[UIApplicationOpenURLOptionsKey.annotation]
        return GIDSignIn.sharedInstance().handle(url, sourceApplication: sourceApplication, annotation: annotation)
    }
}

