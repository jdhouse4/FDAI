//
//  SpacecraftFDAISceneKitScene.swift
//  MissionOrion2
//
//  Created by James Hillhouse IV on 1/11/23.
//

import Foundation
import SceneKit




final class SpacecraftFDAISceneKitScene: SCNScene, ObservableObject {
    
    static let shared   = SpacecraftFDAISceneKitScene()
    
    
    var spacecraftFDAIScene                             = SCNScene(named: "FDAI.scnassets/Orion_CM_FDAI_Assets/Orion_CM_FDAI.scn")!
    var spacecraftFDAISceneNode: SCNNode
    
    var spacecraftFDAINode                              = SCNNode()
    
    @Published var spacecraftFDAICurrentCamera: SCNNode
    @Published var spacecraftFDAICurrentCameraNode: SCNNode
    
    @Published var spacecraftFDAICamera: SCNNode
    @Published var spacecraftFDAICameraNode: SCNNode
    
    /// Spacecraft camera strings (This should be an enum)
    @Published var spacecraftFDAINodeString             = "Orion_CM_FDAI_Node"
    
    /// Orientation
    @Published var spacecraftFDAIQuaternion: simd_quatf = simd_quatf(ix: 0.0, iy: 0.0, iz: 0.0, r: 1.0)
    @Published var deltaFDAIQuaternion: simd_quatf      = simd_quatf(ix: 0.0, iy: 0.0, iz: 0.0, r: 1.0)
    
    let deltaFDAIOrientationAngle: Float                = 0.0078125 * .pi / 180.0 // This results in a 0.5°/s attitude change. 0.015625 = 1°/s
    
    
    
    private override init() {

        print("SpacecraftFDAIScenekitScene private override initialized")
        self.spacecraftFDAISceneNode    = spacecraftFDAIScene.rootNode.childNode(withName: "Orion_CM_FDAI_Scene_Node", recursively: true)!

        self.spacecraftFDAICurrentCamera        = spacecraftFDAIScene.rootNode.childNode(withName: "Orion_CM_FDAI_Camera", recursively: true)!
        self.spacecraftFDAICurrentCameraNode    = spacecraftFDAIScene.rootNode.childNode(withName: "Orion_CM_FDAI_Camera_Node", recursively: true)!

        self.spacecraftFDAINode         = spacecraftFDAIScene.rootNode.childNode(withName: "Orion_CM_FDAI_Node", recursively: true)!
        self.spacecraftFDAICamera       = spacecraftFDAIScene.rootNode.childNode(withName: "Orion_CM_FDAI_Camera", recursively: true)!
        self.spacecraftFDAICameraNode   = spacecraftFDAIScene.rootNode.childNode(withName: "Orion_CM_FDAI_Camera_Node", recursively: true)!
        
        
        super.init()

    }
    
    
    required init?(coder: NSCoder) {
        
        print("SpacecraftFDAIScenekitScene private override initialized")
        self.spacecraftFDAISceneNode    = spacecraftFDAIScene.rootNode.childNode(withName: "Orion_CM_FDAI_Scene_Node", recursively: true)!
        
        self.spacecraftFDAICurrentCamera        = spacecraftFDAIScene.rootNode.childNode(withName: "Orion_CM_FDAI_Camera", recursively: true)!
        self.spacecraftFDAICurrentCameraNode    = spacecraftFDAIScene.rootNode.childNode(withName: "Orion_CM_FDAI_Camera_Node", recursively: true)!

        self.spacecraftFDAINode         = spacecraftFDAIScene.rootNode.childNode(withName: "Orion_CM_FDAI_Node", recursively: true)!
        self.spacecraftFDAICamera       = spacecraftFDAIScene.rootNode.childNode(withName: "Orion_CM_FDAI_Camera", recursively: true)!
        self.spacecraftFDAICameraNode   = spacecraftFDAIScene.rootNode.childNode(withName: "Orion_CM_FDAI_Camera_Node", recursively: false)!

        
        super.init()
        
    }

}
