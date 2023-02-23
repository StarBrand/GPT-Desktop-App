//
//  ConversationsManager.swift
//  GPT Desktop App
//
//  Created by Juan Saez Hidalgo on 17-02-23.
//

import SwiftUI
import os.log

struct ConversationsManager: View {
    @Binding var logger: Logger
    @Binding var conversation: Conversation?
    @Binding var onHold: Bool
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: Conversation.entity(), sortDescriptors: [NSSortDescriptor(key: "modified", ascending: false)]) private var conversations: FetchedResults<Conversation>
    
    var body: some View {
        GeometryReader { gr in
            VStack(alignment: .center) {
                List {
                    ForEach(conversations) { conversation in
                        ConversationSelector(logger: $logger, conversation: conversation)
                            .onTapGesture {
                                if !self.onHold {
                                    let uuid = self.conversation?.identifier?.uuidString ?? "0000"
                                    self.conversation = conversation
                                    self.logger.notice("Changing to conversation \(uuid)")
                                } else {
                                    self.logger.trace("Blocked")
                                }
                            }
                            .background(self.conversation == conversation ? .gray : .clear)
                    }
                }
                NewConversation(logger: $logger, conversation: $conversation, onHold: $onHold)
            }
        }
    }
}
