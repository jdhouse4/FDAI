//
//  FDAIApp.swift
//  FDAI
//
//  Created by James Hillhouse IV on 1/11/23.
//

import SwiftUI

@main
struct FDAIApp: App {
    
    @StateObject var motionManager                          = MotionManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                
                .onAppear {
                    motionManager.setupDeviceMotion()
                }
                .onDisappear {
                    motionManager.stopMotion()
                }

                .environmentObject(motionManager)
        }
    }
        
}
