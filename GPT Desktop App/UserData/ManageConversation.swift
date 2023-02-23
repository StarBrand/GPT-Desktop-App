//
//  ManageConversation.swift
//  GPT Desktop App
//
//  Created by Juan Saez Hidalgo on 17-02-23.
//

import SwiftUI
import CoreData

func addNewConversation(context: NSManagedObjectContext) -> Conversation {
    withAnimation{
        let conversation = Conversation(context: context)
        conversation.identifier = UUID()
        conversation.created = Date()
        conversation.modified = Date()
        
        saveContext(context: context)
        
        return conversation
    }
}

func addDialogs(context: NSManagedObjectContext, question: String, answer: String, order: Int, questionTokens: Int, answerTokens: Int, conversation: Conversation) -> Void {
    withAnimation{
        let questionDialog = DialogText(context: context)
        questionDialog.conversation = conversation
        questionDialog.text = question
        questionDialog.order = Int64(order)
        questionDialog.tokens = Int16(questionTokens)
        
        let answerDialog = DialogText(context: context)
        answerDialog.conversation = conversation
        answerDialog.text = answer
        answerDialog.order = Int64(order + 1)
        answerDialog.tokens = Int16(answerTokens)
        
        conversation.modified = Date()
        saveContext(context: context)
    }
}

func deleteConversation(context: NSManagedObjectContext, conversation: Conversation){
    withAnimation{
        context.delete(conversation)
        saveContext(context: context)
    }
}

private func saveContext(context: NSManagedObjectContext) -> Void {
    do {
        try context.save()
    } catch let error as NSError {
        fatalError("Error on saving context \(error)")
    }
}
