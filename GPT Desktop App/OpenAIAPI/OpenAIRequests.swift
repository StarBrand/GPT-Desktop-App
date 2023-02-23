//
//  PostOpenAI.swift
//  GPT Desktop App
//
//  Created by Juan Saez Hidalgo on 15-02-23.
//

import Foundation
import os.log

let API_URL = "https://api.openai.com/v1/"
let MAX_TOKENS = 4097

func getCompletions<T: Decodable>(userToken: String, text: String, logger: Logger, tokens: Int = 1000) async throws -> T {
    var request = URLRequest(url: URL(string: "\(API_URL)completions")!)
    let sendData = [
        "model": "text-davinci-003",
        "prompt": text,
        "max_tokens": MAX_TOKENS - tokens,
        "temperature": 0
    ] as [String : Any]
    logger.notice("Max number of tokens for response \(MAX_TOKENS - tokens), with \(tokens) tokens sent")
    
    request.httpMethod = "POST"
    request.timeoutInterval = 10
    
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: sendData, options: .prettyPrinted)
    } catch let error {
        logger.critical("\(error.localizedDescription)")
    }
    
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("Bearer \(userToken)", forHTTPHeaderField: "Authorization")

    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
        throw NSError(domain: "HTTPError", code: (response as? HTTPURLResponse)?.statusCode ?? -1, userInfo: nil)
    }
    
    do {
        let jsonReceived: NSDictionary = try JSONSerialization.jsonObject(with: data) as! NSDictionary
        logger.trace("Receive data: \(jsonReceived)")
    } catch {
        logger.warning("Cannot parse JSON")
    }
    
    let decoder = JSONDecoder()
    
    return try decoder.decode(T.self, from: data)
}

func getModels<T: Decodable>(userToken: String, logger: Logger) async throws -> T {
    var request = URLRequest(url: URL(string: "\(API_URL)models")!)
    
    request.httpMethod = "GET"
    request.timeoutInterval = 30
    
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("Bearer \(userToken)", forHTTPHeaderField: "Authorization")
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
        throw NSError(domain: "HTTPError", code: (response as? HTTPURLResponse)?.statusCode ?? -1, userInfo: nil)
    }
    
    let decoder = JSONDecoder()
    
    return try decoder.decode(T.self, from: data)
}
