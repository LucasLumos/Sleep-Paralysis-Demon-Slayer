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

class ViewController: UIViewController {

    var audioEngine:AVAudioEngine?
    var inputBus: AVAudioNodeBus?
    var inputFormat: AVAudioFormat?
    var streamAnalyzer: SNAudioStreamAnalyzer?
    var request: SNClassifySoundRequest?
    let analysisQueue = DispatchQueue(label: "com.example.AnalysisQueue")

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    //Test
    @IBAction func ActivateEngine(_ sender: Any) {
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






