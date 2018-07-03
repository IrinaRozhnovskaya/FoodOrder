//
//  UserManager.swift
//  FoodOrder
//
//  Created by Irina Rozhnovskaya on 6/9/18.
//  Copyright © 2018 Irina Rozhnovskaya. All rights reserved.
//

import Foundation

class UserManager: NSObject
{
    static private let usernameDefaultsKey = "usernameDefaultsKey"
    
    static var username: String?
    {
        get
        {
            return UserDefaults.standard.value(forKey: usernameDefaultsKey) as? String
        }
        set
        {
            if let name = newValue
            {
                UserDefaults.standard.setValue(name, forKey: usernameDefaultsKey)
            }
            else
            {
                UserDefaults.standard.removeObject(forKey: usernameDefaultsKey)
            }
            
        }
    }
}
