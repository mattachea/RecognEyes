//
//  ObjectDetection.swift
//  ARKitInteraction
//
//  Created by Matthew Chea on 2/27/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import UIKit
import CoreML
import Vision
import SceneKit
import ARKit


extension ViewController {
    
    
    func setupObjectDetection() {
        // Load the detection models
        guard let mlModel = try? doorYolo(configuration: .init()).model,
              let detector = try? VNCoreMLModel(for: mlModel) else {
            print("Failed to load detector!")
            return
        }
        // Use a threshold provider to specify custom thresholds for the object detector.
        detector.featureProvider = ThresholdProvider()
        
        objectDetectionRequest = VNCoreMLRequest(model: detector) { [weak self] request, error in
            self?.detectionRequestHandler(request: request, error: error)
        }
        // .scaleFill results in a slight skew but the model was trained accordingly
        objectDetectionRequest.imageCropAndScaleOption = .scaleFill
    }
    
    
    func detect(frame: ARFrame) {
        //only do detection when camera in a good state.
        if let camera = session.currentFrame?.camera, case .normal = camera.trackingState {
            predictionQueue.async {
                /// - Tag: MappingOrientation
                // The frame is always oriented based on the camera sensor,
                // so in most cases Vision needs to rotate it for the model to work as expected.
                let orientation = UIDevice.current.orientation
                
                // The image captured by the camera
                let image = frame.capturedImage
                
                let imageOrientation: CGImagePropertyOrientation
                switch orientation {
                case .portrait:
                    imageOrientation = .right
                case .portraitUpsideDown:
                    imageOrientation = .left
                case .landscapeLeft:
                    imageOrientation = .up
                case .landscapeRight:
                    imageOrientation = .down
                case .unknown:
                    //print("The device orientation is unknown, the predictions may be affected")
                    fallthrough
                default:
                    // By default keep the last orientation
                    // This applies for faceUp and faceDown
                    imageOrientation = self.lastOrientation
                }
                
                // For object detection, keeping track of the image buffer size
                // to know how to draw bounding boxes based on relative values.
                if self.bufferSize == nil || self.lastOrientation != imageOrientation {
                    self.lastOrientation = imageOrientation
                    let pixelBufferWidth = CVPixelBufferGetWidth(image)
                    let pixelBufferHeight = CVPixelBufferGetHeight(image)
                    if [.up, .down].contains(imageOrientation) {
                        self.bufferSize = CGSize(width: pixelBufferWidth,
                                                 height: pixelBufferHeight)
                    } else {
                        self.bufferSize = CGSize(width: pixelBufferHeight,
                                                 height: pixelBufferWidth)
                    }
                }
                
                
                /// - Tag: PassingFramesToVision
                
                // Invoke a VNRequestHandler with that image
                let handler = VNImageRequestHandler(cvPixelBuffer: image, orientation: imageOrientation, options: [:])
                
                do {
                    try handler.perform([self.objectDetectionRequest])
                } catch {
                    print("CoreML request failed with error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    
    
    
    /// Handles results from the detection requests
    ///
    /// - parameters:
    ///     - request: The VNRequest that has been processed
    ///     - error: A potential error that may have occurred
    func detectionRequestHandler(request: VNRequest, error: Error?) {
        // Perform several error checks before proceeding
        if let error = error {
            print("An error occurred with the vision request: \(error.localizedDescription)")
            return
        }
        guard let request = request as? VNCoreMLRequest else {
            print("Vision request is not a VNCoreMLRequest")
            return
        }
        guard let observations = request.results as? [VNRecognizedObjectObservation] else {
            print("Request did not return recognized objects: \(request.results?.debugDescription ?? "[No results]")")
            return
        }
        
        guard !observations.isEmpty else {
            removeBoxes()
            return
        }
        
        guard let observation = observations.first else {
            return
        }
        
        
        drawBox(observation: observation)
        addAnchor(observation: observation)
        
    }
    
    
    
    
    //     MARK: - AR ANCHOR
    func addAnchor(observation: VNRecognizedObjectObservation) {
        guard !coachingOverlay.isActive else { return }
        
        guard let classification = observation.labels.first else {
                print("confidence too low")
                return
        }
        
        DispatchQueue.main.async {
            let rect = self.bounds(for: observation)
            let text = observation.labels.first?.identifier
            let point = CGPoint(x: rect.midX, y: rect.midY)
            let scnHitTestResults = self.sceneView.hitTest(point,
                                                           options: [SCNHitTestOption.searchMode: SCNHitTestSearchMode.all.rawValue])
            guard !scnHitTestResults.contains(where: { $0.node.name == Box.name })
            
            else {
                //print("Hit test failed, node with same name found")
                return
                
            }
            if let camera = self.sceneView.session.currentFrame?.camera, case .normal = camera.trackingState,
               let query = self.sceneView.raycastQuery(from: point, allowing: .existingPlaneInfinite, alignment: .any),
               let result = self.sceneView.session.raycast(query).first {
                
                
                if let _ = result.anchor as? ARPlaneAnchor {
                    let boxNode = Box(text: text!, raycastResult: result)
                    self.positionNode(box: boxNode, at: result)
                    
                    self.updateQueue.async {
                        self.sceneView.scene.rootNode.addChildNode(boxNode)
                        self.boxController.loadedObjects.append(boxNode)
                        print(classification.identifier)
                        self.sayDescription(text: classification.identifier + " detected")
                    }
                    
                } else {
                    //print("Failed to place boxNode, no plane detected")
                }
            }
        }
    }
    
    func positionNode(box: Box, at rayCastResult: ARRaycastResult) {
        box.transform = SCNMatrix4(rayCastResult.anchor!.transform)
        box.eulerAngles = SCNVector3Make(box.eulerAngles.x + (Float.pi / 2), box.eulerAngles.y, box.eulerAngles.z)
        box.position = SCNVector3Make(rayCastResult.worldTransform.columns.3.x, rayCastResult.worldTransform.columns.3.y, rayCastResult.worldTransform.columns.3.z)
        
    }
}
