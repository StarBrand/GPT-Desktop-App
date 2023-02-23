//
//  ContentView.swift
//  GPT Chat Desktop
//
//  Created by Juan Saez Hidalgo on 20-01-23.
//

import SwiftUI
import os.log

struct ContentView: View {
    @State private var logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: ContentView.self)
    )
    @State private var isLoggedIn = false
    @State private var userToken = ""
    
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        if !isLoggedIn {
            LoginView(logger: $logger, isLoggedIn: $isLoggedIn, userToken: $userToken)
        } else {
            MainContentView(logger: $logger, userToken: $userToken)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
