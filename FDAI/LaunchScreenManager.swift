//
//  LaunchScreenManager.swift
//  MissionOrion2
//
//  Created by James Hillhouse IV on 2/13/23.
//

import Foundation




@MainActor
final class LaunchScreenManager: ObservableObject {
    
    static let shared                           = LaunchScreenManager()
    
    @Published var loadingFile: Bool            = true
    @Published var animateLoadViewFade: Bool    = false
    @Published var loadedFile: Bool             = false
    
    
    
    func doneLoadingFile() {
        
        self.loadingFile.toggle()
        print("\(#function) loadingFile.toggle() at \(Date())")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            
            self.animateLoadViewFade.toggle()
            print("\(#function) animateLoadViewFade.toggle() at \(Date())")
            
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                
                self.loadedFile.toggle()
                print("\(#function) loadedFile.toggle() at \(Date())")

            }
            
        }
    }
}
