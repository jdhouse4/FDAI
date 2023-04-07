//
//  SpacecraftFDAISceneRendererDelegate.swift
//  MissionOrion2
//
//  Created by James Hillhouse IV on 10/17/20.
//
import SceneKit




/**
 This is the delegate class for SpacecraftSceneKitScene model.
 
 It's purpose is to do some of the grunt work for an SCNScene. One important role is the function,
 
 `renderer(_:updateAtTime:)`
 
 that allows for changes of the Scene to be rendereed on a reglar time interval. For our purposes, this will allow for the physics-based motion
 say due to firing of the spacecraft's RCS, to be displayed. Another would be to update the position after Runge-Kutta45 integration the state vector.
 */

class SpacecraftFDAISceneRendererDelegate: NSObject, SCNSceneRendererDelegate, ObservableObject {
    
    // This no longer works because,
    //
    // "Main actor-isolated static property 'shared' can not be referenced from a non-isolated context"
    //
    // So, go direct! Use, SpacecraftCameraState.shared.(some @Published property of the singleton).
    //
    // And the same with SpacecraftState.shared.
    //
    var spacecraftFDIAScene: SCNScene                   = SpacecraftFDAISceneKitScene.shared
    
    var spacecraftFDAISceneNode: SCNNode                = SCNNode()
    var spacecraftSceneNodeString: String               = "Orion_CSM_FDAI_Scene_Node"
    
    @Published var spacecraftFDAINode: SCNNode          = SCNNode()
    @Published var spacecraftFDAINodeString: String     = "Orion_CSM_FDAI_Node"
    
    @Published var sceneIsRendering: Bool               = false
    
    //
    // Orientation properties
    //
    let firstRotation    = simd_quatf(angle: -(75.0 * .pi / 180.0),
                                      axis: simd_normalize(simd_float3(x: 0, y: 1, z: 0))).normalized
    
    let secondRotation  = simd_quatf(angle: .pi/2,
                                     axis: simd_normalize(simd_float3(x: 0, y: 0, z: 1))).normalized
    
    let spacecraftFDAINode.simdOrientation = simd_mul(simd_quatf(angle: -(75.0 * .pi / 180.0),
                                                axis: simd_normalize(simd_float3(x: 0, y: 1, z: 0))).normalized,
                                             simd_quatf(angle: .pi/2,
                                                axis: simd_normalize(simd_float3(x: 0, y: 0, z: 1))).normalized).normalized
    
    @Published var spacecraftDeltaQuaternion: simd_quatf    = simd_quatf()
    @Published var spacecraftOrientation: simd_quatf        = simd_quatf()
    @Published var spacecraftEulerAngles: SIMD3<Float>      = simd_float3()
    var spacecraftPreviousEulerAngles: SIMD3<Float>         = simd_float3()
    var spacecraftCurrentEulerAngles: SIMD3<Float>          = simd_float3()
    
    
    // MARK: Orientation and Their Rate Change Parameters
    var deltaRoll : Float                                   = 0.0
    var deltaPitch: Float                                   = 0.0
    var deltaYaw  : Float                                   = 0.0
    var rollRate  : Float                                   = 0.0
    var pitchRate : Float                                   = 0.0
    var yawRate   : Float                                   = 0.0
    @Published var deltaRollRate:Float                      = 0.0
    @Published var deltaPitchRate: Float                    = 0.0
    @Published var deltaYawRate: Float                      = 0.0
    
    
    var motionManager                                       = MotionManager.shared
    
    //
    // For switching cameras in the scene.
    //
    @Published var spacecraftFDAICurrentCamera: String          = SpacecraftFDAICamera.spacecraftFDAICamera.rawValue
    @Published var spacecraftFDAICurrentCameraNode: SCNNode     = SCNNode()
    
    
    var changeCamera: Bool                          = false
        
    var showsStatistics: Bool                       = false
    
    // MARK: Counting Yaw Gimbal Lock
    var gimbalLockCount: Int = 0


    
    // Time, oh time...
    var _previousUpdateTime: TimeInterval           = 0.0
    var _previousUpdateTimeAnimation: TimeInterval  = 0.0
    var _previousUpdateTimeRenderer: TimeInterval   = 0.0
    var _deltaTime: TimeInterval                    = 0.0
    var _deltaTimeAnimation: TimeInterval           = 0.0
    var _deltaTimeRenderer: TimeInterval            = 0.0
    var inertialElapsedTime: TimeInterval           = 0.0
    
    
    //
    // MARK: Keep track of frame rate
    var renderStep: UInt                        = 0
    var previousRenderTime: TimeInterval        = 0.0
    var deltaRenderTime: TimeInterval           = 0.0
    
    
    //
    // MARK: Orbit Calculation Properties
    //
    var deltaT: TimeInterval                    = 0.0
    var updatedTime: TimeInterval               = 0.0

    //var renderCountdownInt: Int                 = 0
    var tempInitStateArray: [Float]             = []

    

    
    
    override init() {
        print("\n\(#function) SpacecraftFDAISceneRendererDelegate override initialized\n")
        
        //
        // This call has been moved to the App protocol, SwiftUISceneKitCoreMotionDemoApp.swift.
        //
        //self.motionManager.setupDeviceMotion()
        
        //self.sceneQuaternion    = self.motionManager.motionQuaternion
        
        //self.spacecraftFDIAScene      = SpacecraftSceneKitScene.shared
        self.spacecraftFDAISceneNode    = SpacecraftFDAISceneKitScene.shared.spacecraftFDAISceneNode
        
        self.spacecraftFDAINode       = SpacecraftFDAISceneKitScene.shared.spacecraftFDAINode
        
        super.init()
        
        ///
        /// Just making sure here that the spacecraftScene and spacecraftNode are what I want them to be.
        ///
        print("SpacecraftFDAISceneRendererDelegate \(#function) spacecraftFDIAScene: \(spacecraftFDIAScene)")
        print("SpacecraftFDAISceneRendererDelegate \(#function) spacecraftFDAISceneNode: \(String(describing: spacecraftFDAISceneNode.name))")
        print("SpacecraftFDAISceneRendererDelegate \(#function) spacecraftFDAINode: \(String(describing: spacecraftFDAINode.name))")
        
    }

    
    
    @MainActor
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        renderer.showsStatistics = showsStatistics
        
        //print("\(#function) time: \(time)")
        
        /*
        renderStep += 1
        
        
        // This is to ensure that the time is initialized properly for the simulator.
        if _previousUpdateTime == 0.0
        {
            
            _previousUpdateTime     = time
            //print("\(#function) setting _previousUpdateTime to time: \(time)\n")
            
        }
        
        _deltaTime  = time - _previousUpdateTime
        //print("\(#function) _deltaTime: \(_deltaTime)")
         
        
        //
        // MARK: Set previousRenderTime = 0 on first pass
        //
        if previousRenderTime == 0.0 {
            
            previousRenderTime  = time
            
        }
        
        deltaRenderTime = time - previousRenderTime
        //print("\(#function) deltaRenderTime: \(deltaRenderTime)")
        
        if deltaRenderTime > 1.0 {
            
            //print("\(#function) frame rate: \(renderStep)")
            previousRenderTime  = time
            renderStep          = 0
        }
         */

        
        ///
        // MARK: Update the attitude.quaternion from device manager
        ///
        motionManager.updateAttitude()
        
        
        
        //
        // Determine whether to let the motion manager update the camera orientation based on whether
        // the user is currently using the gyro features or not.
        //
        if spacecraftFDAICurrentCamera == SpacecraftFDAICamera.spacecraftFDAICamera.rawValue {
            
            //print("\(#function) updating spacecraftFDAICurrentCameraNode: \(spacecraftFDAICurrentCameraNode.name)")
            //self.updateFDAICameraOrientation(of: spacecraftFDAICurrentCameraNode)
            self.updateFDAICameraOrientation(of: spacecraftFDAINode)

        }

    }
    
    
    /*
    @MainActor
    func renderer(_ renderer: SCNSceneRenderer, didApplyAnimationsAtTime time: TimeInterval) {
        
        
        // This is to ensure that the time is initialized properly for the simulator.
        if _previousUpdateTimeAnimation == 0.0 {
            
            _previousUpdateTimeAnimation     = time
            //print("\(#function) setting _previousUpdateTime to time: \(time)\n")
            
        }
        
        _deltaTimeAnimation  = time - _previousUpdateTimeAnimation
        //print("\(#function) _deltaTimeAnimation: \(_deltaTimeAnimation)")
        

        // MARK: Calculate attitude changes and rates, and loading of assets.
        if _deltaTimeAnimation > 0.2 {
            //
            // Calculating euler angles and roll rates
            //
            //print("\n\(#function) Time to calculate eulers and roll rates.")
            print("\n\(#function) _deltaTimeAnimation: \(_deltaTimeAnimation)")
            //print("\(#function) _deltaTimeAnimation - 0.2: \(Float(_deltaTimeAnimation - 0.20))")
            
            
            // MARK: _deltaTime is reset to zero.
            _previousUpdateTimeAnimation         = time
            //print("\(#function) _previousTime: \(_previousUpdateTime)")
            
            
            //
            // MARK: Roll, Pitch, and Yaw Angle Rate of Change
            // TODO: Make Roll, Pitch, and Yaw Angle Rates of Change a function!
            
            
            // MARK: Previous Orientation
            ///
            /// This calculates the delta-roll euler angle by taking the difference of the current and previous roll angles
            /// and dividing by the elapsed time. This is not meant as final code and will be refined later.
            ///
            self.spacecraftPreviousEulerAngles        = self.spacecraftCurrentEulerAngles
            
            // To get positive or negative angles on roll.
            let spacecraftPreviousRollAngle: Float  = radians2Degrees(self.spacecraftPreviousEulerAngles.x) > 0.0 ? radians2Degrees(self.spacecraftPreviousEulerAngles.x) : -radians2Degrees(self.spacecraftPreviousEulerAngles.x)
            
            // To get positive or negative angle on pitch
            let spacecraftPreviousPitchAngle: Float = radians2Degrees(self.spacecraftPreviousEulerAngles.z) > 0.0 ? radians2Degrees(self.spacecraftPreviousEulerAngles.z) : -radians2Degrees(spacecraftPreviousEulerAngles.z)
            
            // To get positive or negative angle on yaw
            let spacecraftPreviousYawAngle: Float = radians2Degrees(self.spacecraftPreviousEulerAngles.y) > 0.0 ? radians2Degrees(self.spacecraftPreviousEulerAngles.y) : -radians2Degrees(spacecraftPreviousEulerAngles.y)
            
            let spacecraftSceneNodeYawAngle: Float = spacecraftFDAISceneNode.simdEulerAngles.y
            print("\(#function) spacecraftSceneNodeYawAngle: \(spacecraftSceneNodeYawAngle) radians")
            print("\(#function) spacecraftPreviousYawAngle: \(self.spacecraftPreviousEulerAngles.y) radians")

            
            
            // MARK: Current Orientation Updated from Previous and Delta Orientation
            self.spacecraftCurrentEulerAngles = self.spacecraftFDAISceneNode.simdEulerAngles
            
            let spacecraftCurrentRollAngle: Float   = radians2Degrees(self.spacecraftCurrentEulerAngles.x) > 0.0 ? radians2Degrees(self.spacecraftCurrentEulerAngles.x) : -radians2Degrees(self.spacecraftCurrentEulerAngles.x)
            
            let spacecraftCurrentPitchAngle: Float  = radians2Degrees(self.spacecraftCurrentEulerAngles.z) > 0.0 ? radians2Degrees(self.spacecraftCurrentEulerAngles.z) : -radians2Degrees(spacecraftCurrentEulerAngles.z)
            
            // Yaw is a special case since it is an ASin function. Lot's of checks here to make sure things aren't getting improperly calculated.
            
            let spacecraftCurrentYawAngle: Float  = radians2Degrees(self.spacecraftCurrentEulerAngles.y) > 0.0 ? radians2Degrees(self.spacecraftCurrentEulerAngles.y) : -radians2Degrees(spacecraftCurrentEulerAngles.y)
            //print("\(#function) spacecraftCurrentYawAngle: \(self.spacecraftCurrentEulerAngles.y) radians")
            
            if self.spacecraftCurrentEulerAngles.y == (-.pi / 2.0) && self.spacecraftCurrentEulerAngles.y < 0.0 {
                
                //print("\n\(#function) spacecraftCurrentYawAngle is between -90° and 0°")
                //print("\n\(#function) spacecraftCurrentYawAngle: \(self.spacecraftCurrentEulerAngles.y)")
                
            } else if self.spacecraftCurrentEulerAngles.y > 0.0 && self.spacecraftCurrentEulerAngles.y < (.pi / 2.0) {
                
                //print("\n\(#function) spacecraftCurrentYawAngle is between 0° and 90°")
                //print("\n\(#function) spacecraftCurrentYawAngle: \(self.spacecraftCurrentEulerAngles.y)")
                
            } else if self.spacecraftCurrentEulerAngles.y == 0.0 {
                
                //print("\n\(#function) spacecraftCurrentYawAngle is 0°")
                //print("\n\(#function) spacecraftCurrentYawAngle: \(self.spacecraftCurrentEulerAngles.y)")
                
            } else if self.spacecraftCurrentEulerAngles.y == (-.pi / 2.0) {
                
                //print("\n\(#function) spacecraftCurrentYawAngle is -90°")
                //print("\n\(#function) spacecraftCurrentYawAngle: \(self.spacecraftCurrentEulerAngles.y)")
                
            } else {
                
                //print("\n\(#function) spacecraftCurrentYawAngle is 90°")
                //print("\n\(#function) spacecraftCurrentYawAngle: \(self.spacecraftCurrentEulerAngles.y)")
                
            }
            
            
            deltaRoll   = abs(spacecraftCurrentRollAngle - spacecraftPreviousRollAngle)
            deltaPitch  = abs(spacecraftCurrentPitchAngle - spacecraftPreviousPitchAngle)
            deltaYaw    = abs(spacecraftCurrentYawAngle - spacecraftPreviousYawAngle)
            //print("\(#function) deltaYaw: \(deltaYaw)°")
            
            rollRate    = deltaRoll / Float(_deltaTimeAnimation)
            pitchRate   = deltaPitch / Float(_deltaTimeAnimation)
            yawRate     = deltaYaw / Float(_deltaTimeAnimation)/*Float(_deltaTimeAnimation - (_deltaTimeAnimation - 0.20))*/
            //print("\(#function) yawRate: \(yawRate)°/s")
            
            
            
            if spacecraftSceneNodeYawAngle > -1.571 && spacecraftSceneNodeYawAngle < -1.57 {
                
                gimbalLockCount += 1
                print("\(#function) gimgalLockCount: \(gimbalLockCount)")
                //print("\(#function) SpacecraftCurrentYawAngle: \(spacecraftCurrentYawAngle)")
                //print("\(#function) Updated spacecraftSceneNodeYawAngle: \(Float(spacecraftDeltaQuaternion.angle))")
                
            } else {
                
                gimbalLockCount = 0
            }
            
            
            // MARK: Trying to fix the yaw angle bug
            spacecraftYawAngleDelta = Float(SpacecraftState.shared.yawImpulseCounter) * 0.25
            print("\(#function) spacecraftYawAngleDelta: \(spacecraftYawAngleDelta)°/s")
            print("\(#function) SpacecraftState.shared.yawImpulseCounter = \(SpacecraftState.shared.yawImpulseCounter)")
            print("\(#function) spacecraftSceneNode.simdEulerAngles.y = \(spacecraftFDAISceneNode.simdEulerAngles.y)")
            print("\(#function) spacecraftPreviousYawAngle: \(spacecraftPreviousYawAngle)°")
            print("\(#function) spacecraftCurrentYawAngle: \(spacecraftCurrentYawAngle)°")
            print("\(#function) spacecraftYawAngleDelta: \(spacecraftYawAngleDelta)°")

            
            previouslyUpdatedSpacecraftYawAngle = updatedSpacecraftYawAngle

            
            if /*SpacecraftState.shared.yawImpulseCounter >= 0 &&*/ spacecraftSceneNodeYawAngle >= 0.0 && spacecraftSceneNodeYawAngle <= 1.57 && spacecraftPreviousYawAngle <= spacecraftCurrentYawAngle {
                
                // Between 0° and ~86.4°
                
                updatedSpacecraftYawAngle = radians2Degrees(self.spacecraftFDAISceneNode.simdEulerAngles.y)
                print("\(#function) In first quadrant, updatedSpacecraftYawAngle: \(updatedSpacecraftYawAngle)°")

            } else if /*SpacecraftState.shared.yawImpulseCounter >= 0 &&*/ spacecraftSceneNodeYawAngle > -1.571 && spacecraftSceneNodeYawAngle < -1.57 {
                
                // Area between ~86.4° and ~94.6°
                
                updatedSpacecraftYawAngle += spacecraftYawAngleDelta * Float(_deltaTimeAnimation)
                print("\(#function) In between first and second quadrants area of discontinuity, updatedSpacecraftYawAngle: \(updatedSpacecraftYawAngle)°")
                
            } else if /*SpacecraftState.shared.yawImpulseCounter >= 0 &&*/ spacecraftSceneNodeYawAngle > 0.0 && spacecraftSceneNodeYawAngle < 1.57 && spacecraftPreviousYawAngle >= spacecraftCurrentYawAngle {
                
                // Between 90° and 180°
                
                updatedSpacecraftYawAngle = radians2Degrees(.pi - Float(self.spacecraftFDAISceneNode.simdEulerAngles.y))
                print("\(#function) In second quadrant, updatedSpacecraftYawAngle: \(updatedSpacecraftYawAngle)°")

            } else if /*SpacecraftState.shared.yawImpulseCounter >= 0 &&*/ spacecraftSceneNodeYawAngle < 0.0 && spacecraftSceneNodeYawAngle > -1.57 && spacecraftPreviousYawAngle <= spacecraftCurrentYawAngle  {
                
                // Between 180° and 270°
                
                updatedSpacecraftYawAngle = radians2Degrees(.pi - Float(self.spacecraftFDAISceneNode.simdEulerAngles.y))
                print("\(#function) In third quadrant, updatedSpacecraftYawAngle: \(updatedSpacecraftYawAngle)°")

            } else if /*SpacecraftState.shared.yawImpulseCounter >= 0 &&*/ spacecraftSceneNodeYawAngle > 1.57 && spacecraftSceneNodeYawAngle < 1.571 {
                  
                updatedSpacecraftYawAngle += spacecraftYawAngleDelta * Float(_deltaTimeAnimation)
                //updatedSpacecraftYawAngle = radians2Degrees(.pi + Float(self.spacecraftSceneNode.simdEulerAngles.y))
                print("\(#function) In between third and fourth quadrants area of discontinuity, updatedSpacecraftYawAngle: \(updatedSpacecraftYawAngle)°")

            } else if /*SpacecraftState.shared.yawImpulseCounter >= 0 &&*/ spacecraftSceneNodeYawAngle < 0.0 && spacecraftSceneNodeYawAngle > -1.57 && spacecraftPreviousYawAngle >= spacecraftCurrentYawAngle {
                
                // Between 90° and 180°
                
                updatedSpacecraftYawAngle = radians2Degrees((2.0 * .pi) + Float(self.spacecraftFDAISceneNode.simdEulerAngles.y))
                print("\(#function) In fourth quadrant, updatedSpacecraftYawAngle: \(updatedSpacecraftYawAngle)°")
                
            }
            
            /*
            if SpacecraftState.shared.yawImpulseCounter < 1 {
                
                spacecraftYawAngle += spacecraftYawAngleDelta * Float(_deltaTimeAnimation)
                print("\(#function) Spacecraft Scene Node Yaw Angle: \(spacecraftYawAngle)°")
                
            }
             */
            
            print("\(#function) previouslyUpdatedSpacecraftYawAngle: \(previouslyUpdatedSpacecraftYawAngle)°")
            print("\(#function) updatedSpacecraftYawAngle: \(updatedSpacecraftYawAngle)°")

            
            // TODO: I need to bracket yaw changes between 86.3° since at ~86.32° or ~86.37° I go into gimbal lock.
            //
            // How to do this? There are two paths. One technically right, the other that could be right, but I need to check.
            //
            // 1. I'm rotating at 0.25°/s. So, when the value for spacecraftCurrentEulerAngle.y gets to 86.3, take-over calculation
            //    of yaw angle and manually add 0.25° * _deltaTimeAnimation, which is the value divided into 0.25.
            //    Since I know I'm in a positive rotation, I can also take this opportunity to fix the display bug that shows my
            //    yaw angle decreasing past 90°.
            //    And, later, this will serve as an opportunity to toggle a flag that shows the user I'm in a positve or
            //    negative rotation. Yay!!!
            //
            // 2. Other way, manually calculate the ∆° based on knowledge that I'm at 0° starting-out. THIS IS DANGEROUS.
            
            
            ///
            /// This main actor task gets assignments for Published vars for:
            ///
            ///  1. spacecraftEularAngles
            ///  2. deltaRollRate
            ///
            /// off of whatever thread SCNSceneRenderDelegate is rendering and onto the Main thread, as needed
            /// for assigning published vars.
            ///
            // MARK: MainActor for indicating loading of assets, orientation change, and rate of change.
            Task {
                
                await MainActor.run {
                    
                    //print("Calling MainActor.run @ time: \(time)")
                    
                     self.spacecraftEulerAngles = self.spacecraftFDAISceneNode.simdEulerAngles
                     //print("\(#function) self.spacecraftEulerAngles: \(self.spacecraftEulerAngles)")
                     
                     self.deltaRollRate         = rollRate
                     //print("\(#function) self.deltaRollRate: \(self.deltaRollRate)")
                     
                     self.deltaPitchRate        = pitchRate
                     //print("\(#function) self.deltaPitchRate: \(self.deltaPitchRate)")
                     
                     self.deltaYawRate          = yawRate
                     //print("\(#function) self.deltaYawRate: \(self.deltaYawRate) for yawRate: \(yawRate)")
                    
                }
                
            }

        }
        
    }
    */
    
    /*
    func renderer(_ renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: TimeInterval) {
        
        //
        // MARK: Orbit Integration: Integrate the state array [positionX, positionY, positionZ, velocityX, velocityY, velocityZ] to its new state.
        //
        if updatedTime == 0.0 {
            
            updatedTime = time
            
        }
        
        deltaT = time - updatedTime
        //print("\(#function) deltaT: \(deltaT)")
        
        
        if deltaT > 0.1 {
            
            updatedTime = time
            //deltaT      = updatedTime - _deltaTime
            //print("\(#function) deltaT: \(deltaT)")
            
            //}
            
            //print("\(#function) deltaT: \(deltaT)")
            updatedLunarOrbitStateArray     = rungeKutta45(initialLunarOrbitStateArray,
                                                           deltaT: Float(deltaT) * deltaTLunarOrbitScalingFactor,
                                                           with: µMoon) // Now deltaT is 60, so with fps = 60, each hour.
            
            spacecraftFDAISceneNode.position    = SCNVector3(x: updatedLunarOrbitStateArray[0] / scalingFactorLunarOrbit,
                                                         y: updatedLunarOrbitStateArray[1] / scalingFactorLunarOrbit,
                                                         z: updatedLunarOrbitStateArray[2] / scalingFactorLunarOrbit)
            
            
            
            // Set the itial state array to the updated state array in preparation for the next loop.
            initialLunarOrbitStateArray     = updatedLunarOrbitStateArray
            
        }
        
    }
    */
    
    /*
    @MainActor
    func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        
        // This is to ensure that the time is initialized properly for the simulator.
        if _previousUpdateTimeRenderer == 0.0
        {
            
            _previousUpdateTimeRenderer     = time
            //print("\(#function) setting _previousUpdateTime to time: \(time)\n")
            
        }
        
        _deltaTimeRenderer  = time - _previousUpdateTimeRenderer
        //print("\(#function) _deltaTime: \(_deltaTime)")
        
        
        
        // MARK: Calculate attitude changes and rates, and loading of assets.
        if _deltaTimeRenderer > 0.2 {
            //
            // Calculating euler angles and roll rates
            //
            //print("\n\(#function) Time to display calculated eulers and roll rates at: \(_deltaTimeRenderer).")
            //print("\(#function) _deltaTime: \(_deltaTime)")
            
            
            // MARK: _deltaTime is reset to zero.
            _previousUpdateTimeRenderer         = time
            //print("\(#function) _previousTime: \(_previousUpdateTime)")
            
            
            //
            // MARK: Roll, Pitch, and Yaw Angle Rate of Change
            // TODO: Make Roll, Pitch, and Yaw Angle Rates of Change a function!
            
            ///
            /// This calculates the delta-roll euler angle by taking the difference of the current and previous roll angles
            /// and dividing by the elapsed time. This is not meant as final code and will be refined later.
            ///
            
            
            ///
            /// This main actor task gets assignments for Published vars for:
            ///
            ///  1. spacecraftEularAngles
            ///  2. deltaRollRate
            ///
            /// off of whatever thread SCNSceneRenderDelegate is rendering and onto the Main thread, as needed
            /// for assigning published vars.
            ///
            // MARK: MainActor for indicating loading of assets, orientation change, and rate of change.
            Task {
                
                await MainActor.run {
                    
                    //print("Calling MainActor.run @ time: \(time)")
                    /*
                     self.spacecraftEulerAngles    = self.spacecraftFDAISceneNode.simdEulerAngles
                     //print("\(#function) self.spacecraftEulerAngles: \(self.spacecraftEulerAngles)")
                     
                     self.deltaRollRate          = rollRate
                     //print("\(#function) self.deltaRollRate: \(self.deltaRollRate)")
                     
                     self.deltaPitchRate         = pitchRate
                     //print("\(#function) self.deltaPitchRate: \(self.deltaPitchRate)")
                     
                     self.deltaYawRate           = yawRate
                     print("\(#function) self.deltaYawRate: \(self.deltaYawRate)")
                     */
                    
                    //
                    // This is for the splash screen that also has a ProgressView to show files are loading
                    //
                    //print("\(#function) running...running...running...")
                    if LaunchScreenManager.shared.loadingFile {
                        
                        LaunchScreenManager.shared.doneLoadingFile()
                        print("\(#function) LaunchScreenManager.shared.doneLoadingFile")
                        
                    }
                    
                }
                
            }
            
        }
        
        
        /*
         if SpacecraftCameraState.shared.chase360CameraEulersInertiallyDampen == true {
         
         inertialCameraRotation()
         
         } else {
         
         inertialElapsedTime = 0.0
         
         }
         
         
         
         ///
         // MARK: Update the attitude.quaternion from device manager
         ///
         motionManager.updateAttitude()
         
         
         
         // MARK: Update the orientation due to RCS activity
         self.updateSpacecraftFDAISceneNodeOrientation()
         */
        
    }
    */
    
    
    func setCurrentCameraName(name: String) {
        spacecraftFDAICurrentCamera = name
    }
    
    
    
    func setCurrentCameraNode(node: SCNNode) {
        spacecraftFDAICurrentCameraNode = node
        motionManager.resetReferenceFrame()
    }
    
    
    func updateFDAICameraOrientation(of node: SCNNode) -> Void {
        /*let firstRotation    = simd_quatf(angle: -(75.0 * .pi / 180.0),
                                             axis: simd_normalize(simd_float3(x: 0, y: 1, z: 0))).normalized
        
        let secondRotation  = simd_quatf(angle: .pi/2,
                                         axis: simd_normalize(simd_float3(x: 0, y: 0, z: 1))).normalized
        
        let correctedRotation = simd_mul(secondRotation, firstRotation).normalized

         
        // Change Orientation with Device Motion
        let motionSimdQuatf     = simd_quatf(ix: Float(motionManager.deviceMotion!.attitude.quaternion.x),
                                             iy: -Float(motionManager.deviceMotion!.attitude.quaternion.y),
                                             iz: -Float(motionManager.deviceMotion!.attitude.quaternion.z),
                                             r:   Float(motionManager.deviceMotion!.attitude.quaternion.w)).normalized
        
        node.simdOrientation   = simd_mul(motionSimdQuatf, correctedRotation).normalized
         */
        
        node.simdOrientation   = simd_quatf(ix: -Float(motionManager.deviceMotion!.attitude.quaternion.x),
                                            iy: -Float(motionManager.deviceMotion!.attitude.quaternion.y),
                                            iz:  Float(motionManager.deviceMotion!.attitude.quaternion.z),
                                            r:   Float(motionManager.deviceMotion!.attitude.quaternion.w)).normalized
        

    }
    
    
    /*
    // MARK: Updates the spacecraft's orientation.
    func updateSpacecraftFDAISceneNodeOrientation() -> Void {
        
        // MARK: This is where the spacecraft's orientation changes are realized
        self.spacecraftFDAISceneNode.simdOrientation   = simd_mul(spacecraftFDAISceneNode.simdOrientation, spacecraftDeltaQuaternion).normalized
        
    }
     */
    
    
    
    func radians2Degrees(_ number: Float) -> Float {
        
        return number * 180.0 / .pi
        
    }
    
    
    /*
    func inertialCameraRotation() {
    
    Task {
        
        
            await MainActor.run {
                
                
            inertialElapsedTime += 1.0/60.0
            

            if abs(SpacecraftCameraState.shared.cameraInertialEulerX) > 0.01 || abs(SpacecraftCameraState.shared.cameraInertialEulerY) > 0.01 {
                
                //
                // Dampen Chase360Camera's euler angle change.
                //
                
                var updatedCameraInertialEulerX = SpacecraftCameraState.shared.cameraInertialEulerX
                var updatedCameraInertialEulerY = SpacecraftCameraState.shared.cameraInertialEulerY
                print("\(#function) Dampening updatedCameraInertialEulerX from cameraInertialEulerX = \(updatedCameraInertialEulerX)")
                
                if updatedCameraInertialEulerX > 0.0 {
                    //
                    // For updatedCameraInertialEulerX, swiping left is positive.
                    //
                    print("\(#function) updatedCameraInertialEulerX is > 0.0")
                    
                    updatedCameraInertialEulerX     = updatedCameraInertialEulerX - updatedCameraInertialEulerX * 0.05
                    //print("\(#function) decreasing updatedCameraInertialEulerX \(updatedCameraInertialEulerX) by \(updatedCameraInertialEulerX - updatedCameraInertialEulerX * 0.05)")
                    
                    if updatedCameraInertialEulerX > 0.0 && updatedCameraInertialEulerX < 0.025 {
                        
                        updatedCameraInertialEulerX     = updatedCameraInertialEulerX - 0.009
                        //print("\(#function) decreasing updatedCameraInertialEulerX \(updatedCameraInertialEulerX) by \(updatedCameraInertialEulerX - 0.009)")
                        
                    }
                    
                } else {
                    //
                    // For updatedCameraInertialEulerX, swiping right is negative.
                    //
                    //print("\(#function) updatedCameraInertialEulerX is < 0.0")
                    
                    // Never forget that to subtract a negative from a negative, in this case the scaler needs to be...NEGATIVE!
                    updatedCameraInertialEulerX     = updatedCameraInertialEulerX + updatedCameraInertialEulerX * -0.05
                    //print("\(#function) decreasing updatedCameraInertialEulerX \(updatedCameraInertialEulerX) by \(updatedCameraInertialEulerX + updatedCameraInertialEulerX * 0.05)")
                    
                    if updatedCameraInertialEulerX > -0.025 && updatedCameraInertialEulerX < 0.0 {
                        
                        updatedCameraInertialEulerX     = updatedCameraInertialEulerX + 0.009
                        //print("\(#function) decreasing updatedCameraInertialEulerX \(updatedCameraInertialEulerX) by \(updatedCameraInertialEulerX + 0.009)")
                        
                    }
                                        
                }
                
                if updatedCameraInertialEulerY > 0.0 {
                    
                    print("\(#function) updatedCameraInertialEulerY is > 0.0")
                    
                    updatedCameraInertialEulerY     = updatedCameraInertialEulerY - updatedCameraInertialEulerY * 0.075
                    //print("\(#function) decreasing updatedCameraInertialEulerY \(updatedCameraInertialEulerY) by \(updatedCameraInertialEulerY - updatedCameraInertialEulerY * 0.025)")
                    
                    if updatedCameraInertialEulerY > 0.0 && updatedCameraInertialEulerY < 0.001 {
                        
                        updatedCameraInertialEulerY     = updatedCameraInertialEulerY - 0.0005
                        //print("\(#function) decreasing updatedCameraInertialEulerY \(updatedCameraInertialEulerY) by \(updatedCameraInertialEulerY - 0.005)")
                        
                    }
                    
                    
                } else {
                    
                    print("\(#function) updatedCameraInertialEulerY is < 0.0")
                    
                    // Never forget that to subtract a negative from a negative, in this case the scaler needs to be...NEGATIVE!
                    updatedCameraInertialEulerY     = updatedCameraInertialEulerY + updatedCameraInertialEulerY * -0.075
                    //print("\(#function) decreasing updatedCameraInertialEulerY \(updatedCameraInertialEulerY) by \(updatedCameraInertialEulerY + updatedCameraInertialEulerY * 0.025)")
                    
                    if updatedCameraInertialEulerY > -0.001 && updatedCameraInertialEulerY < 0.0 {
                        
                        updatedCameraInertialEulerY     = updatedCameraInertialEulerY + 0.0005
                        //print("\(#function) decreasing updatedCameraInertialEulerY \(updatedCameraInertialEulerY) by \(updatedCameraInertialEulerY + 0.005)")
                        
                    }
                                        
                }
                
                print("\(#function) updatedCameraInertialEulerX = \(updatedCameraInertialEulerX)")
                print("\(#function) updatedCameraInertialEulerY = \(updatedCameraInertialEulerY)")
                
                SpacecraftCameraState.shared.cameraInertialEulerX   = updatedCameraInertialEulerX
                SpacecraftCameraState.shared.cameraInertialEulerY   = updatedCameraInertialEulerY
                
                
                SpacecraftCameraState.shared.updateChase360CameraForInertia(of: self.spacecraftFDAICurrentCameraNode,
                                                                            with: updatedCameraInertialEulerX,
                                                                            and: updatedCameraInertialEulerY)
                
            } else {
                
                //
                // Chase360Camera euler angle change has been damped-out enough, so toggle
                // chase360CameraEulersInteriallyDampen to cease these operations.
                //
                SpacecraftCameraState.shared.chase360CameraEulersInertiallyDampen.toggle()
                print("\(#function) SpacecraftCameraState.shared.chase360CameraInertia = \(SpacecraftCameraState.shared.chase360CameraEulersInertiallyDampen)")
                
            }
            
            print("\(#function) inertialElapsedTime: \(inertialElapsedTime)")
            
        }
        
    }
}
    
    
        
    // MARK:-
    // TODO: Consolodate the orbit and orientation code into an orbit class or struct.
    //
    
    // MARK: Orbit Functions
    //
    func deriv(_ stateArray: [Float], with µ: Float) -> [Float] {
        var radius: Float           = 0.0
        var radiusSquared: Float    = 0.0
        
        for i in 0..<3
        {
            radiusSquared   += stateArray[i] * stateArray[i]
        }
        
        radius          = sqrt(radiusSquared)
        let radius3     = pow(radius, 3.0)
        
        
        //
        // Create a velocity array
        //
        var velocityArray: [Float]      = []
        
        for i in 0..<3
        {
            velocityArray   += [stateArray[i + 3]]
        }
        
        
        //
        // Create a acceleration array
        //
        var accelerationArray: [Float] = []
        
        for i in 0..<3
        {
            accelerationArray   += [ -µ * stateArray[i] / radius3 ]
        }
        
        //print("\(#function) velocityArray:\(velocityArray)")
        
        
        //
        // Return the combined velocity and acceleration arrays
        //
        return velocityArray + accelerationArray
    }
    
    
    
    func rungeKutta45(_ stateVector: [Float], deltaT: Float, with µ: Float) -> [Float] {
        let arraySize           = stateVector.count
        var uStateArray         = [Float](repeating: 0.0, count: 6)
        
        var dVelAccelArrray     = deriv(stateVector, with: µ)
        
        
        for i in 0..<arraySize
        {
            dVelAccelArrray[i]      = dVelAccelArrray[i] * deltaT
            uStateArray[i]          = stateVector[i] + 0.5 * dVelAccelArrray[i]
        }
        
        
        var fVelAccelArrray     = deriv(uStateArray, with: µ)
        
        for i in 0..<arraySize
        {
            fVelAccelArrray[i]      *= deltaT
            dVelAccelArrray[i]      += 2.0 * fVelAccelArrray[i]
            uStateArray[i]          = stateVector[i] + 0.5 * fVelAccelArrray[i]
        }
        
        
        fVelAccelArrray         = deriv(uStateArray, with: µ)
        
        
        for i in 0..<arraySize
        {
            fVelAccelArrray[i]      *= deltaT
            dVelAccelArrray[i]      += 2.0 * fVelAccelArrray[i]
            uStateArray[i]          = stateVector[i] + fVelAccelArrray[i]
        }
        
        
        fVelAccelArrray         = deriv(uStateArray, with: µ)
        
        
        var updatedStateVector  = [Float](repeating: 0.0, count: 6)
        
        for i in 0..<arraySize
        {
            updatedStateVector[i]       = stateVector[i] + (dVelAccelArrray[i] + fVelAccelArrray[i] * deltaT) / 6.0
        }
        
        //print("\(#function) updatedStateVector: \(updatedStateVector)")
        return updatedStateVector
    }
     */
}
