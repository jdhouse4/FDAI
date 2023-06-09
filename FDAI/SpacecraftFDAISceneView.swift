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
    
    //private var sceneViewRenderContinuously = SceneView.Options.rendersContinuously
    
    
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
        /*.onTapGesture(count: 2, perform: {
            print("I just double tapped")
            //print("\n\(#function) spacecraftFDAISceneRendererDelegate.resetEulerAngles: \(spacecraftFDAISceneRendererDelegate.resetSpacecraftEulerAngles)\n")
            //motionManager.resetReferenceFrame()
            //spacecraftFDAISceneRendererDelegate.resetSpacecraftEulerAngles = true
            //spacecraftFDAISceneRendererDelegate.
            //spacecraftFDAISceneRendererDelegate.resetEulerAngles()
            spacecraftFDAISceneRendererDelegate.stillAlive()
            
        })*/
        .onAppear {
            //print("\n\(#function) SpacecraftSceneView should have just popped-up!\n")
            spacecraftFDAISceneRendererDelegate.spacecraftFDAICurrentCameraNode = spacecraftFDAI.spacecraftFDAICameraNode
            //print("\n\(#function) spacecraftFDAISceneRendererDelegate.resetEulerAngles: \(spacecraftFDAISceneRendererDelegate.resetSpacecraftEulerAngles)\n")
            /*spacecraftCameraState.resetCurrentCameraFOV(of: spacecraftFDAI.spacecraftFDAICurrentCamera.camera!, screenWdith: sizeClass!)*/
            motionManager.resetReferenceFrame()
        }
        
    }
    
}




struct SpacecraftFDAISceneView_Previews: PreviewProvider {
    static var previews: some View {
        SpacecraftFDAISceneView()
    }
}
