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

    
    var body: some View {
        VStack {
            SpacecraftFDAISceneView()
            
            
            
        }
        .padding()
        
        .environmentObject(spacecraftFDAIScene)
        .environmentObject(spacecraftFDAISceneRendererDelegate)
        //.environmentObject(motionManager)
    }
    
}




struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
