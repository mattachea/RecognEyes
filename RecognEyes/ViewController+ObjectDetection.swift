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
//                print("The device orientation is unknown, the predictions may be affected")
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
    
    // MARK: - AR ANCHOR
    func addAnchor(observation: VNRecognizedObjectObservation) {
        let rect = self.bounds(for: observation)
        let text = observation.labels.first?.identifier
        let point = CGPoint(x: rect.midX, y: rect.midY)
        let scnHitTestResults = sceneView.hitTest(point,
                                                  options: [SCNHitTestOption.searchMode: SCNHitTestSearchMode.all.rawValue])
        
        guard !scnHitTestResults.contains(where: { $0.node.name == BubbleNode.name })
        else {
            print("Hit test failed, node with same name found")
            return
            
        }
        print("Attempting to place node")
        if let camera = sceneView.session.currentFrame?.camera, case .normal = camera.trackingState,
           let query = sceneView.raycastQuery(from: point, allowing: .existingPlaneInfinite, alignment: .any),
            let result = sceneView.session.raycast(query).first {
            
            print("Found plane")
            
            if let planeAnchor = result.anchor as? ARPlaneAnchor {
                let bubbleNode = BubbleNode(text: text!)
                let position = SCNVector3(result.worldTransform.columns.3.x, result.worldTransform.columns.3.y, result.worldTransform.columns.3.z)
                print("Placing node")
                bubbleNode.worldPosition = position
                updateQueue.async {
                    self.sceneView.scene.rootNode.addChildNode(bubbleNode)
                }
            } else {
                print("Failed to place bubbleNode, no plane detected")
            }
        }
    }
    
    // - Tag: PlaceVirtualContent
    func loadAndPlaceVirtualObject(object: VirtualObject) {
        virtualObjectLoader.loadVirtualObject(object, loadedHandler: { [unowned self] loadedObject in

            do {
                let scene = try SCNScene(url: object.referenceURL, options: nil)
                self.sceneView.prepare([scene], completionHandler: { _ in
                    DispatchQueue.main.async {
                        self.hideObjectLoadingUI()
                        self.placeVirtualObject(loadedObject)
                    }
                })
            } catch {
                fatalError("Failed to load SCNScene from object.referenceURL")
            }

        })
        displayObjectLoadingUI()
    }

}