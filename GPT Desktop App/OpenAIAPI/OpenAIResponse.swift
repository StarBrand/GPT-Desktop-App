//
//  OpenAIResponse.swift
//  GPT Desktop App
//
//  Created by Juan Saez Hidalgo on 19-02-23.
//

import Foundation

struct OpenAIResponse: Decodable {
    let choices: Array<OpenAIChoices>
    let model: String
    let object: String
    let usage: OpenAITokenUsage
}

struct OpenAIChoices: Decodable {
    let text: String
    let finish_reason: String
}

struct OpenAITokenUsage: Decodable {
    let completion_tokens: Int
    let prompt_tokens: Int
    let total_tokens: Int
}

struct OpenAIModels: Decodable {
    let data: Array<OpenAIModel>
}

struct OpenAIModel: Decodable {
    let id: String
    let owned_by: String
}
