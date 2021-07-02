//
//  BoxController.swift
//  RecognEyes
//
//  Created by Matthew Chea on 3/8/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import Foundation
import ARKit

class BoxController {
    var loadedObjects = [Box]()
    var selectedObjects = IndexSet()
    var speakDistanceTimer = Timer()
    
    //MARK: -Distance
    func speakDistance(from session: ARSession , to box: Box, synthesizer: AVSpeechSynthesizer) {
        
        speakDistanceTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { timer in
            let distance = self.getDistance(from: session.currentFrame!.camera, to: box)
            let utterance = AVSpeechUtterance(string: String(distance) + "feet")
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            utterance.rate = 0.5
            utterance.volume = 0.25
            synthesizer.speak(utterance)
        }
    }
    
    
    func stopSpeakDistance() {
        speakDistanceTimer.invalidate()
    }
    
    
    // distance in feet to the nearest foot
    func getDistance(from camera: ARCamera,  to box: Box) -> Int {
        return Int(round(simd_distance(box.simdTransform.columns.3, (camera.transform.columns.3)) * 3.21)) //convert meters to feet
    }
    
    // MARK: - Positional Audio
    func playSound(at box: Box, audioSource: SCNAudioSource) {
        // Ensure there is only one audio player
        box.removeAllAudioPlayers()
        // Create a player from the source and add it to `objectNode`        
        box.addAudioPlayer(SCNAudioPlayer(source: audioSource))
        
    }
    
    func stopSound(at box: Box) {

        box.removeAllAudioPlayers()
    }


    // MARK: - Removing Objects
    func removeAllBoxes() {
        // Reverse the indices so we don't trample over indices as objects are removed.
        for index in loadedObjects.indices.reversed() {
            removeBox(at: index)
        }
    }

    /// - Tag: RemoveVirtualObject
    func removeBox(at index: Int) {
        guard loadedObjects.indices.contains(index) else { return }
        // Remove the visual node from the scene graph.
        loadedObjects[index].removeFromParentNode()
        // Recoup resources allocated by the object.
        loadedObjects.remove(at: index)
    }

}
