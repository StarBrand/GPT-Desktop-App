//
//  LoginView.swift
//  GPT Chat Desktop
//
//  Created by Juan Saez Hidalgo on 15-02-23.
//

import SwiftUI
import os.log

struct LoginView: View {
    @Binding var logger     : Logger
    @Binding var isLoggedIn : Bool
    @Binding var userToken  : String
    @State private var saveToken     : Bool   = UserDefaults.standard.bool(forKey: "saveToken")
    @State private var onHold        : Bool   = false
    @State private var onError       : Bool   = false
    @State private var onErrorMsg    : String = ""
    private let TOKEN_PLACEHOLDER: String = "PERSONAL TOKEN"
    
    private func login() async -> Void {
        onError = false
        onHold = true
        do {
            let data: OpenAIModels = try await getModels(userToken: userToken, logger: logger)
            self.logger.notice("\(String(describing: data))")
        } catch let error as NSError {
            switch error.code {
            case 401:
                self.logger.critical("\(String(describing: error))")
                onErrorMsg = "Wrong authentication, change token provided"
            case NSURLErrorTimedOut:
                self.logger.critical("Timeout error")
                onErrorMsg = "Timeout. Retry?"
            case NSURLErrorNotConnectedToInternet:
                self.logger.critical("Not connected to internet")
                onErrorMsg = "Not connected to the internet, please, check your connection and then retry"
            default:
                self.logger.critical("\(String(describing: error))")
                self.logger.critical("\(error.code)")
                onErrorMsg = error.localizedDescription
            }
            onError = true
        }
        onHold = false
        if !onError {
            UserDefaults.standard.set(saveToken, forKey: "saveToken")
            if saveToken {
                UserDefaults.standard.set(userToken, forKey: "userToken")
            }
            self.logger.notice("Logged!")
            isLoggedIn = true
        }
    }
    
    var body: some View {
        VStack{
            Text("Insert your API key below")
            HStack{
                Text("If you does not have one, get it on")
                Link(destination: URL(string: "https://platform.openai.com/account/api-keys")!){
                    Text("the API key page")
                }
            }
            TextField(TOKEN_PLACEHOLDER, text: $userToken, onEditingChanged: {_ in
                self.onError = false
            })
                .disabled(self.onHold)
            if self.onError {
                Text(self.onErrorMsg)
                    .foregroundColor(.red)
                    .font(Font.footnote)
            }
            if self.onHold {
                Button(action: {
                    self.logger.trace("Bloked")
                }){
                    ProgressView()
                        .scaleEffect(0.5)
                }
                .buttonStyle(.borderedProminent)
                .tint(.gray)
            } else if self.onError {
                Button(action: {
                    Task {
                        
                    }
                }){
                    Image(systemName: "arrow.counterclockwise")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            } else {
                Button(action: {
                    Task {
                        self.logger.trace("Log in...")
                        let toTrace = saveToken ? "Saving token" : "Token enter without saving"
                        self.logger.trace("\(toTrace)")
                        await login()
                    }
                }){
                    Text("Enter")
                }
                .buttonStyle(.borderedProminent)
                .tint(.gray)
            }
            Toggle(isOn: $saveToken){
                Text("Save token")
            }
        }
        .onAppear {
            if self.saveToken {
                userToken = UserDefaults.standard.string(forKey: "userToken") ?? ""
            }
        }
    }
}

struct Previews_LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(
            logger: .constant(Logger()),
            isLoggedIn: .constant(false),
            userToken: .constant("")
        )
    }
}
