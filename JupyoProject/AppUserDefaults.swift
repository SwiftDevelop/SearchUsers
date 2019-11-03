//
//  UserDefaults.swift
//  JupyoProject
//
//  Created by INNOTIVE Inc. on 2019/10/31.
//  Copyright © 2019 JangJupyo. All rights reserved.
//

import UIKit

enum KeyName: String {
    case likeUser
}

class AppUserDefaults: NSObject {
    
    func set(_ value: Any, key: KeyName) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }
    
    func get(_ key: KeyName) -> Any? {
        guard let value = UserDefaults.standard.object(forKey: key.rawValue) else { return nil }
        return value
    }
    
    func delete(_ key: KeyName) {
        UserDefaults.standard.removeObject(forKey: key.rawValue)
    }
    
}
