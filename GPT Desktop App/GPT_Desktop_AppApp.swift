//
//  GPT_Desktop_AppApp.swift
//  GPT Desktop App
//
//  Created by Juan Saez Hidalgo on 15-02-23.
//

import SwiftUI

@main
struct GPT_Desktop_AppApp: App {
    
    let persistenceController = PersitentUserData.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
