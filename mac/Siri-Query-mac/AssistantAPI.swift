//
//  SiriQueryAPI.swift
//  Siri-Query-mac
//
//  Created by Cal Stephens on 4/23/17.
//  Copyright © 2017 SiriQuery. All rights reserved.
//

import Foundation

class AssistantAPI {
    
    private static let developmentMode = false
    
    static var baseURL: URL {
        if AssistantAPI.developmentMode {
            return URL(string: "http://localhost:8081")!
        } else {
            //http://bit.ly/2oxzOxW
            return URL(string:"http://server.calstephens.tech:8081")!
        }
    }
    
    static var currentTaskID: String?
    
    static func resetServer() {
        dataTask(for: "/reset", completion: { response in
            print("reset server: \(response ?? "none")")
        })
    }
    
    static func tweetsAvailable(completion: @escaping (Bool) -> ()) {
        dataTask(for: "/tweetsAvailable", completion: { response in
            
            if let response = response {
                if response == "false" {
                    completion(false)
                } else {
                    AssistantAPI.currentTaskID = response //save the task id
                    completion(true)
                }
            }
                
            //error
            else {
                completion(false)
            }
        })
    }
    
    static func textForNextTweet(completion: @escaping (String?) -> ()) {
        dataTask(for: "/nextTweet", completion: { response in
        
            if let response = response {
                completion(response)
            } else {
                completion(nil)
            }
        })
    }
    
    static func deliverResponse(
        siriResponse: String? = nil,
        alexaResponse: String? = nil,
        googleResponse: String? = nil,
        completion: @escaping () -> Void)
    {
        var bodyDict = [String: String]()
        bodyDict["task-id"] = currentTaskID!
        
        if let siriResponse = siriResponse { bodyDict["siri-response"] = siriResponse }
        if let alexaResponse = alexaResponse { bodyDict["alexa-response"] = alexaResponse }
        if let googleResponse = googleResponse { bodyDict["google-response"] = googleResponse }
        let bodyJson = try! JSONSerialization.data(withJSONObject: bodyDict, options: [])
        print(String(data: bodyJson, encoding: .utf8))
        
        
        //post the data
        let url = AssistantAPI.baseURL.appendingPathComponent("/deliverAssistantResponses")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = bodyJson
        request.setValue("application/json", forHTTPHeaderField:"Content-Type")
        
        URLSession.shared.dataTask(with: request, completionHandler: { (data, _, error) -> () in
            if let data = data {
                print("uploaded with response: \(String(data: data, encoding: .utf8) ?? "")")
                completion()
            }
        }).resume()
    }
    
    //MARK: - Helpers
    
    private static func dataTask(for endpoint: String, completion: @escaping (String?) -> ()) {
        
        let url = AssistantAPI.baseURL.appendingPathComponent(endpoint)
        
        let task = URLSession.shared.dataTask(with: url, completionHandler: { data, _, error in
            
            if let error = error {
                print("error on data task: \(error)")
            }
            
            if let data = data, let string = String(data: data, encoding: .utf8) {
                completion(string)
            } else {
                completion(nil)
            }
            
        })
        
        task.resume()
    }
    
}
