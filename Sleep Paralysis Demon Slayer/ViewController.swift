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
var t:Float = 30

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

    let userDefaults = UserDefaults.standard

    let hum_KEY = "humKey"
    let sigh_KEY = "sighKey"
    let babble_KEY = "babbleKey"
    let gargle_KEY = "gargleKey"
    let cry_KEY = "cryKey"
    let scream_KEY = "screamKey"
    let moo_KEY = "mooKey"
    let whale_KEY = "whaleKey"
    let dog_KEY = "dogKey"
    let lion_KEY = "lionKey"
    let growl_KEY = "growlKey"
    let threshold_KEY = "thresholdKey"
    
    
    
    func checkSwitchState()
    {

        thresholdSlider.value = userDefaults.float(forKey: threshold_KEY)
        t = Float(thresholdSlider.value.rounded())
        ThresholdLabel.text = String(Int(t)) + " %"
        
        if(userDefaults.bool(forKey: hum_KEY))
        {
            humSwitch.setOn(true, animated: false)
            hum = true
        }
        else
        {
            humSwitch.setOn(false, animated: false)
            hum = false
        }
        
        if(userDefaults.bool(forKey: sigh_KEY))
        {
            sighSwitch.setOn(true, animated: false)
            sigh = true
        }
        else
        {
            sighSwitch.setOn(false, animated: false)
            sigh = false
        }
        
        if(userDefaults.bool(forKey: babble_KEY))
        {
            babbleSwitch.setOn(true, animated: false)
            babble = true
        }
        else
        {
            babbleSwitch.setOn(false, animated: false)
            babble = false
        }
        
        if(userDefaults.bool(forKey: gargle_KEY))
        {
            gargleSwitch.setOn(true, animated: false)
            gargle = true
        }
        else
        {
            gargleSwitch.setOn(false, animated: false)
            gargle = false
        }
        
        if(userDefaults.bool(forKey: cry_KEY))
        {
            crySwitch.setOn(true, animated: false)
            cry = true
        }
        else
        {
            crySwitch.setOn(false, animated: false)
            cry = false
        }
        
        if(userDefaults.bool(forKey: scream_KEY))
        {
            screamSwitch.setOn(true, animated: false)
            scream = true
        }
        else
        {
            screamSwitch.setOn(false, animated: false)
            scream = false
        }
        
        if(userDefaults.bool(forKey: moo_KEY))
        {
            mooSwitch.setOn(true, animated: false)
            moo = true
        }
        else
        {
            mooSwitch.setOn(false, animated: false)
            moo = false
        }
        
        if(userDefaults.bool(forKey: whale_KEY))
        {
            whaleSwitch.setOn(true, animated: false)
            whale = true
        }
        else
        {
            whaleSwitch.setOn(false, animated: false)
            whale = false
        }
        
        if(userDefaults.bool(forKey: dog_KEY))
        {
            dogSwitch.setOn(true, animated: false)
            dog = true
        }
        else
        {
            dogSwitch.setOn(false, animated: false)
            dog = false
        }
        
        if(userDefaults.bool(forKey: growl_KEY))
        {
            growlSwitch.setOn(true, animated: false)
            growl = true
        }
        else
        {
            growlSwitch.setOn(false, animated: false)
            growl = false
        }
        
        if(userDefaults.bool(forKey: lion_KEY))
        {
            lionSwitch.setOn(true, animated: false)
            lion = true
        }
        else
        {
            lionSwitch.setOn(false, animated: false)
            lion = false
        }
        
    }

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
        checkSwitchState()
        
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
    
    
    @IBAction func infoButton(_ sender: Any) {
        let alertController = UIAlertController(title: "How the app works", message: "The app will listen in the background for the selected sounds, and play music when the that sound is detected. You can set the sensitivity using the activiation threshold slider (higher is harder to detect). You can stop the sound by clicking the stop sound button at the bottom. The show log button shows what sounds have been detected thus far. The sounds available here are some sounds that could be potentially detected during sleep paralysis episodes. You can try having all the options on, and set a lower activation threshold to start, and turn off options that triggers false starts until you reach a satisfactory threshold and sound settings. The app will remember this setting even if you close the app and be set to it next time you open the app.", preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default) {
            (action: UIAlertAction!) in
            // Code in this block will trigger when OK button tapped.
            
        }
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func stopMusic(_ sender: Any) {
        audioPlayer?.stop()
    }
    
    @IBAction func changedThreshold(_ sender: Any) {
        t = Float(thresholdSlider.value.rounded())
        ThresholdLabel.text = String(Int(t)) + " %"

    }
    
    
    @IBAction func sliderDone(_ sender: Any) {
        userDefaults.set(t, forKey: threshold_KEY)
    }
    
    @IBAction func showLog(_ sender: Any) {
        logText.text = logtext
    }
    
    
    @IBOutlet weak var humSwitch: UISwitch!
    @IBAction func humChanged(_ sender: Any) {
        if (humSwitch.isOn) {
            hum = true
            userDefaults.set(true, forKey: hum_KEY)
        }else{
            userDefaults.set(false, forKey: hum_KEY)
            hum = false
        }
    }
    
    
    @IBOutlet weak var sighSwitch: UISwitch!
    @IBAction func sighChanged(_ sender: Any) {
        if (sighSwitch.isOn) {
            sigh = true
            userDefaults.set(true, forKey: sigh_KEY)
        }else{
            sigh = false
            userDefaults.set(false, forKey: sigh_KEY)
        }
    }
    
    @IBOutlet weak var babbleSwitch: UISwitch!
    
    @IBAction func babbleChanged(_ sender: Any) {
        if (babbleSwitch.isOn) {
            babble = true
            userDefaults.set(true, forKey: babble_KEY)
        }else{
            babble = false
            userDefaults.set(false, forKey: babble_KEY)
        }
    }
    
    @IBOutlet weak var gargleSwitch: UISwitch!
    
    @IBAction func gargleChanged(_ sender: Any) {
        if (gargleSwitch.isOn) {
            userDefaults.set(true, forKey: gargle_KEY)
            gargle = true
        }else{
            gargle = false
            userDefaults.set(false, forKey: gargle_KEY)
        }
    }
    
    @IBOutlet weak var crySwitch: UISwitch!
    
    @IBAction func cryChanged(_ sender: Any) {
        if (crySwitch.isOn) {
            cry = true
            userDefaults.set(true, forKey: cry_KEY)
        }else{
            cry = false
            userDefaults.set(false, forKey: cry_KEY)
        }
    }
    
    @IBOutlet weak var screamSwitch: UISwitch!
    
    @IBAction func screamChanged(_ sender: Any) {
        if (screamSwitch.isOn) {
            scream = true
            userDefaults.set(true, forKey: scream_KEY)
        }else{
            scream = false
            userDefaults.set(false, forKey: scream_KEY)
        }
    }
    
    @IBOutlet weak var mooSwitch: UISwitch!
    @IBAction func mooChanged(_ sender: Any) {
        if (mooSwitch.isOn) {
            moo = true
            userDefaults.set(true, forKey: moo_KEY)
        }else{
            moo = false
            userDefaults.set(false, forKey: moo_KEY)
        }
    }
    
    @IBOutlet weak var whaleSwitch: UISwitch!
    
    @IBAction func whaleChanged(_ sender: Any) {
        if (whaleSwitch.isOn) {
            whale = true
            userDefaults.set(true, forKey: whale_KEY)
        }else{
            whale = false
            userDefaults.set(false, forKey: whale_KEY)
        }
    }
    
    @IBOutlet weak var dogSwitch: UISwitch!
    @IBAction func dogChanged(_ sender: Any) {
        if (dogSwitch.isOn) {
            dog = true
            userDefaults.set(true, forKey: dog_KEY)
        }else{
            dog = false
            userDefaults.set(false, forKey: dog_KEY)
        }
    }
    
    
    @IBOutlet weak var growlSwitch: UISwitch!
    @IBAction func growlChanged(_ sender: Any) {
        if (growlSwitch.isOn) {
            growl = true
            userDefaults.set(true, forKey: growl_KEY)
        }else{
            growl = false
            userDefaults.set(false, forKey: growl_KEY)
        }
    }
    
    @IBOutlet weak var lionSwitch: UISwitch!
    
    @IBAction func lionChanged(_ sender: Any) {
        if (lionSwitch.isOn) {
            lion = true
            userDefaults.set(true, forKey: lion_KEY)
        }else{
            lion = false
            userDefaults.set(false, forKey: lion_KEY)
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
        let percent = Float(classification.confidence * 100.0)
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






