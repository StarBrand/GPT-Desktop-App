//
//  Persistence.swift
//  GPT Desktop App
//
//  Created by Juan Saez Hidalgo on 15-02-23.
//

import CoreData

struct PersitentUserData {
    static let shared = PersitentUserData()
    let container: NSPersistentContainer
    
    init(){
        container = NSPersistentContainer(name: "UserData")
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Container load failed: \(error)")
            }
        }
    }
}
