/*
ViewController+BoundingBoxes.swift

Abstract:
Convenience extension to draw bounding boxes.
*/

import UIKit
import Vision

extension ViewController {
    /// Sets up CALayers for rendering bounding boxes
    func setupLayers() {
        DispatchQueue.main.async {
            self.detectionOverlay = CALayer() // container layer that has all the renderings of the observations
            self.detectionOverlay.name = "DetectionOverlay"
            self.detectionOverlay.bounds = CGRect(x: 0.0,
                                                  y: 0.0,
                                                  width: self.sceneView.frame.width,
                                                  height: self.sceneView.frame.height)
            self.detectionOverlay.position = CGPoint(x: self.rootLayer.bounds.midX,
                                                     y: self.rootLayer.bounds.midY)
            self.rootLayer.addSublayer(self.detectionOverlay)
        }
    }

    /// Update the size of the overlay layer if the sceneView size changed
    func updateDetectionOverlaySize() {
        DispatchQueue.main.async {
            self.detectionOverlay.bounds = CGRect(x: 0.0,
                                                  y: 0.0,
                                                  width: self.sceneView.frame.width,
                                                  height: self.sceneView.frame.height)
        }
    }

    /// Update layer geometry when needed
    func updateLayerGeometry() {
        DispatchQueue.main.async {
            let bounds = self.rootLayer.bounds
            var scale: CGFloat

            let xScale: CGFloat = bounds.size.width / self.sceneView.frame.height
            let yScale: CGFloat = bounds.size.height / self.sceneView.frame.width

            scale = fmax(xScale, yScale)
            if scale.isInfinite {
                scale = 1.0
            }
            CATransaction.begin()
            CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)

            self.detectionOverlay.position = CGPoint(x: bounds.midX, y: bounds.midY)

            CATransaction.commit()
        }
    }

    /// Creates a text layer to display the label for the given box
    ///
    /// - parameters:
    ///     - bounds: Bounds of the detected object
    ///     - identifier: Class label for the detected object
    ///     - confidence: Confidence in the prediction
    /// - returns: A newly created CATextLayer
    func createTextSubLayerInBounds(_ bounds: CGRect, identifier: String, confidence: VNConfidence) -> CATextLayer {
        let textLayer = CATextLayer()
        textLayer.name = "Object Label"
        let attributedString = NSMutableAttributedString(string: String(format: "\(identifier)\nConfidence:  %.2f", confidence))
        let largeFont = UIFont(name: "Menlo", size: 12)!
        let attributes = [NSAttributedString.Key.font: largeFont,
                          NSAttributedString.Key.foregroundColor: UIColor.white]
        attributedString.addAttributes(attributes,
                                       range: NSRange(location: 0, length: identifier.count))
        textLayer.string = attributedString
        textLayer.bounds = CGRect(x: 0, y: 0, width: bounds.size.height, height: bounds.size.width)
        textLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        textLayer.shadowOpacity = 0.0
        textLayer.foregroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 1.0, 1.0, 1.0])
        textLayer.contentsScale = 2.0 // retina rendering
        return textLayer
    }

    /// Creates a reounded rectangle layer with the given bounds
    /// - parameter bounds: The bounds of the rectangle
    /// - returns: A newly created CALayer
    func createRoundedRectLayerWithBounds(_ bounds: CGRect) -> CALayer {
        let shapeLayer = CALayer()
        shapeLayer.bounds = bounds
        shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        shapeLayer.name = "Found Object"
        shapeLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.0, 0.8, 1.0, 0.6])
        shapeLayer.cornerRadius = 14
        return shapeLayer
    }

    /// Removes all bounding boxes from the screen
    func removeBoxes() {
        drawBoxes(observations: [])
    }

    //NOT NEEDED RIGHT NOW. ONLY NEED TO DRAW ONE BOX
    /// Draws bounding boxes based on the object observations
    ///
    /// - parameter observations: The list of object observations from the object detector
    func drawBoxes(observations: [VNRecognizedObjectObservation]) {
        DispatchQueue.main.async {
            //use CATransaction to group multiple renders together (not needed right now since only one return per function call)
            CATransaction.begin()
            CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
            self.detectionOverlay.sublayers = nil // remove all the old recognized objects

            //for many observations
            for observation in observations {

                // Select only the label with the highest confidence.
                guard let topLabelObservation = observation.labels.first else {
                    print("Object observation has no labels")
                    continue
                }
                let objectBounds = self.bounds(for: observation)
                let shapeLayer = self.createRoundedRectLayerWithBounds(objectBounds)
                let textLayer = self.createTextSubLayerInBounds(objectBounds,
                                                                identifier: topLabelObservation.identifier,
                                                                confidence: topLabelObservation.confidence)
                shapeLayer.addSublayer(textLayer)
                self.detectionOverlay.addSublayer(shapeLayer)
            }

            self.updateLayerGeometry()
            CATransaction.commit()
        }

    }
    
    
    //for one observation
    func drawBox(observation: VNRecognizedObjectObservation) {
//        guard !coachingOverlay.isActive else { return }

        DispatchQueue.main.async {
            self.detectionOverlay.sublayers = nil // remove all the old recognized objects
            
            guard let classification = observation.labels.first else {
                    print("confidence too low")
                    return
            }
            let objectBounds = self.bounds(for: observation)
            let shapeLayer = self.createRoundedRectLayerWithBounds(objectBounds)
            let textLayer = self.createTextSubLayerInBounds(objectBounds, identifier: classification.identifier, confidence: classification.confidence)
//            print(classification.identifier, classification.confidence)
            
            shapeLayer.addSublayer(textLayer)
            self.detectionOverlay.addSublayer(shapeLayer)
            self.updateLayerGeometry()
            
            
        }
    }  
}
