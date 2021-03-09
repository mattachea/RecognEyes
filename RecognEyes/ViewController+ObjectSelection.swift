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
        
    }

    func virtualObjectSelectionViewController(_: VirtualObjectSelectionViewController, didDeselectObject object: Box) {
        
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
