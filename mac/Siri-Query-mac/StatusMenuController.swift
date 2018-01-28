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

class StatusMenuController: NSObject {
    @IBOutlet weak var menuOutlet: NSMenuItem!
    
    var player: AVPlayer!
    var recorder: AVAudioRecorder!
    var levelTimer: Timer!
    var pollingTimer: Timer!
    var startTime: Date!
    
    var googleProcess: Process?
    
    @IBOutlet weak var statusMenu: NSMenu!
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    override func awakeFromNib() {
        let icon = NSImage(named: NSImage.Name(rawValue: "statusIcon"))
        icon?.isTemplate = true // best for dark mode
        statusItem.image = icon
        statusItem.menu = statusMenu
        
        AssistantAPI.resetServer()
        pollForNextTweet()
    }
    
    func pollForNextTweet() {
        AssistantAPI.tweetsAvailable(completion: { tweetsAreAvailable in
            guard tweetsAreAvailable else {
                print("No tweets available for download")
                return
            }
            
            AssistantAPI.textForNextTweet(completion: { tweetText in
                guard let tweetText = tweetText else { return }
                print("Received tweet \(tweetText)")
                self.spawnAlexa(withQuery: tweetText, completion: {
                    AssistantAPI.deliverResponse(alexaResponse: "spawned alexa response", completion: {
                        self.pollForNextTweet()
                    })
                })
            })
        })
    }
    
    func spawnAlexa(withQuery query: String, completion: @escaping () -> Void) {
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
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.0, execute: {
                pipe.fileHandleForWriting.write("q".data(using: .utf8)!)
            })
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 7.5, execute: {
                task.terminate()
                completion()
            })
        })
    }
    
    func spawnGoogle(withQuery query: String) {
        googleProcess = Process()
        let pipe = Pipe()
        googleProcess?.launchPath = "/Library/Frameworks/Python.framework/Versions/2.7/bin/googlesamples-assistant-pushtotalk"
        googleProcess?.arguments = []
        googleProcess?.standardInput = pipe
        
        googleProcess?.launch()
        googleProcess?.qualityOfService = .userInteractive
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
            pipe.fileHandleForWriting.write("".data(using: .utf8)!)
            self.executeTask("say", arguments: [query])
            self.record()
        })
    }
    
    private func executeTask(_ name: String, arguments: [String]) {
        let task = Process()
        task.launchPath = "/usr/bin/\(name)"
        task.arguments = arguments
        task.launch()
        task.waitUntilExit()
    }
    
    func runSiri(rawText: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            let task = Process()
            task.launchPath = "/usr/bin/say"
            task.arguments = [rawText]
            task.launch()
            task.waitUntilExit()
        })
        self.record()
        self.menuOutlet.title = "Listening to Siri..."
    }


    func record() {
        let outputPath = "\(AppConfiguration.homeDir)/Desktop/output.flac"
        checkFile(path: outputPath)
        let url = URL(fileURLWithPath: outputPath)
        
        let startTime = Date()
        
        recorder = try? AVAudioRecorder(url: url, settings: [AVFormatIDKey : kAudioFormatFLAC, AVSampleRateKey : 44100])
        recorder.prepareToRecord()
        recorder.isMeteringEnabled = true
        print(recorder.record())
        
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { (Timer) in
            self.recorder.updateMeters()
            print(self.recorder.averagePower(forChannel: 0))

            if self.recorder.averagePower(forChannel: 0) <= -120.0 {
                if Date().timeIntervalSince(startTime) > 3 {
                    self.recorder.stop()
                    self.levelTimer.invalidate()
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(10), execute: {
                        //TODO: do something speech-to-text
                        //AssistantAPI.deliverResponse(imagePath: imagePath, audioPath: outputPath)
                        //self.getInput()
                        self.googleProcess?.terminate()
                        WatsonAPI.curlSpeechToText(fromFileOnDesktopNamed: "output.flac", completion: { string in
                            print(string)
                        })
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
    
    
    /*func getInput() {
        menuOutlet.title = "Waiting for input..."
        
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { (Timer) in
            self.download(url: AssistantAPI.baseURL.appendingPathComponent("/nextRecording.wav"), to: URL(fileURLWithPath: inputPath), completion: { text in
                self.runSiri(rawText: text)
            })
        }
    }
    
    func download(url: URL, to localUrl: URL, completion: @escaping (String) -> ()) {
        checkFile(path: inputPath)
        
        AssistantAPI.textForNextTweet(completion: ?????)(completion: { newRecordingAvailable in
            if newRecordingAvailable {
                
                SiriQueryAPI.rawTextForNextQuery(completion: { rawText in
                    if let rawText = rawText {
                        completion(rawText)
                    }
                })
                
                //download the new file
                print("downloading")
                self.menuOutlet.title = "Downloading..."
                
                guard let id = SiriQueryAPI.currentTaskID else { return }
                let downloadURL = SiriQueryAPI.baseURL.appendingPathComponent("/recordings/\(id).wav")
                
                let task = URLSession.shared.downloadTask(with: downloadURL) { (tempLocalUrl, response, error) in
                    if let tempLocalUrl = tempLocalUrl, error == nil {
                        do {
                            self.pollingTimer.invalidate()
                            
                            try FileManager.default.copyItem(at: tempLocalUrl, to: localUrl)
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100), execute: {
                                print("running Siri")
                                self.menuOutlet.title = "Running Siri..."
                                completion("FALSE")
                            })
                            
                        } catch (let writeError) {
                            print("error writing file \(localUrl) : \(writeError)")
                            self.menuOutlet.title = "Error writing file \(localUrl) : \(writeError)"
                        }
                    }
                }
                task.resume()
                
            }
        })
        
    }*/
    
}
