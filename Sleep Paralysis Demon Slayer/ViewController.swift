//
//  ViewController.swift
//  Sleep Paralysis Demon Slayer
//
//  Created by Lucas Tang on 9/25/23.
//

import Foundation
import SwiftUI
import UIKit
import AVFoundation
import AudioToolbox
import SoundAnalysis
import Combine

let resultsObserver = ResultsObserver()

var audioPlayer : AVAudioPlayer?
var t:Double = 30

var hum:Bool = true
var sigh:Bool = true
var babble:Bool = true
var gargle:Bool = true
var cry:Bool = true
var scream:Bool = true
var moo:Bool = true
var whale:Bool = true
var dog:Bool = true
var lion:Bool = true
var growl:Bool = true

var logtext:String = ""

class ViewController: UIViewController {

    @IBOutlet weak var ThresholdLabel: UILabel!
    @IBOutlet weak var thresholdSlider: UISlider!
    @IBOutlet weak var StopAlarmButton: UIButton!
    
    @IBOutlet weak var logText: UILabel!
    
    var audioEngine:AVAudioEngine?
    var inputBus: AVAudioNodeBus?
    var inputFormat: AVAudioFormat?
    var streamAnalyzer: SNAudioStreamAnalyzer?
    var request: SNClassifySoundRequest?
    let analysisQueue = DispatchQueue(label: "com.example.AnalysisQueue")

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        startAudioEngine()
        // Create a new stream analyzer.
        streamAnalyzer = SNAudioStreamAnalyzer(format: inputFormat!)
        
        let version1 = SNClassifierIdentifier.version1
        do {
            // Start the stream of audio data.
            request = try SNClassifySoundRequest(classifierIdentifier: version1)
            try streamAnalyzer!.add(request!,
                                   withObserver: resultsObserver)
        } catch {
            print("Unable to start sound  request: \(error.localizedDescription)")
        }
        
        installAudioTap()
        
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            print("Session is Active")
            //try AVAudioSession.sharedInstance().setActive(false)
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker,.interruptSpokenAudioAndMixWithOthers, .allowAirPlay, .mixWithOthers])
            print("Playback OK")

        } catch {
            print(error)
        }
    }
    
    func analyzeAudio(buffer: AVAudioBuffer, at time: AVAudioTime) {
        analysisQueue.async {
            self.streamAnalyzer!.analyze(buffer,
                                        atAudioFramePosition: time.sampleTime)
        }
    }
    
    func startAudioEngine() {
        // Create a new audio engine.
        
        audioEngine = AVAudioEngine()
        // Get the native audio format of the engine's input bus.
        inputBus = AVAudioNodeBus(0)
        inputFormat = audioEngine!.inputNode.inputFormat(forBus: inputBus!)
        do {
            // Start the stream of audio data.
            try audioEngine!.start()
        } catch {
            print("Unable to start AVAudioEngine: \(error.localizedDescription)")
        }
    }

    func installAudioTap() {
        audioEngine!.inputNode.installTap(onBus: inputBus!,
                                         bufferSize: 8192,
                                         format: inputFormat,
                                         block: analyzeAudio(buffer:at:))
    }
    
    
    @IBAction func stopMusic(_ sender: Any) {
        audioPlayer?.stop()
    }
    
    @IBAction func changedThreshold(_ sender: Any) {
        t = Double(thresholdSlider.value.rounded())
        ThresholdLabel.text = String(Int(t)) + " %"
    }
    
    @IBAction func showLog(_ sender: Any) {
        logText.text = logtext
    }
    
    
    @IBOutlet weak var humSwitch: UISwitch!
    @IBAction func humChanged(_ sender: Any) {
        if (humSwitch.isOn) {
            hum = true
        }else{
            hum = false
        }
    }
    
    
    @IBOutlet weak var sighSwitch: UISwitch!
    
    @IBAction func sighChanged(_ sender: Any) {
        if (sighSwitch.isOn) {
            sigh = true
        }else{
            sigh = false
        }
    }
    
    @IBOutlet weak var babbleSwitch: UISwitch!
    
    @IBAction func babbleChanged(_ sender: Any) {
        if (babbleSwitch.isOn) {
            babble = true
        }else{
            babble = false
        }
    }
    
}



func playSound(){
     
       //getting the resource path
       let resourcePath = Bundle.main.url(forResource: "safe1", withExtension: "m4a")
    
       do{
           //initializing the audio player with the resource path
           
           do {
               try AVAudioSession.sharedInstance().setActive(true)
               print("Session is Active")
               //try AVAudioSession.sharedInstance().setActive(false)
               //try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker,.interruptSpokenAudioAndMixWithOthers, .allowAirPlay, .mixWithOthers])
               print("Playback OK")

           } catch {
               print(error)
           }
           
           
           audioPlayer = try AVAudioPlayer(contentsOf: resourcePath!)
           audioPlayer?.numberOfLoops = 10
           
           //play the audio
           audioPlayer?.play()
           print("playing sound")

          //stop the audio
         // audioPlayer?.stop()
          
    
       }
       catch{
         //error handling
           print(error.localizedDescription)
       }
    
    
   }

/// An observer that receives results from a classify sound request.
class ResultsObserver: NSObject, SNResultsObserving {
    /// Notifies the observer when a request generates a prediction.
    func request(_ request: SNRequest, didProduce result: SNResult) {
        // Downcast the result to a classification result.
        guard let result = result as? SNClassificationResult else  { return }


        // Get the prediction with the highest confidence.
        guard let classification = result.classifications.first else { return }


        // Get the starting time.
        let timeInSeconds = result.timeRange.start.seconds


        // Convert the time to a human-readable string.
        let formattedTime = String(format: "%.2f", timeInSeconds)
        print("Analysis result for audio at time: \(formattedTime)")


        // Convert the confidence to a percentage string.
        let percent = classification.confidence * 100.0
        let percentString = String(format: "%.2f%%", percent)


        // Print the classification's name (label) with its confidence.
        print("\(classification.identifier): \(percentString) confidence.\n")
        
        //triger events
        if (hum && classification.identifier == "humming" && percent > t){
            logtext = logtext + " hum"
            playSound()
            
        }else if (sigh && classification.identifier == "sigh" && percent > t){
            logtext = logtext + " sigh"
            playSound()
        }else if ( babble && classification.identifier == "babble" && percent > t){
            logtext = logtext + " babble"
            playSound()
        }else if (gargle && classification.identifier == "gargling" && percent > t){
            logtext = logtext + " gargle"
            playSound()
        }else if (cry && classification.identifier == "cyring_sobbing" && percent > t){
            logtext = logtext + " cry"
            playSound()
        }else if (scream && classification.identifier == "screaming" && percent > t){
            logtext = logtext + " scream"
            playSound()
        }else if (lion && classification.identifier == "lion_roar" && percent > t){
            logtext = logtext + " lion"
            playSound()
        }else if (whale && classification.identifier == "whale_vocalization" && percent > t){
            logtext = logtext + " whale"
            playSound()
        }else if (dog && classification.identifier == "dog" && percent > t){
            logtext = logtext + " dog"
            playSound()
        }else if (growl && classification.identifier == "dog_growl" && percent > t){
            logtext = logtext + " growl"
            playSound()
        }else if ((classification.identifier == "clapping" && percent > 0.6) || (classification.identifier == "finger_snapping" && percent > 0.6) ){
            logtext = logtext + " clap/snap"
            audioPlayer?.stop()
        }
    
    }

    /// Notifies the observer when a request generates an error.
    func request(_ request: SNRequest, didFailWithError error: Error) {
        print("The analysis failed: \(error.localizedDescription)")
    }


    /// Notifies the observer when a request is complete.
    func requestDidComplete(_ request: SNRequest) {
        print("The request completed successfully!")
    }
}






