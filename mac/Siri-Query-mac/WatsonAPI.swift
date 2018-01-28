//
//  WatsonAPI.swift
//  Siri-Query-mac
//
//  Created by Cal Stephens on 1/28/18.
//  Copyright © 2018 SiriQuery. All rights reserved.
//

import Foundation

class WatsonAPI {
    
    private static let speechToTextEndpoint = URL(string: "https://stream.watsonplatform.net/speech-to-text/api/v1/recognize")!
    
    static func curlSpeechToText(fromFileOnDesktopNamed nameOfFileOnDesktop: String, completion: @escaping (String?) -> Void) {
        
        let task = Process()
        let outputPipe = Pipe()
        
        task.standardOutput = outputPipe
        task.launchPath = "/usr/local/opt/curl/bin/curl"
        
        // cURL arguments: https://developer.ibm.com/answers/questions/244630/speech-to-text-error-using-pre-recorded-audio-file.html
        task.arguments = [
            "-s", // silence cURL's progress indicator
            "-X", "POST",
            "-u", "0d884b88-0ed4-43e6-b6d3-a81f4d440ffa:0j6VcHydZj4K", // IBM endpoint username:password
            "--header", "Content-Type: audio/mpeg",
            "--data-binary", "@/Users/\(AppConfiguration.username)/Desktop/\(nameOfFileOnDesktop)",
            "https://stream.watsonplatform.net/speech-to-text/api/v1/recognize"]
        
        print("Spawning Speech to Text request...")
        task.launch()
        task.qualityOfService = .userInteractive
        task.waitUntilExit()
        print("Received Speech to Text response!")
        
        // parse the json response
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        guard let json = try? JSONSerialization.jsonObject(with: outputData, options: []) as? [String: Any] else {
            print("Failed to retrevie speech to text")
            completion(nil)
            return
        }
        
        guard let results = json?["results"] as? [[String: Any]] else {
            print("Failed to retrevie speech to text")
            completion(nil)
            return
        }
        
        var speechToTextResult = ""
        for partialResult in results {
            if let transcript = (partialResult["alternatives"] as? [[String: Any]])?.first?["transcript"] as? String {
                speechToTextResult += transcript
            }
        }
        
        speechToTextResult = speechToTextResult.trimmingCharacters(in: .whitespacesAndNewlines)
        if speechToTextResult.isEmpty {
            completion(nil)
        } else {
            completion(speechToTextResult)
        }
    }
    
}
