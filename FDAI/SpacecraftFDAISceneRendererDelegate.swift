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
    var resetSpacecraftEulerAngles: Bool     = false
    
    //
    // Orientation properties
    //
    @Published var spacecraftFDAIDeltaQuaternion: simd_quatf    = simd_quatf()
    @Published var spacecraftOrientation: simd_quatf            = simd_quatf()
    @Published var spacecraftEulerAngles: SIMD3<Float>          = simd_float3()
    
    var spacecraftPreviousFDAIQuaternion: simd_quatf        = simd_quatf()
    var spacecraftCurrentFDAIQuaternion: simd_quatf         = simd_quatf()
    var deltaEulerAngles: SIMD3<Float>                      = simd_float3()
    
    var spacecraftRollAngle: Float                          = 0.0
    var spacecraftYawAngle: Float                           = 0.0
    var spacecraftPitchAngle: Float                         = 0.0
    
    
    //
    // Orientation and Their Rate Change Parameters
    //
    var deltaRoll : Float                   = 0.0
    var deltaPitch: Float                   = 0.0
    var deltaYaw  : Float                   = 0.0
    var rollRate  : Float                   = 0.0
    var pitchRate : Float                   = 0.0
    var yawRate   : Float                   = 0.0
    
    @Published var deltaRollRate:Float      = 0.0
    @Published var deltaPitchRate: Float    = 0.0
    @Published var deltaYawRate: Float      = 0.0
    
    
    var motionManager                                       = MotionManager.shared

    //
    // For switching cameras in the scene.
    //
    @Published var spacecraftFDAICurrentCamera: String          = SpacecraftFDAICamera.spacecraftFDAICamera.rawValue
    @Published var spacecraftFDAICurrentCameraNode: SCNNode     = SCNNode()
    
    
    var changeCamera: Bool                          = false
        
    var showsStatistics: Bool                       = false
    
    // Time, oh time...
    var _previousUpdateTime: TimeInterval           = 0.0
    var _previousUpdateTimeAnimation: TimeInterval  = 0.0
    var _previousUpdateTimeRenderer: TimeInterval   = 0.0
    var _deltaTime: TimeInterval                    = 0.0
    var _deltaTimeAnimation: TimeInterval           = 0.0
    var _deltaTimeRenderer: TimeInterval            = 0.0
    var inertialElapsedTime: TimeInterval           = 0.0
    
    
    // MARK: Variables from "Fix Your Time Step"
    var t: Float                                    = 0.0
    var diffTime: TimeInterval                      = 0.0
    var dT: Float                                   = 0.03 // Desired framerate
    var currentTime: TimeInterval                   = 0.0
    var accumulator: Float                          = 0.0

    
    
    override init() {
        print("\n\(#function) SpacecraftFDAISceneRendererDelegate override initialized\n")
        
        //
        // This call has been moved to the App protocol, SwiftUISceneKitCoreMotionDemoApp.swift.
        //
        //self.motionManager.setupDeviceMotion()
        
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
        
        spacecraftPreviousFDAIQuaternion = spacecraftCurrentFDAIQuaternion
        
        
        ///
        // MARK: Update the attitude.quaternion from device manager
        ///
        motionManager.updateAttitude()
        
        
        if resetSpacecraftEulerAngles == true {
            
            print("\(#function) Resetting!!!")
            
            resetEulerAngles()
            
            resetSpacecraftEulerAngles.toggle()
            
        }
        
        
        // MARK: Fix Your TimeStep Code
        //
        // Thanks to okmkz for simplifying the code from the original post,
        // https://www.reddit.com/r/libgdx/comments/5ib2q3/trying_to_get_my_head_around_fixed_timestep_in/
        //
        // that was located here under "Fix Your Timestep",
        // https://gafferongames.com/post/fix_your_timestep/
        //
        // that Peter Liu found for me.
        //
        
        
        if currentTime == 0.0 {
            
            currentTime = time
            
        }
        
        
        //diffTime = time - currentTime
        
        let newTime: TimeInterval = time
        
        var frameTime: TimeInterval = newTime - currentTime
        
        if frameTime > 0.25 {
            
            frameTime = 0.25
            
        }
        
        currentTime = time
        
        accumulator += Float(frameTime)
        
        while accumulator >= dT {
            
            accumulator -= dT
            
            
            //
            // Determine whether to let the motion manager update the camera orientation based on whether
            // the user is currently using the gyro features or not.
            //
            if spacecraftFDAICurrentCamera == SpacecraftFDAICamera.spacecraftFDAICamera.rawValue {
                
                //print("\(#function) updating spacecraftFDAICurrentCameraNode: \(spacecraftFDAICurrentCameraNode.name)")
                self.updateFDAICameraOrientation(of: spacecraftFDAICurrentCameraNode)
                //self.updateFDAICameraOrientation(of: spacecraftFDAINode)
                
            }
            
            /*
             if resetSpacecraftEulerAngles {
             
             resetEulerAngles()
             
             resetSpacecraftEulerAngles.toggle()
             
             }
             */
            
            
            //
            // MARK: Calculate current euler angles, previous to updating and then reading the spacecraft's orientation.
            //
            deltaEulerAngles            = spacecraftSceneNodeDeltaEulerAngles()
            
            
            // Calculate Delta Angles
            deltaRoll   =  radians2Degrees(deltaEulerAngles.z)
            deltaYaw    =  -radians2Degrees(deltaEulerAngles.y)
            deltaPitch  =  radians2Degrees(deltaEulerAngles.x)
            
            // Calculate the rate of change in angle deltas.
            rollRate    = deltaRoll / Float(dT)
            yawRate     = deltaYaw / Float(dT)
            pitchRate   = deltaPitch / Float(dT)
            
            
            //
            // Roll
            //
            if spacecraftRollAngle > 360.0 {
                
                spacecraftRollAngle = 0.0
                
            }
            
            
            if rollRate > 0.0 {
                
                spacecraftRollAngle += abs(deltaRoll)
                
                
            } else if rollRate < 0.0 {
                
                
                if spacecraftRollAngle > 0.0 {
                    
                    spacecraftRollAngle -= abs(deltaRoll)
                    
                    
                }  else {
                    
                    spacecraftRollAngle = 360.0 - abs(deltaRoll)
                    
                }
                
            }
            
            
            //
            // Yaw
            //
            if spacecraftYawAngle >= 360.0 {
                
                spacecraftYawAngle = 0.0
                
            }
            
            
            if yawRate > 0.0 {
                
                spacecraftYawAngle += abs(deltaYaw)
                
                
            } else if yawRate < 0.0 {
                
                
                if spacecraftYawAngle > 0.0 {
                    
                    spacecraftYawAngle -= abs(deltaYaw)
                    
                    
                }  else {
                    
                    spacecraftYawAngle = 360.0 - abs(deltaYaw)
                    
                }
                
            }
            
            
            //
            // Pitch
            //
            if spacecraftPitchAngle > 360.0 {
                
                spacecraftPitchAngle = 0.0
                
            }
            
            
            if pitchRate > 0.0 {
                
                spacecraftPitchAngle += abs(deltaPitch)
                
                
            } else if pitchRate < 0.0 {
                
                
                if spacecraftPitchAngle > 0.0 {
                    
                    spacecraftPitchAngle -= abs(deltaPitch)
                    
                    
                }  else {
                    
                    spacecraftPitchAngle = 360.0 - abs(deltaPitch)
                    
                }
                
            }
            
            
            //t += dT
            
        }
        
        /*
         print("\n")
         //print("\(#function) spacecraftYawAngleDelta: \(spacecraftYawAngleDelta)°/s")
         //print("\(#function) SpacecraftState.shared.yawImpulseCounter = \(SpacecraftState.shared.yawImpulseCounter)")
         //print("\(#function) spacecraftSceneNode.simdEulerAngles.y = \(spacecraftSceneNode.simdEulerAngles.y)")
         //print("\(#function) spacecraftPreviousEulerAngles.y: \(spacecraftPreviousEulerAngles.y)radians")
         //print("\(#function) spacecraftPreviousYawAngle: \(spacecraftPreviousYawAngle)°")
         //print("\(#function) spacecraftCurrentEulerAngles.y: \(spacecraftCurrentEulerAngles.y) radians")
         //print("\(#function) spacecraftCurrentPitchEulerAngle: \(-spacecraftFDAICurrentCameraNode.simdEulerAngles.x * 180.0 / .pi)°")
         //print("\(#function) deltaPitch: \(deltaPitch)°")
         //print("\(#function) pitchRate: \(pitchRate)°/s")
         //print("\(#function) spacecraftPitchAngle: \(spacecraftPitchAngle)°")
         //print("\(#function) spacecraftCurrentYawEulerAngle: \(-spacecraftFDAICurrentCameraNode.simdEulerAngles.y * 180.0 / .pi)°")
         print("\(#function) deltaYaw: \(deltaYaw)°")
         print("\(#function) yawRate: \(yawRate)°/s")
         print("\(#function) spacecraftYawAngle: \(spacecraftYawAngle)°")
         //print("\(#function) deltaRoll: \(deltaRoll)°")
         //print("\(#function) rollRate: \(rollRate)°/s")
         //print("\(#function) spacecraftRollAngle: \(spacecraftRollAngle)°")
         //print("\(#function) frameTime: \(frameTime)s")
         //print("\(#function) diffTime: \(diffTime)")
         //print("\(#function) accumulator: \(accumulator)")
         print("\(#function) dT: \(dT)")
         //print("\(#function) t: \(t)\n")
         */
        
    }
    
    
    
    @MainActor
    func renderer(_ renderer: SCNSceneRenderer, didApplyAnimationsAtTime time: TimeInterval) {
        
        
    }
    
    
    
    func renderer(_ renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: TimeInterval) {
        
        // This is to ensure that the time is initialized properly for the simulator.
        if _previousUpdateTimeRenderer == 0.0
        {
            
            _previousUpdateTimeRenderer     = time
            //print("\(#function) setting _previousUpdateTime to time: \(time)\n")
            
        }
        
        _deltaTimeRenderer  = time - _previousUpdateTimeRenderer
        //print("\(#function) _deltaTime: \(_deltaTime)")
        
        
        // MARK: Calculate attitude changes and rates, and loading of assets.
        if _deltaTimeRenderer > 0.2
        {
            //
            // Calculating euler angles and roll rates
            //
            //print("\n\(#function) Time to display calculated eulers and roll rates at: \(_deltaTimeRenderer).")
            //print("\(#function) _deltaTime: \(_deltaTime)")
            
            
            // MARK: _deltaTime is reset to zero.
            _previousUpdateTimeRenderer         = time
            //print("\(#function) _previousTime: \(_previousUpdateTime)")
            
            
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
                    
                    self.spacecraftEulerAngles    = self.spacecraftFDAISceneNode.simdEulerAngles
                    //print("\(#function) self.spacecraftFDAIEulerAngles: \(self.spacecraftFDAIEulerAngles)")
                    
                    self.deltaRollRate          = rollRate
                    //print("\(#function) self.deltaRollRate: \(self.deltaRollRate)")
                    
                    self.deltaPitchRate         = pitchRate
                    //print("\(#function) self.deltaPitchRate: \(self.deltaPitchRate)")
                    
                    self.deltaYawRate           = yawRate
                    //print("\(#function) self.deltaYawRate: \(self.deltaYawRate)")
                    
                    
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

        
    }
    
    
    
    func stillAlive() {
        
        print("\n\(#function) Oh yeah!!!\n")
        
    }
    
    
    
    func resetEulerAngles() -> Void {
        
        spacecraftRollAngle     = 0.0
        spacecraftYawAngle      = 0.0
        spacecraftPitchAngle    = 0.0
        
        deltaRoll               = 0.0
        deltaYaw                = 0.0
        deltaPitch              = 0.0
        
        spacecraftPreviousFDAIQuaternion = simd_quatf(angle: 0, axis: simd_float3(x: 0.0, y: 0.0, z: 0.0))
        spacecraftCurrentFDAIQuaternion =  simd_quatf(angle: 0, axis: simd_float3(x: 0.0, y: 0.0, z: 0.0))
        
        deltaEulerAngles = spacecraftSceneNodeDeltaEulerAngles()
        
        //print("\n\(#function) All Euler angle parameters reset.")
        
    }
    
    
    
    // TODO: Consider merging this functionality into spacecraftSceneNodeDeltaEulerAngles since it's used in calculatedSpacecraft..., which is temporary.
    fileprivate func spacecraftEulerAngles(from deltaQuaternion: simd_quatf) -> simd_float3 {
        
        let n = SCNNode()
        n.simdOrientation = deltaQuaternion
        
        return n.simdEulerAngles
        
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
        
        //
        // For the current camera node
        //
        node.simdOrientation   = simd_quatf(ix: -Float(motionManager.deviceMotion!.attitude.quaternion.x),
                                            iy: -Float(motionManager.deviceMotion!.attitude.quaternion.y),
                                            iz:  Float(motionManager.deviceMotion!.attitude.quaternion.z),
                                            r:   Float(motionManager.deviceMotion!.attitude.quaternion.w)).normalized
        

        /*
        //
        // For the FDAI node rotations
        //
        node.simdOrientation   = simd_quatf(ix:  Float(motionManager.deviceMotion!.attitude.quaternion.x),
                                            iy:  Float(motionManager.deviceMotion!.attitude.quaternion.y),
                                            iz: -Float(motionManager.deviceMotion!.attitude.quaternion.z),
                                            r:   Float(motionManager.deviceMotion!.attitude.quaternion.w)).normalized
        */

        //
        // Be sure to set the updated orientation of the FDAI camera node. This will be needed for angles and rates.
        //
        spacecraftCurrentFDAIQuaternion = node.simdOrientation
        
    }
     
    
    
    func spacecraftSceneNodeOrientationDelta(of previousFDAIOrientation: simd_quatf, and currentFDAIOrientation: simd_quatf) -> simd_quatf {
        
        let inversePreviousQuaternion = previousFDAIOrientation.normalized.inverse
        let currentQuaternion         = currentFDAIOrientation.normalized
        
        return simd_mul(currentQuaternion, inversePreviousQuaternion).normalized
        
    }
    
    
    
    fileprivate func spacecraftSceneNodeDeltaEulerAngles() -> simd_float3 {
        
        let deltaQuaternion     = spacecraftSceneNodeOrientationDelta(of: spacecraftCurrentFDAIQuaternion, and: spacecraftPreviousFDAIQuaternion)
        let node = SCNNode()
        node.simdOrientation    = deltaQuaternion
        
        return node.simdEulerAngles
        
    }
    
    
    
    func setCurrentCameraName(name: String) {
        spacecraftFDAICurrentCamera = name
    }
    
    
    
    func setCurrentCameraNode(node: SCNNode) {
        spacecraftFDAICurrentCameraNode = node
        motionManager.resetReferenceFrame()
    }
 
    
    
    func radians2Degrees(_ number: Float) -> Float {
        
        return number * 180.0 / .pi
        
    }
    
}
