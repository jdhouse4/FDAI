//
//  FDAIApp.swift
//  FDAI
//
//  Created by James Hillhouse IV on 1/11/23.
//

import SwiftUI

@main
struct FDAIApp: App {
    
    //@StateObject var motionManager          = MotionManager.shared
    @StateObject var launchScreenManager    = LaunchScreenManager.shared
    
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                
                ContentView()
                
                // MARK: Note: A good overview of launch screen options (tag: launchScreen)
                //
                // A good overview of launch screen options is at,
                //
                // https://betterprogramming.pub/launch-screen-with-swiftui-bd2958771f3b
                //
                if !launchScreenManager.loadedFile {
                    
                    SpacecraftLoadingView()
                    
                }

            }
            /*
            .onAppear {
                motionManager.setupDeviceMotion()
            }
            .onDisappear {
                //motionManager.resetReferenceFrame()
                motionManager.stopMotion()
            }
            */
            //.environmentObject(motionManager)
            .environmentObject(launchScreenManager)
            
        }
    }
    
}
