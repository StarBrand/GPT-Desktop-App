//
//  NewConversation.swift
//  GPT Desktop App
//
//  Created by Juan Saez Hidalgo on 17-02-23.
//

import SwiftUI
import os.log

struct NewConversation: View {
    @Binding var logger: Logger
    @Binding var conversation: Conversation?
    @Binding var onHold: Bool
    
    var body: some View {
        Button(action: {
            if !self.onHold {
                self.logger.notice("New Conversation")
                conversation = nil
            } else {
                self.logger.trace("Blocked")
            }
        }){
            Text("Create New Conversation")
        }
    }
}
