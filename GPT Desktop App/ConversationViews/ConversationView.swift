//
//  Conversation.swift
//  GPT Desktop App
//
//  Created by Juan Saez Hidalgo on 17-02-23.
//

import SwiftUI
import os.log

let DELTA_TOKENS: Int = 5

private func getTokens(inputText: String) -> Int {
    return (inputText.components(separatedBy: [" ", "'"]).count * 4 / 3) + DELTA_TOKENS
}

struct ConversationView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var logger       : Logger
    @Binding var userToken    : String
    @Binding var conversation : Conversation?
    @Binding var onHold       : Bool
    @State private var currentConversation: [String] = []
    @State private var onError            : Bool     = false
    @State private var inputText          : String   = ""
    @State private var candidTokens       : Int      = 0
    @State private var totalTokens        : Int      = 0
    
    func getAnswer() async -> (String, Int, Int) {
        self.logger.trace("Using conversation \(self.currentConversation)")
        onError = false
        onHold = true
        var answer = ""
        var qTokens = 0
        var aTokens = 0
        do {
            let data: OpenAIResponse = try await getCompletions(
                userToken: userToken,
                text: self.currentConversation.joined(separator: "\n\n"),
                logger: self.logger,
                tokens: self.totalTokens + self.candidTokens
            )
            self.logger.notice("\(String(describing: data))")
            answer = data.choices[0].text.replacingOccurrences(of: "\n\n", with: "", options: .literal, range: nil)
            assert(
                data.usage.prompt_tokens + data.usage.completion_tokens == data.usage.total_tokens,
                "Wrong calculation of tokens: \(data.usage.prompt_tokens) + \(data.usage.completion_tokens) != \(data.usage.total_tokens)"
            )
            qTokens = data.usage.prompt_tokens - self.totalTokens
            aTokens = data.usage.completion_tokens
        } catch let error as NSError {
            switch error.code {
            case NSURLErrorTimedOut:
                self.logger.warning("Timeout error")
                answer = "Timeout. Retry?"
            case NSURLErrorNotConnectedToInternet:
                self.logger.warning("Not connected to internet")
                answer = "Not connected to the internet, please, check your connection and then retry"
            default:
                self.logger.warning("Other NSError: \(error.code)")
                answer = "\(error.localizedDescription), retry?"
            }
            onError = true
        } catch {
            self.logger.critical("Error on answer: \(error.localizedDescription)")
            fatalError(error.localizedDescription)
        }
        onHold = false
        return (answer, qTokens, aTokens)
    }
    
    func getDialog() -> [DialogText] {
        do {
            let fetchRequest: NSFetchRequest<DialogText> = NSFetchRequest(entityName: "DialogText")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
            fetchRequest.predicate = NSPredicate(format: "conversation == %@", self.conversation!)
            return try self.viewContext.fetch(fetchRequest)
        } catch {
            self.logger.warning("Error fetching dialog: \(error.localizedDescription)")
            return []
        }
    }
    
    private func getDialogColor(number: Int) -> Color {
        if self.onError && number == self.currentConversation.endIndex - 1 {
            return Color(red: 153/255, green: 0/255, blue: 0/255)
        }
        if number % 2 == 0 {
            return Color.black
        } else {
            return Color.gray
        }
    }
    
    var body: some View {
        GeometryReader { gr in
            VStack {
                ScrollViewReader{ value in
                    List{
                        ForEach(currentConversation.indices, id: \.self){ index in
                            ZStack(alignment: .topLeading) {
                                Rectangle()
                                    .fill(getDialogColor(number: index))
                                Text(currentConversation[index])
                                    .textSelection(.enabled)
                                    .padding()
                            }
                        }
                    }
                    .onChange(of: currentConversation.count) {
                        _ in
                        value.scrollTo(currentConversation.count - 1)
                    }
                    .frame(height: gr.size.height * 0.9)
                }
                HStack {
                    TextEditor(text: $inputText)
                        .lineLimit(1)
                    if self.onHold {
                        Button(action: {
                            self.logger.trace("Button Blocked")
                        }){
                            ProgressView()
                                .scaleEffect(0.5)
                        }
                    } else if self.onError {
                        Button(action: {
                            Task {
                                self.logger.notice("Retrying")
                                self.inputText = ""
                                let discarted: String? = self.currentConversation.popLast()
                                if discarted == nil {
                                    self.logger.warning("Nothing discarted")
                                } else {
                                    self.logger.trace("Dialog discarted: '\(discarted ?? "")'")
                                }
                                let (answer, qTokens, aTokens) = await getAnswer()
                                let endIndex = self.currentConversation.endIndex - 1;
                                if self.conversation != nil && !self.onError {
                                    self.logger.trace("Adding dialog after timeout on \(endIndex)")
                                    addDialogs(
                                        context: viewContext,
                                        question: self.currentConversation[endIndex],
                                        answer: answer,
                                        order: endIndex,
                                        questionTokens: qTokens,
                                        answerTokens: aTokens,
                                        conversation: conversation!
                                    )
                                    self.totalTokens += qTokens + aTokens
                                    self.logger.notice("Current tokens: \(self.totalTokens)")
                                } else {
                                    self.logger.warning("Current tokens: \(self.totalTokens)")
                                }
                                self.logger.trace("\(self.conversation)")
                                self.currentConversation.append(answer)
                                self.logger.trace("\(self.currentConversation)")
                            }
                        }){
                            Image(systemName: "arrow.counterclockwise")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .keyboardShortcut(KeyEquivalent.return, modifiers: .command)
                    } else {
                        Button(action: {
                            Task{
                                self.logger.trace("Text entered \(self.inputText)")
                                self.currentConversation.append(self.inputText)
                                self.candidTokens = getTokens(inputText: self.inputText)
                                self.inputText = ""
                                let (answer, qTokens, aTokens) = await getAnswer()
                                if conversation == nil {
                                    self.conversation = addNewConversation(context: viewContext)
                                }
                                let endIndex = self.currentConversation.endIndex - 1;
                                if self.conversation != nil && !self.onError{
                                    self.logger.trace("Adding dialog at first try on \(endIndex)")
                                    addDialogs(
                                        context: viewContext,
                                        question: self.currentConversation[endIndex],
                                        answer: answer,
                                        order: endIndex,
                                        questionTokens: qTokens,
                                        answerTokens: aTokens,
                                        conversation: conversation!
                                    )
                                    self.totalTokens += qTokens + aTokens
                                    self.logger.notice("Current tokens: \(self.totalTokens)")
                                } else {
                                    self.logger.warning("Current tokens: \(self.totalTokens)")
                                }
                                self.logger.trace("\(self.conversation)")
                                self.currentConversation.append(answer)
                                self.logger.trace("\(self.currentConversation)")
                            }
                        }){
                            Image(systemName: "paperplane")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .keyboardShortcut(KeyEquivalent.return, modifiers: .command)
                    }
                }
                .frame(height: gr.size.height * 0.07)
                .onChange(of: conversation) { newConversation in
                    self.onError = false
                    if newConversation == nil {
                        self.currentConversation = []
                    } else {
                        let dialog = getDialog()
                        self.logger.trace("\(dialog.map { ($0.text ?? "", "tokens: \($0.tokens)") } )")
                        self.currentConversation = dialog.map { $0.text ?? "" }
                    }
                }
            }
        }
    }
}
