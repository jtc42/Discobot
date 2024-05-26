//
//  UserDefaults.swift
//  Discobot
//
//  Created by Joel Collins on 26/05/2024.
//

import Foundation

extension UserDefaults {
    func valueExists(forKey key: String) -> Bool {
        return object(forKey: key) != nil
    }
}
