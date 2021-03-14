//
//  Box.swift
//  RecognEyes
//
//  Created by Matthew Chea on 3/7/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import SceneKit
import ARKit

class Box : SCNNode {
    static let name = String(describing: Box.self)
    
    let bubbleDepth: CGFloat = 0.01
    
    var objectName = ""
    var nodeName: String {
        return objectName
    }
    
    init(text: String, raycastResult: ARRaycastResult) {
        super.init()
        self.objectName = text
        //text
        let bubble = SCNText(string: text, extrusionDepth: CGFloat(bubbleDepth))
        let font = UIFont(name: "Futura", size: 0.05)
        bubble.font = font
        bubble.alignmentMode = CATextLayerAlignmentMode.center.rawValue
        bubble.firstMaterial?.diffuse.contents = UIColor.orange
        bubble.firstMaterial?.specular.contents = UIColor.white
        bubble.firstMaterial?.isDoubleSided = true
        bubble.chamferRadius = CGFloat(bubbleDepth)
        let (minBound, maxBound) = bubble.boundingBox
        let bubbleNode = SCNNode(geometry: bubble)
        bubbleNode.pivot = SCNMatrix4MakeTranslation((maxBound.x - minBound.x) / 2,
                                                     minBound.y,
                                                     Float(bubbleDepth) / 2)
        bubbleNode.scale = SCNVector3Make(0.2, 0.2, 0.2)


        //box
        let box = SCNBox(width: 0.5, height: 1, length: 0.02, chamferRadius: 0.02)
        
        let boxNode = SCNNode(geometry: box)
        
        positionNode(node: boxNode, at: raycastResult)
        positionNode(node: bubbleNode, at: raycastResult)

        boxNode.name = Self.name
        boxNode.geometry?.materials.first?.transparency = 0.6

        addChildNode(bubbleNode)
        addChildNode(boxNode)
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        bubbleNode.constraints = [billboardConstraint]
        
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func positionNode(node: SCNNode, at rayCastResult: ARRaycastResult) {
            //1
            node.transform = SCNMatrix4(rayCastResult.anchor!.transform)
            //2
            node.eulerAngles = SCNVector3Make(node.eulerAngles.x + (Float.pi / 2), node.eulerAngles.y, node.eulerAngles.z)
            //3
            let position = SCNVector3Make(rayCastResult.worldTransform.columns.3.x + node.geometry!.boundingBox.min.z, rayCastResult.worldTransform.columns.3.y, rayCastResult.worldTransform.columns.3.z)
            node.position = position
        }
}
