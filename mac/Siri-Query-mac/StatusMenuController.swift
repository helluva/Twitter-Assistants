//
//  StatusMenuController.swift
//  Siri-Query-mac
//
//  Created by Nate Thompson on 4/22/17.
//  Copyright © 2017 SiriQuery. All rights reserved.
//

import Cocoa
import AVKit
import AVFoundation

// **********************************

let DEVICE_ASSISTANT = Assistant.siri

// **********************************

enum Assistant {
    case alexa
    case siri
    case google
    
    var name: String {
        switch self {
        case .alexa: return "Alexa"
        case .siri: return "Siri"
        case .google: return "Google"
        }
    }
}

class StatusMenuController: NSObject {
    @IBOutlet weak var menuOutlet: NSMenuItem!
    
    var player: AVPlayer!
    var recorder: AVAudioRecorder!
    var levelTimer: Timer!
    var pollingTimer: Timer!
    var startTime: Date!
    
    @IBOutlet weak var statusMenu: NSMenu!
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    override func awakeFromNib() {
        let icon = NSImage(named: NSImage.Name(rawValue: "statusIcon"))
        icon?.isTemplate = true // best for dark mode
        statusItem.image = icon
        statusItem.menu = statusMenu
        
        print("using assistant \(DEVICE_ASSISTANT.name.uppercased())")
        print ("================================")
        
        AssistantAPI.resetServer()
        
        Timer.scheduledTimer(timeInterval: 4.0, target: self, selector: #selector(self.pollForNextTweet), userInfo: nil, repeats: true)
        self.pollForNextTweet()
    }
    
    @objc func pollForNextTweet() {
        guard AssistantAPI.currentTaskID == nil else {
            return
        }
        
        print("Polling...")
        
        AssistantAPI.tweetsAvailable(completion: { tweetsAreAvailable in
            guard tweetsAreAvailable else {
                print("No tweets available for download")
                return
            }
            
            AssistantAPI.textForNextTweet(completion: { tweetText in
                guard let tweetText = tweetText else { return }
                print("Received tweet \(tweetText)")
                
                
                switch DEVICE_ASSISTANT {
                    
                // Amazon Alexa -- interfaces with an Amazon Alexa sdk sample app
                case .alexa:
                    self.spawnAlexa(withQuery: tweetText, completion: { alexaResponse in
                        AssistantAPI.deliverResponse(alexaResponse: alexaResponse ?? "We had trouble communicating with Alexa.")
                    })
                    
                // Google Assistant -- interfaces with a Google Assistant sdk sample app
                case .google:
                    self.spawnGoogle(withQuery: tweetText, completion: { googleAssistantResponse in
                        AssistantAPI.deliverResponse(googleResponse: googleAssistantResponse ?? "We had trouble communicating with Google Assistant.")
                    })
                    
                // Siri -- interfaces with the production macOS Siri.app
                case .siri:
                    self.spawnSiri(rawText: tweetText, completion: { siriResponse in
                        AssistantAPI.deliverResponse(siriResponse: siriResponse ?? "We had trouble communicating with Siri.")
                    })
                    
                }
                
            })
        })
    }
    
    func spawnAlexa(withQuery query: String, completion: @escaping (String?) -> Void) {
        executeTask("killall", arguments: ["SampleApp"] /* SampleApp is the Alexa runner */)
        
        let task = Process()
        let pipe = Pipe()
        task.launchPath = "/Users/cal/sdk-folder/sdk-build/SampleApp/src/SampleApp"
        task.arguments = ["/Users/cal/sdk-folder/sdk-build/Integration/AlexaClientSDKConfig.json"]
        task.standardInput = pipe
        task.launch()
        task.qualityOfService = .userInteractive
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
            pipe.fileHandleForWriting.write("t".data(using: .utf8)!)
            self.executeTask("say", arguments: [query])
            pipe.fileHandleForWriting.write("".data(using: .utf8)!)
            
            self.recordAudioAndConvertToText(
                whenDoneRecording: {
                    pipe.fileHandleForWriting.write("q".data(using: .utf8)!)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                        task.terminate()
                    })
                }, completion: completion)
        })
    }
    
    func spawnGoogle(withQuery query: String, completion: @escaping (String?) -> Void) {
        let process = Process()
        let pipe = Pipe()
        process.launchPath = "/Library/Frameworks/Python.framework/Versions/2.7/bin/googlesamples-assistant-pushtotalk"
        process.arguments = []
        process.standardInput = pipe
        
        process.launch()
        process.qualityOfService = .userInteractive
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
            pipe.fileHandleForWriting.write("".data(using: .utf8)!)
            self.executeTask("say", arguments: [query])
            
            self.recordAudioAndConvertToText(
                whenDoneRecording: { process.terminate() },
                completion: completion)
        })
    }
    
    private func executeTask(_ name: String, arguments: [String]) {
        let task = Process()
        task.launchPath = "/usr/bin/\(name)"
        task.arguments = arguments
        task.launch()
        task.waitUntilExit()
    }
    
    func spawnSiri(rawText: String, completion: @escaping (String?) -> Void) {
        NSWorkspace.shared.launchApplication("/Applications/Siri.app")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(700), execute: {
            let task = Process()
            task.launchPath = "/usr/bin/say"
            task.arguments = [rawText]
            task.launch()
            task.waitUntilExit()
            
            self.recordAudioAndConvertToText(whenDoneRecording: { return }, completion: completion)
        })
    }

    func recordAudioAndConvertToText(whenDoneRecording: @escaping () -> Void, completion: @escaping (String?) -> Void) {
        let outputPath = "\(AppConfiguration.homeDir)/Desktop/output.ulaw"
        checkFile(path: outputPath)
        let url = URL(fileURLWithPath: outputPath)
        
        let startTime = Date()

        recorder = try? AVAudioRecorder(url: url, settings: [AVFormatIDKey : kAudioFormatULaw, AVSampleRateKey : 44100])
        recorder.prepareToRecord()
        recorder.isMeteringEnabled = true
        let recorderSuccess = recorder.record()
        print("RECORDING: \(recorderSuccess)")
        
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { (Timer) in
            self.recorder.updateMeters()
            print(self.recorder.averagePower(forChannel: 0))

            if self.recorder.averagePower(forChannel: 0) <= -120.0 {
                if Date().timeIntervalSince(startTime) > 3 {
                    self.recorder.stop()
                    self.levelTimer.invalidate()
                    whenDoneRecording()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(10), execute: {
                        //TODO: do something speech-to-text
                        //AssistantAPI.deliverResponse(imagePath: imagePath, audioPath: outputPath)
                        //self.getInput()
                        WatsonAPI.curlSpeechToText(fromFileOnDesktopNamed: "output.ulaw", completion: completion)
                    })
                }
            }
        }
    }

    @IBAction func quitClicked(sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }
    
    
    func checkFile(path: String) {
        let url = URL(fileURLWithPath: path)
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: path) {
            do {
                try fileManager.removeItem(at: url)
            } catch let error as NSError {
                print(error)
                menuOutlet.title = "Error"
            }
        }
    }
    
}
