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
    
    var referenceFrame: CMAttitude?
    var motionTimer: Timer?
    var deviceMotion: CMDeviceMotion?
    var resetFrame: Bool = false




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

                        //if motionManager.isGyroAvailable {
                            
                            if motionManager.deviceMotion?.attitude != nil {

                                self.referenceFrame = self.deviceMotion?.attitude

                                self.deviceMotion?.attitude.multiply(byInverseOf: self.referenceFrame!)

                                self.motionQuaterionAvailable = true
                            
                            }
                        //}
                    }
                }
            }
        }
        //print("deviceMotion: \(String(describing: self.deviceMotion))")
        //print("referenceFrame: \(String(describing: self.referenceFrame))")

        self.startDeviceMotion()
    }



    func startDeviceMotion() {
        print("\(#function): startDeviceMotion()")
        self.motionTimer = Timer(fire: Date(), interval: (1.0 / 60.0), repeats: true) { (motionTimer) in
                                    if self.deviceMotion != nil {
                                        self.motionQuaternion = simd_quatf( ix: -Float((self.deviceMotion?.attitude.quaternion.y)!),
                                                                            iy:  Float((self.deviceMotion?.attitude.quaternion.x)!),
                                                                            iz:  Float((self.deviceMotion?.attitude.quaternion.z)!),
                                                                            r:   Float(((self.deviceMotion!.attitude.quaternion.w)))).normalized

                                        //self.updateAttitude()
                                    }
        } //)

        //print("motionTimer set.")

        // Add the timer to the current run loop.
        RunLoop.current.add(self.motionTimer!, forMode: RunLoop.Mode.common)

    }



    func stopMotion() {
        motionManager.stopDeviceMotionUpdates()
    }



    func resetReferenceFrame() {
        print("\(#function) MotionManager resetReferenceFrame()")
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
