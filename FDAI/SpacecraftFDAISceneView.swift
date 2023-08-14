//
//  SpacecraftFDAISceneView.swift
//  MissionOrion2
//
//  Created by James Hillhouse IV on 1/11/23.
//

import SwiftUI
import SceneKit




struct SpacecraftFDAISceneView: View {
    
    @EnvironmentObject var spacecraftFDAI: SpacecraftFDAISceneKitScene
    @EnvironmentObject var spacecraftFDAISceneRendererDelegate: SpacecraftFDAISceneRendererDelegate
    @EnvironmentObject var motionManager: MotionManager
    
    
    
    var body: some View {
        
        SceneView (
            scene: spacecraftFDAI.spacecraftFDAIScene,
            pointOfView: spacecraftFDAI.spacecraftFDAICurrentCamera,
            delegate: spacecraftFDAISceneRendererDelegate
        )
        .frame(width: 300, height: 300)
        .mask {
            RoundedRectangle(cornerRadius: 150.0)
        }
        .onAppear {
            spacecraftFDAISceneRendererDelegate.spacecraftFDAICurrentCameraNode = spacecraftFDAI.spacecraftFDAICameraNode
            motionManager.resetReferenceFrame()
        }
        
    }
    
}




struct SpacecraftFDAISceneView_Previews: PreviewProvider {
    static var previews: some View {
        SpacecraftFDAISceneView()
    }
}
