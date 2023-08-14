//
//  MotionManager.swift
//  MissionOrion2
//
//  Created by James Hillhouse IV on 1/6/20.
//  Copyright © 2020 PortableFrontier. All rights reserved.
//

import CoreMotion
import simd



//@MainActor
final class MotionManager: ObservableObject {
    
    //
    // Setup MotionManager singleton shared instance.
    static let shared                   = MotionManager()
    
    private var motionManager: CMMotionManager
    
    var motionQuaternion: simd_quatf    = simd_quatf()
    
    var motionQuaterionAvailable: Bool  = false
    
    var deviceMotionOn: Bool            = false
    
    var referenceFrame: CMAttitude?
    var motionTimer: Timer              = Timer()
    var deviceMotion: CMDeviceMotion?
    var resetFrame: Bool                = false
    
    
    
    
    private init() {
        
        print("\(#function): MotionManager initialized")
        self.motionManager = CMMotionManager()
        
    }
    
    
    
    func setupDeviceMotion() {
        
        print("\(#function): setupDeviceMotion (spinning-up the gyro platform 🍾🥂🥳")
        
        if motionManager.isDeviceMotionAvailable {
            
            self.motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
            self.motionManager.startDeviceMotionUpdates()
            
            
            while motionQuaterionAvailable == false {
                
                if self.motionManager.deviceMotion != nil {
                    
                    if self.motionManager.isDeviceMotionActive {
                        
                        self.deviceMotion = self.motionManager.deviceMotion
                        
                        if motionManager.deviceMotion?.attitude != nil {
                            
                            self.referenceFrame = self.deviceMotion?.attitude
                            print("\n\(#function)self.deviceMotion?.attitude: \(String(describing: self.deviceMotion?.attitude))")
                            
                            self.deviceMotion?.attitude.multiply(byInverseOf: self.referenceFrame!)
                            
                            self.motionQuaterionAvailable = true
                            print("\(#function)motionQuaterionAvailable: \(String(describing: self.motionQuaterionAvailable))\n")
                            
                            
                            self.startDeviceMotion()
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
        //print("\n\(#function)deviceMotion: \(String(describing: self.deviceMotion))\n")
        //print("referenceFrame: \(String(describing: self.referenceFrame))")
        
    }
    
    
    
    func startDeviceMotion() {
        
        print("\n\(#function): startDeviceMotion()\n")
        
        self.deviceMotionOn = true
        //print("\n\(#function): deviceMotionOn: \(self.deviceMotionOn)")
        
        //if motionTimer == nil {
        
        if motionManager.isDeviceMotionAvailable {
            
            
            self.motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
            
            self.motionManager.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler: {
                (data, error) in
                
                if let validData = data {
                    
                    self.motionQuaternion = simd_quatf( ix: -Float((validData.attitude.quaternion.y)),
                                                        iy:  Float((validData.attitude.quaternion.x)),
                                                        iz:  Float((validData.attitude.quaternion.z)),
                                                        r:   Float((validData.attitude.quaternion.w))).normalized
                    
                }
                
            })
            
            /*
             //self.motionManager.startDeviceMotionUpdates()
             
             //if let motionData = deviceMotion {
             
             /*
              self.motionTimer = Timer(fire: Date(), interval: (1.0 / 60.0), repeats: true) { (motionTimer) in
              
              if let motionData = self.deviceMotion {
              
              
              //if self.deviceMotion != nil {
              
              /*
               self.motionQuaternion = simd_quatf( ix: -Float((self.deviceMotion.attitude.quaternion.y)!),
               iy:  Float((self.deviceMotion?.attitude.quaternion.x)!),
               iz:  Float((self.deviceMotion?.attitude.quaternion.z)!),
               r:   Float((self.deviceMotion?.attitude.quaternion.w)!)).normalized
               */
              
              self.motionQuaternion = simd_quatf( ix: -Float((motionData.attitude.quaternion.y)),
              iy:  Float((motionData.attitude.quaternion.x)),
              iz:  Float((motionData.attitude.quaternion.z)),
              r:   Float((motionData.attitude.quaternion.w))).normalized
              
              //print("\(#function) self.motionQuaternion: \(self.motionQuaternion)")
              
              }
              
              }
              */
             
             //}
             /*else {
              
              print("\(#function) There's a problem with the call, self.deviceMotion != nil")
              
              }*/
             
             //}
             
             //
             // Add the timer to the current run loop.
             //
             // RunLoop.current.add(self.motionTimer!, forMode: RunLoop.Mode.common)
             //RunLoop.current.add(self.motionTimer, forMode: RunLoop.Mode.default)
             */
            
        }
        
    }
    
    
    
    func stopDeviceMotion() {
        
        print("\n\(#function) Stop device updates and invalidating the timer.\n")
        
        self.deviceMotionOn = false
        
        motionManager.stopDeviceMotionUpdates()
        
        //self.motionTimer.invalidate()
        
    }
    
    
    
    func resetReferenceFrame() {
        
        //print("MotionManager resetReferenceFrame()")
        //if motionManager.isDeviceMotionAvailable
        if motionManager.isDeviceMotionActive
        {
            
            //print("MotionManager device motion is available.")
            referenceFrame          = motionManager.deviceMotion!.attitude
            resetFrame.toggle()
            //print("resetFrame: \(resetFrame)")
            //print("deviceMotion.attitude: \(referenceFrame?.quaternion)")
            
        }
        
    }
    
    
    
    func updateAttitude() {
        
        deviceMotion = motionManager.deviceMotion
        
        if motionManager.deviceMotion != nil {
            
            deviceMotion?.attitude.multiply(byInverseOf: referenceFrame!)
            
        }
        
    }
    
}
