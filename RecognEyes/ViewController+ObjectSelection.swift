/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Methods on the main view controller for handling virtual object loading and movement
*/

import UIKit
import ARKit

extension ViewController: VirtualObjectSelectionViewControllerDelegate {

    // MARK: - VirtualObjectSelectionViewControllerDelegate
    
    // - Tag: Turn on sound
    func virtualObjectSelectionViewController(_: VirtualObjectSelectionViewController, didSelectObject object: Box) {
        print("object selected, starting sound")
        
        //if object is selected do not allow more objects to be placed
        self.shouldPlaceAnchors = false
        print("select ", self.shouldPlaceAnchors)

        //remove any previously selected objects and turn off positional audio and distance sound
        self.boxController.selectedObjects.forEach{ index in
            self.boxController.stopSound(at: self.boxController.loadedObjects[index])
            self.boxController.stopSpeakDistance()
        }
        
        // empty set
        self.boxController.selectedObjects = IndexSet()
        
        guard let index = self.boxController.loadedObjects.firstIndex(of: object) else {return}
        self.boxController.selectedObjects.insert(index)
        self.boxController.playSound(at: object, audioSource: audioSource)
        self.boxController.speakDistance(from: self.sceneView.session, to: object, synthesizer: self.synthesizer)
    }

    // - Tag: Turn off sound
    func virtualObjectSelectionViewController(_: VirtualObjectSelectionViewController, didDeselectObject object: Box) {
        
        //allow placing anchors again
        self.shouldPlaceAnchors = true
        print("deselect ", self.shouldPlaceAnchors)
        
        
        
        print("object deselected, stopping sound")
        guard let index = self.boxController.loadedObjects.firstIndex(of: object) else {return}
        self.boxController.selectedObjects.remove(index)
        self.boxController.stopSound(at: object)
        self.boxController.stopSpeakDistance()
    }

    // MARK: Object Loading UI
    
    func displayObjectLoadingUI() {
        // Show progress indicator.
        spinner.startAnimating()
        addObjectButton.setImage(#imageLiteral(resourceName: "buttonring"), for: [])
        addObjectButton.isEnabled = false
        isRestartAvailable = false
    }

    func hideObjectLoadingUI() {
        // Hide progress indicator.
        spinner.stopAnimating()
        addObjectButton.setImage(#imageLiteral(resourceName: "add"), for: [])
        addObjectButton.setImage(#imageLiteral(resourceName: "addPressed"), for: [.highlighted])
        addObjectButton.isEnabled = true
        isRestartAvailable = true
    }
}
