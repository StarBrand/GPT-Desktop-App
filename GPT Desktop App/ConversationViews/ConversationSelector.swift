//
//  ConversationSelector.swift
//  GPT Desktop App
//
//  Created by Juan Saez Hidalgo on 17-02-23.
//

import SwiftUI
import os.log

struct ConversationSelector: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var logger: Logger
    @State var conversation: Conversation?
    @State private var isHover   : Bool = false
    @State private var toDelete  : Bool = false
    
    private func getFirstDialog() -> String {
        var dialogs: [DialogText] = []
        if self.conversation == nil {
            return "0000 [Error retrieving text]"
        }
        do {
            let fetchRequest: NSFetchRequest<DialogText> = NSFetchRequest(entityName: "DialogText")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
            fetchRequest.predicate = NSPredicate(format: "conversation == %@", self.conversation!)
            dialogs = try self.viewContext.fetch(fetchRequest)
        } catch {
            self.logger.warning("Error on retrieving dialog: \(error.localizedDescription)")
        }
        let errorLog: String = "\(self.conversation?.identifier?.uuidString ?? "0000") [Error retrieving text]"
        if dialogs.isEmpty {
            return errorLog
        } else {
            return dialogs[0].text ?? errorLog
        }
    }
    
    var body: some View {
        HStack{
            Text(getFirstDialog())
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(2.5)
            if self.isHover {
                if self.toDelete {
                    Image(systemName: "checkmark")
                        .onTapGesture {
                            self.logger.notice("Delete confirmed")
                            deleteConversation(context: viewContext, conversation: conversation!)
                        }
                    Image(systemName: "xmark")
                        .onTapGesture {
                            self.logger.notice("Cancel delete")
                            self.toDelete = false
                        }
                } else {
                    Image(systemName: "trash")
                        .onTapGesture {
                            let uuid = conversation!.identifier?.uuidString ?? ""
                            self.logger.notice("Delete conversation: \(uuid)")
                            self.toDelete = true
                        }
                }
            }
        }
        .onHover { hovering in
            self.isHover = hovering
            if !hovering {
                self.toDelete = false
            }
        }
    }
}

struct Previews_ConversationSelector_Previews: PreviewProvider {
    static var previews: some View {
        ConversationSelector(
            logger: .constant(Logger())
        )
    }
}
