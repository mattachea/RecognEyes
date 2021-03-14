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
