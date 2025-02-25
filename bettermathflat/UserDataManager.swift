//
//  UserDataManager.swift
//  bettermathflat
//
//  Created by youngzheimer on 2/24/25.
//

import Foundation

func getUserData() -> UserData? {
    if let savedUser = UserDefaults.standard.data(forKey: "userData") {
        let decoder = JSONDecoder()
        if let loadedUser = try? decoder.decode(UserData.self, from: savedUser) {
            return loadedUser
        }
    }
    return nil
}

func saveUserData(data: UserData) {
    let encoder = JSONEncoder()
    if let encoded = try? encoder.encode(data) {
        UserDefaults.standard.set(encoded, forKey: "userData")
    }
}
