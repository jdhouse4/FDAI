//
//  SpacecraftCameraState.swift
//  MissionOrion2
//
//  Created by James Hillhouse IV on 8/7/22.
//

import Foundation
import SceneKit
import SwiftUI
import simd




@MainActor
class SpacecraftCameraState: ObservableObject {
    
    // Needed to expose the camera state to the rest of the code base.
    static var shared                                           = SpacecraftCameraState()
    
    private let screenWidth                                     = UIScreen.main.bounds.width
    
    private var motionManager: MotionManager                    = MotionManager.shared
    
    @Published var currentCamera: SCNNode                       = SCNNode()
    @Published var updateCameraAttitude: Bool                   = false
    
    //
    // These have to do with the camera's orientation, etc.
    //
    //@Published var currentEulerAngles: simd_float3              = simd_float3()
    @Published var totalCommanderCameraEulerAngles: simd_float3 = simd_float3()
    @Published var totalChase360CameraEulerAngles: simd_float3  = simd_float3()
    //@Published var currentCameraTransform: SCNMatrix4           = SCNMatrix4()
    
    
    //
    // This has to do with the camera's magnification, really FOV.
    //
    let maximumCurrentCameraFOV: CGFloat                        = 15 // Zoom-in. Was 25.
    let minimumCurrentCameraFOV: CGFloat                        = 90 // Zoom-out.
    @Published var currentCameraMagnification: CGFloat          = CGFloat(1.0)
    
    
    
    @Published var chase360CameraEulersInertiallyDampen: Bool   = false
    let decelerationRate: Float                                 = 1.0
    var endLocationX: Float                                     = Float()
    var endLocationY: Float                                     = Float()
    var predictedEndTranslation: simd_float2                    = simd_float2()
    var predictedEndTranslationLength: Float                    = 0.0
    var deltaTranslation: simd_float2                           = simd_float2()
    var deltaTranslationLength: Float                           = 0.0
    var decelerationTimeSteps: Float                            = 0.0
    
    @Published var cameraInertialEulerX: Float                  = Float()
    @Published var cameraInertialEulerY: Float                  = Float()
    
    
    // MARK: -Change Camera Orientation
    
    /*
    func changeExteriorCameraOrientation(of currentCameraNode: SCNNode, with value: DragGesture.Value) {
        
        print("\(#function) Beginning Drag Locations: \(value.startLocation)")
        
        
        //print("\n")
        
        //
        // Exterior cameras have different needs than interior cameras in tracking translation changes.
        //
        //inertialStartLocation  = simd_float2(x: Float(value.location.x), y: Float(value.location.y))
        //print("\(#function) inertialStartLocation: \(inertialStartLocation)")
        
        
        let translationX = Float( value.translation.width )
        let translationY = Float( value.translation.height )
        //print("\(#function) translationX: \(translationX)")
        //print("\(#function) translationY: \(translationY)")
        
        
        //
        // Using Euler Angles
        //
        //print("\(#function) Beginning of DragGesture .onChanged of \(currentCameraNode.name!) simdEulerAngles: \(currentCameraNode.simdEulerAngles)")
        //print("\(#function) Beginning of DragGesture .onChanged of \(currentCameraNode.name!) Total simdEulerAngles: \(totalChase360CameraEulerAngles)")
        
        let translationWidthRatio   = translationX / Float(UIScreen.main.bounds.width)
        let translationHeightRatio  = translationY / (Float(UIScreen.main.bounds.height) * 2.0 ) // This is to slow-down pitch, which can be a pain when also yawing.
        //print("\(#function) translationWidthRatio: \(translationWidthRatio)")
        //print("\(#function) translationHeightRatio: \(translationHeightRatio)")
        
        let cameraEulerX    = Float(-2 * Double.pi) * translationWidthRatio
        let cameraEulerY    = Float(Double.pi) * translationHeightRatio
        print("\(#function) cameraEulerX: \(cameraEulerX)")
        print("\(#function) cameraEulerY: \(cameraEulerY)")
        
        
        currentCameraNode.eulerAngles.y = cameraEulerX + totalChase360CameraEulerAngles.y
        print("\(#function) Chase360Camera euler.y: \(currentCameraNode.eulerAngles.y)")
        
        if abs(cameraEulerY + totalChase360CameraEulerAngles.z) > abs(Float(Double.pi / 2.0)) {
            
            //print("\(#function) Ooopsie! Angle too high.")
            
            if cameraEulerY + totalChase360CameraEulerAngles.z > 0 {
                
                currentCameraNode.eulerAngles.z = Float(Double.pi / 2.0)
                
            } else {
                
                currentCameraNode.eulerAngles.z = -Float(Double.pi / 2.0)
                
            }
            
        } else {
            
            currentCameraNode.eulerAngles.z = cameraEulerY + totalChase360CameraEulerAngles.z
            
        }
        
        
        
        
        //print("\n\(#function) End of DragGesture .onChanged end translation \(value.translation)")
        //print("\(#function) End of DragGesture .onChanged predicted end translation \(value.predictedEndTranslation)")
        
        //print("\n\(#function) End of DragGesture .onChanged end location \(value.location)")
        //print("\(#function) End of DragGesture .onChanged predicted end location \(value.predictedEndLocation)")
        //print("\(#function) End of DragGesture .onChanged simdEulerAngles: \(currentCameraNode.simdEulerAngles)")
        //print("\(#function) End of DragGesture .onChanged of \(currentCameraNode.name!) Total simdEulerAngles: \(totalChase360CameraEulerAngles)")
         
    }
    
    
    
    func changeInteriorCameraOrientation(of currentCameraNode: SCNNode, with value: DragGesture.Value) {
        
        //print("\n")
        
        
        let translationX = Float(value.translation.width)
        let translationY = Float(-value.translation.height)
        
        
        //
        // Using Euler Angles
        //
        //print("\(#function) Beginning of DragGesture .onChanged simdEulerAngles: \(currentCameraNode.simdEulerAngles)")
        //print("\(#function) Beginning of DragGesture .onChanged of \(currentCameraNode.name!) Total simdEulerAngles: \(totalCommanderCameraEulerAngles)")
        
        let translationWidthRatio   = translationX / Float(UIScreen.main.bounds.width)
        let translationHeightRatio  = translationY / Float(UIScreen.main.bounds.height)
        
        let cameraEulerX    = Float(-2 * Double.pi) * translationWidthRatio
        let cameraEulerY    = Float(-Double.pi) * translationHeightRatio
        
        currentCameraNode.eulerAngles.y =    cameraEulerX + totalCommanderCameraEulerAngles.y
        currentCameraNode.eulerAngles.x = -( cameraEulerY + -( totalCommanderCameraEulerAngles.x ) )
        
        //print("\(#function) End of DragGesture .onChanged simdEulerAngles: \(currentCameraNode.simdEulerAngles)")
        //print("\(#function) End of DragGesture .onChanged of \(currentCameraNode.name!) Total simdEulerAngles: \(totalCommanderCameraEulerAngles)")
        
    }
    
    
    
    // MARK: Calculate delta between initial and final translation from touch
    // Determine if the user's gesture was sufficient to indicate that there should be some camera inertia
    // after the user lifts their finger.
    fileprivate func calculatePredictedAndEndTranslationDelta(_ value: DragGesture.Value) {
        //
        // Record the DragGesture.Value parameters at the end of the swipe.
        //
        endLocationX                = Float( value.location.x)
        endLocationY                = Float( value.location.y)
        //print("\(#function) endLocationX: \(value.location.x)")
        //print("\(#function) endLocationY: \(value.location.y)")
        //print("\(#function) Translation: \((simd_float2(x: Float(value.translation.width), y: Float(value.translation.height))))")
        
        predictedEndTranslation     = simd_float2(x: Float(value.predictedEndTranslation.width),
                                                  y: Float(value.predictedEndTranslation.height))
        //print("\(#function) predictedEndLocationX: \((value.predictedEndLocation.x))")
        //print("\(#function) predictedEndLocationY: \((value.predictedEndLocation.y))")
        //print("\(#function) predictedEndTranslation: \((predictedEndTranslation))")
        
        
        deltaTranslation            = simd_float2(x: Float(value.predictedEndTranslation.width), y: Float(value.predictedEndTranslation.height)) - simd_float2(x: Float(value.translation.width), y: Float(value.translation.height))
        //print("\(#function) deltaTranslation: \(deltaTranslation)")
        
        deltaTranslationLength      = simd_length(deltaTranslation)
        //print("\(#function) predicted - actual translation: \(deltaTranslationLength)")
    }
    
    
    
    //
    // MARK: Determine if a DragGesture was of sufficient velocity to enable inertia
    // This fuction determines if a DragGesture was of sufficient velocity to enable inertia, and if so
    // then calculates other things needed for inertia.
    //
    func chase360CameraInertia(of currentCameraNode: SCNNode, with value: DragGesture.Value) {
        
        //print("\n\(#function) Determine whether the inertial is needed and, if so, set the state of SpacecraftCameraState to true.")
        
        //print("\(#function) deltaTranslationLength: \(deltaTranslationLength)")
        
        print("\(#function) deltaTranslationLength > 50: \(deltaTranslationLength > 50 ? "true" : "false")")
        
        
        //
        // If deltaTranslationLength is above a certain amount, then there needs to be inertial dampening of the
        // Chase360Camera euler angles x and y over a period of time. This simulates that the camera can be whipped-around.
        //
        if deltaTranslationLength > 50 {
            
            //
            // We need to do some preliminary work here.
            //
            //calculateTimeSteps()
            
            //
            // This calculates the values for cameraInertialEulerX and cameraInertialEulerY, which will be used in the SCNRendererDelegate
            // to affect an inertially dampening of the change of the camera's euler angles.
            //
            calculateCameraEulerAngles()
            
            //
            // Now that the preliminary work is done calculating cameraInertialEulerX and cameraInertialEulerY, setting
            // chase360CameraEulersInertiallyDampen = true will trigger SCNRendererDelegate to call updateChase360CameraForInertia until
            // cameraInertialEulerX and cameraInertialEulerY are small enough to zero-out and cease Chase360Camera's euler angle changes.
            //
            chase360CameraEulersInertiallyDampen    = true
            print("\(#function) chase360CameraEulersInertiallyDampen = \(chase360CameraEulersInertiallyDampen)")
            
        }
    }
    
    
    // MARK: Calculate current camera euler angles
    // This will be needed in determining the dampening.
    fileprivate func calculateCameraEulerAngles() {
        //print("\(#function) Calculating the Chase360CameraInertia.")
        
        
        let deltaTranslationXStep   = Float( deltaTranslation.x) / 25.0 //decelerationTimeSteps
        let deltaTranslationYStep   = Float( deltaTranslation.y) / 25.0 //decelerationTimeSteps
        //print("\(#function) deltaTranslationXStep: \(deltaTranslationXStep)")
        //print("\(#function) deltaTranslationYStep: \(deltaTranslationYStep)")
        
        let calculatedX             = deltaTranslationXStep
        let calculatedY             = deltaTranslationYStep
        //print("\(#function) calculatedX: \(calculatedX)")
        //print("\(#function) calculatedY: \(calculatedY)")
        
        let translationWidthRatio   = Float( calculatedX ) /        Float(UIScreen.main.bounds.width)
        let translationHeightRatio  = Float( calculatedY ) / (2.0 * Float(UIScreen.main.bounds.height)) // This is to slow-down pitch, which can be a pain when also yawing.
        //print("\(#function) translationWidthRatio: \(translationWidthRatio)")
        //print("\(#function) translationHeightRatio: \(translationHeightRatio)")
        
        cameraInertialEulerX        = Float(-2 * Double.pi) * translationWidthRatio // Yaw
        cameraInertialEulerY        = Float(Double.pi) * translationHeightRatio // Pitch
        //print("\(#function) cameraInertialEulerX: \(cameraInertialEulerX)")
        //print("\(#function) cameraInertialEulerY: \(cameraInertialEulerY)")
        
    }
    
    
    // MARK: Update the camera for the euler angles instilled from inertia.
    func updateChase360CameraForInertia(of currentCameraNode: SCNNode, with cameraInertialEulerX: Float, and cameraInertialEulerY: Float) {
        print("\(#function)")
        
        //
        // The node's orientation would be calculated here
        //
        //
        // Assign yaw.
        currentCameraNode.eulerAngles.y = cameraInertialEulerX + self.totalChase360CameraEulerAngles.y
        //print("\(#function) Chase360Camera euler.y: \(currentCameraNode.eulerAngles.y)")
        
        //
        // Deal with pitch exceeding ± 90°
        //
        if abs(cameraInertialEulerY + self.totalChase360CameraEulerAngles.z) > abs(Float(Double.pi / 2.0)) {
            
            //print("\(#function) Ooopsie! Angle too high.")
            
            if cameraInertialEulerY + self.totalChase360CameraEulerAngles.z > 0 {
                
                currentCameraNode.eulerAngles.z = Float(Double.pi / 2.0)
                
            } else {
                
                currentCameraNode.eulerAngles.z = -Float(Double.pi / 2.0)
                
            }
            
        } else {
            
            currentCameraNode.eulerAngles.z = cameraInertialEulerY + self.totalChase360CameraEulerAngles.z
            
        }
        
        totalChase360CameraEulerAngles      = currentCameraNode.simdEulerAngles
        
    }
    
    
    // MARK: Update the final camera orientation.
    func updateCameraOrientation(of currentCameraNode: SCNNode, with value: DragGesture.Value) {
        //print("\n")
        
        //print("\(#function)")
        
        //
        // Using Euler Angles
        //
        //print("\(#function) Current Eulers: \(String(describing: currentCameraNode.simdEulerAngles))")
        //print("\(#function) Total Eulers: \(String(describing: totalCommanderCameraEulerAngles))")
        
        
        //
        // Determine the camera node for which to set the total euler angles.
        //
        if currentCameraNode.name! + "Node" == SpacecraftFDAICamera.spacecraftCommanderCamera.rawValue {
            
            //print("\(#function) Current Camera Node is: \(currentCameraNode.name!)")
            
            totalCommanderCameraEulerAngles     = currentCameraNode.simdEulerAngles
            
            //print("\(#function) Total Interior Eulers after adding: \(String(describing: totalCommanderCameraEulerAngles))")
            
        }
        if currentCameraNode.name! == SpacecraftFDAICamera.spacecraftChase360Camera.rawValue {
            
            //print("\(#function) Current Camera Node is: \(currentCameraNode.name!)")
            
            totalChase360CameraEulerAngles      = currentCameraNode.simdEulerAngles
            //print("\(#function) totalChase360CameraEulerAngles: \(totalChase360CameraEulerAngles)")
            
            calculatePredictedAndEndTranslationDelta(value)
            
            //print("\(#function) Total Eulers after adding: \(String(describing: totalChase360CameraEulerAngles))")
            
        }
        
    }

    
    
    // MARK: -Change Camera FOV (for magnification)
    
    func resetCameraOrientation(of currentCameraNode: SCNNode) {
        //print("\n")
        //
        // This resets the cameras so that resetting the update on one doesn't pollute the other cameras.
        //
        
        currentCameraNode.transform = SCNMatrix4Identity
        
        print("\(#function) currentCameraNode.name: \(currentCameraNode.name!)")
        
        // This resets the "neck" of the spacecraft's interior commander camera
        if currentCameraNode.name! + "Node" == SpacecraftFDAICamera.spacecraftCommanderCamera.rawValue {
            
            //print("\(#function) RESET currentCameraNode.name: \(currentCameraNode.name!)")
            //print("\(#function) RESET SpacecraftFDAICamera.spacecraftCommanderCamera.rawValue: \(SpacecraftFDAICamera.spacecraftCommanderCamera.rawValue)")
            
            totalCommanderCameraEulerAngles         *= 0.0
            currentCameraNode.pivot                 = SCNMatrix4Identity
            currentCameraNode.simdEulerAngles       *= 0.0
            currentCameraNode.simdPivot.columns.3.y = -0.09
            
        } else if currentCameraNode.name! == SpacecraftFDAICamera.spacecraftChase360Camera.rawValue{
            
            //print("\(#function) RESET currentCameraNode.name: \(currentCameraNode.name!)")
            //print("\(#function) RESET SpacecraftFDAICamera.spacecraftCommanderCamera.rawValue: \(SpacecraftFDAICamera.spacecraftCommanderCamera.rawValue)")
            
            totalChase360CameraEulerAngles          *= 0.0
            currentCameraNode.pivot                 = SCNMatrix4Identity
            currentCameraNode.simdEulerAngles       *= 0.0
        }
        
        // Don't forget to reset the gyro so that as one swaps between cameras in gyro mode, the user isn't exposed to some unexpected orientation.
        motionManager.resetReferenceFrame()
    }
    
    
    
    func changeCurrentCameraFOV(of camera: SCNCamera, value: CGFloat) {
        if currentCameraMagnification >= 1.025 {
            currentCameraMagnification  = 1.025
        }
        if currentCameraMagnification <= 0.97 {
            currentCameraMagnification  = 0.97
        }
        
        //let maximumFOV: CGFloat = 25 // Zoom-in.
        //let minimumFOV: CGFloat = 90 // Zoom-out.
        
        camera.fieldOfView /= currentCameraMagnification
        
        if camera.fieldOfView <= maximumCurrentCameraFOV {
            camera.fieldOfView          = maximumCurrentCameraFOV
            currentCameraMagnification  = 1.0
        }
        if camera.fieldOfView >= minimumCurrentCameraFOV {
            camera.fieldOfView          = minimumCurrentCameraFOV
            currentCameraMagnification  = 1.0
        }
    }
    
    
    
    func resetCurrentCameraFOV(of currentCamera: SCNCamera, screenWdith: UserInterfaceSizeClass) {
        print("\(#function) resetting cameraFOV")
        print("\(#function) current camera: \(String(describing: currentCamera.name)) FOV: \(currentCamera.fieldOfView)")
        print("\(#function) current screenWidth size class: \(screenWidth)")
        
        
        if currentCamera.name == SpacecraftFDAICamera.spacecraftChase360Camera.rawValue {
            if screenWdith == .compact {
                currentCamera.fieldOfView = 45
            }
            if screenWdith == .regular {
                currentCamera.fieldOfView = 50
            }
            print("spacecraftFDAICamera FOV: \(currentCamera.fieldOfView)")
        }
        
        if currentCamera.name == SpacecraftFDAICamera.spacecraftCommanderCamera.rawValue {
            if screenWdith == .compact {
                currentCamera.fieldOfView = 35
            }
            if screenWdith == .regular {
                currentCamera.fieldOfView = 45
            }
        }
        print("spacecraftCommanderCamera FOV: \(currentCamera.fieldOfView)")
    }
    */
    
}
