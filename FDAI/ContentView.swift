//
//  ContentView.swift
//  FDAI
//
//  Created by James Hillhouse IV on 1/11/23.
//

import SwiftUI
import SceneKit




struct ContentView: View {
    
    @StateObject var spacecraftFDAIScene                    = SpacecraftFDAISceneKitScene.shared
    @StateObject var spacecraftFDAISceneRendererDelegate    = SpacecraftFDAISceneRendererDelegate()
    @StateObject var motionManager                          = MotionManager.shared
    
        
    
    var body: some View {
        ZStack {
            
            SpacecraftFDAISceneView()
            
            Image("centerIndicatorFDAI")
                .resizable()
                .scaledToFit()
            
        }
        .onTapGesture(count: 2, perform: {
            
            motionManager.resetReferenceFrame()
            
            spacecraftFDAISceneRendererDelegate.resetSpacecraftEulerAngles = true
            
        })
        .onAppear {
            
            motionManager.setupDeviceMotion()
            
        }
        .onDisappear {
            
            motionManager.stopDeviceMotion()
            
        }
        
        
        
        
        
        .padding()
        
        .environmentObject(spacecraftFDAIScene)
        .environmentObject(spacecraftFDAISceneRendererDelegate)
        .environmentObject(motionManager)
    }
    
}




struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
