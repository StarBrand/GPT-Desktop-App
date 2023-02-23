//
//  MainContentView.swift
//  GPT Chat Desktop
//
//  Created by Juan Saez Hidalgo on 15-02-23.
//

import SwiftUI
import os.log

struct MainContentView: View {
    @Binding var logger: Logger
    @Binding var userToken: String
    @State var conversation: Conversation? = nil
    @State var onHold: Bool = false
    
    var body: some View {
        GeometryReader { gr in
            HStack{
                ConversationsManager(
                    logger: $logger,
                    conversation: $conversation,
                    onHold: $onHold
                )
                    .frame(width: gr.size.width * 0.3)
                    .padding(5)
                ConversationView(
                    logger: $logger,
                    userToken: $userToken,
                    conversation: $conversation,
                    onHold: $onHold
                )
                    .frame(width: gr.size.width * 0.65)
                    .padding(10)
            }
        }
    }
}
