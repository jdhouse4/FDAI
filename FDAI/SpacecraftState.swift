//
//  SpacecraftState.swift
//  MissionOrion2
//
//  Created by James Hillhouse IV on 3/14/22.
//

import Foundation
import SceneKit
import simd



@MainActor
class SpacecraftState: ObservableObject {
    
    static let shared = SpacecraftState()
    
    @Published var spacecraftLoaded: Bool   = false
    
    // MARK: Rendering and Delta Orientation Per Time Note
    //
    // Rendering in SceneKit is currently 60 fps. If a ∆° of 0.25°/s is desired, then 0.25 / 60 = 0.0041666...
    //
    // However! The ∆t isn't exactly 0.2 but more like 0.200155999997714162, which is 1.0007799999...times 0.2.
    // So, the correct ∆° is 0.004169916667. But do I really want to be playing a guessing game of what ∆t actually is at
    // the time it's being used? Nopity nope nope!
    //
    // The "fix" is to implement the change at the time the ∆° is being calculated, in the subclass of SCNRendererDelegate function
    // handling those calculations.
    //
    /// This is a place where the position, velocity, orientation, delta-orientation, and translation data is stored and managed.
    let deltaOrientationAngle: Float    = 0.00416666667 /*0.004169916667*/ * .pi / 180.0 // This results in a 0.25°/s attitude change.
    
    
    // MARK: These orientation impulse UInt counters keep track of the number of impulses.
    // -X is an impulse in the negative direction and +X is in the positive.
    var yawImpulseCounter: Int      = 0
    var rollImpulseCounter: Int     = 0
    var pitchImpulseCounter: Int    = 0
    
    ///
    /// The scene for the spacecraft scn
    //@Published var spacecraftScene: SCNScene         = SpacecraftSceneKitScene.shared

    ///
    /// The scene node for the spacecraft itself
    //@Published var spacecraftNode: SCNNode
    
    
    /// Spacecraft Position
    ///
    /// Spacecraft Velocity
    ///
    /// Spacecraft Orientation
    @Published var spacecraftOrientation: simd_quatf  // Do this as a computed property
    
    @Published var spacecraftDeltaQuaternion: simd_quatf
    
    @Published var spacecraftEulerAngles: SIMD3<Float>
    
    var spacecraftRollAngle: Float = 0.0
    
    private init() {
        print("SpacecraftState \(#function)")
        self.spacecraftOrientation        = simd_quatf(ix: 0.0, iy: 0.0, iz: 0.0, r: 1.0)
        
        self.spacecraftDeltaQuaternion    = simd_quatf(ix: 0.0, iy: 0.0, iz: 0.0, r: 1.0)
        
        //self.spacecraftNode               = SpacecraftSceneKitScene.shared.spacecraftNode
        
        self.spacecraftEulerAngles        = simd_float3(x: 0.0, y: 0.0, z: 0.0)
    }
    
    
    
    func degrees2Radians(_ number: Float) -> Float {
        return number * .pi / 180.0
    }
    
    
    
    func radians2Degrees(_ number: Float) -> Float {
        return number * 180.0 / .pi
    }

    
    //
    // MARK: - Roll Orientation Change
    //
    func singleImpulseRollStarboard() -> simd_quatf {
        //print("SpacecraftState singleImpulseStarboard()")
        
        
        rollImpulseCounter += 1
        //print("\(#function): rollImpulseCounter: \(rollImpulseCounter)")

        let rollStarboardQuaternion: simd_quatf = simd_quatf(angle: deltaOrientationAngle,
                                                             axis: simd_float3(x: 1.0, y: 0.0, z: 0.0)).normalized
        
        spacecraftDeltaQuaternion = simd_mul(spacecraftDeltaQuaternion, rollStarboardQuaternion).normalized
        //print("\(#function): spacecraftFDAIDeltaQuaternion: \(spacecraftFDAIDeltaQuaternion.debugDescription)")
        
        return spacecraftDeltaQuaternion
    }
    
    
    
    func doubleImpulseRollStarboard() -> simd_quatf {
        //print("SpacecraftState doubleImpulseStarboard()")
            
        rollImpulseCounter += 2
        //print("\(#function): rollImpulseCounter: \(rollImpulseCounter)")
        
        let rollStarboardQuaternion: simd_quatf = simd_quatf(angle: deltaOrientationAngle * 2.0,
                                                             axis: simd_float3(x: 1.0, y: 0.0, z: 0.0)).normalized
        
        spacecraftDeltaQuaternion = simd_mul(spacecraftDeltaQuaternion, rollStarboardQuaternion).normalized
        //print("\(#function): spacecraftFDAIDeltaQuaternion: \(spacecraftFDAIDeltaQuaternion.debugDescription)")
        
        return spacecraftDeltaQuaternion
    }
    
    
    
    func singleImpulseRollPort() -> simd_quatf {
        //print("SpacecraftState singleImpulsePort()")
        
        rollImpulseCounter -= 1
        //print("\(#function): rollImpulseCounter: \(rollImpulseCounter)")
        
        
        let rollPortQuaternion: simd_quatf = simd_quatf(angle: deltaOrientationAngle,
                                                        axis: simd_float3(x: -1.0, y: 0.0, z: 0.0)).normalized
        
        spacecraftDeltaQuaternion = simd_mul(spacecraftDeltaQuaternion, rollPortQuaternion).normalized
        //print("\(#function): spacecraftFDAIDeltaQuaternion: \(spacecraftFDAIDeltaQuaternion.debugDescription)")
        
        return spacecraftDeltaQuaternion
    }

    
    
    func doubleImpulseRollPort() -> simd_quatf {
        //print("SpacecraftState doubleImpulsePort()")
        
        rollImpulseCounter -= 2
        //print("\(#function): rollImpulseCounter: \(rollImpulseCounter)")
        
        
        let rollPortQuaternion: simd_quatf = simd_quatf(angle: deltaOrientationAngle * 2.0,
                                                        axis: simd_float3(x: -1.0, y: 0.0, z: 0.0)).normalized
        
        spacecraftDeltaQuaternion = simd_mul(spacecraftDeltaQuaternion, rollPortQuaternion).normalized
        //print("\(#function): spacecraftFDAIDeltaQuaternion: \(spacecraftFDAIDeltaQuaternion.debugDescription)")
        
        return spacecraftDeltaQuaternion
    }
    
    
    
    //
    // MARK: - Pitch Orientation Change
    func singleImpulsePitchUp() -> simd_quatf {
        //print("SpacecraftState singleImpulsePitchUp()")
        
        pitchImpulseCounter += 1
        //print("\(#function): pitchImpulseCounter: \(pitchImpulseCounter)")
        
        let pitchUpQuaternion: simd_quatf = simd_quatf(angle: deltaOrientationAngle,
                                                       axis: simd_float3(x: 0.0, y: 0.0, z: 1.0)).normalized
        
        spacecraftDeltaQuaternion = simd_mul(spacecraftDeltaQuaternion, pitchUpQuaternion).normalized
        //print("\(#function): spacecraftDeltaQuaterion: \(spacecraftFDAIDeltaQuaternion.debugDescription)")
        
        return spacecraftDeltaQuaternion
    }

    
    
    func doubleImpulsePitchUp() -> simd_quatf {
        //print("SpacecraftState doubleImpulsePitchUp()")
        
        pitchImpulseCounter += 2
        //print("\(#function): pitchImpulseCounter: \(pitchImpulseCounter)")
        
        let pitchUpQuaternion: simd_quatf = simd_quatf(angle: deltaOrientationAngle * 2.0,
                                                       axis: simd_float3(x: 0.0, y: 0.0, z: 1.0)).normalized
        
        spacecraftDeltaQuaternion = simd_mul(spacecraftDeltaQuaternion, pitchUpQuaternion).normalized
        //print("\(#function): spacecraftDeltaQuaterion: \(spacecraftFDAIDeltaQuaternion.debugDescription)")
        
        return spacecraftDeltaQuaternion
    }
    
    
    
    func singleImpulsePitchDown() -> simd_quatf {
        //print("SpacecraftState singleImpulsePitchUp()")
        
        pitchImpulseCounter -= 1
        //print("\(#function): pitchImpulseCounter: \(pitchImpulseCounter)")
        
        let pitchUpQuaternion: simd_quatf = simd_quatf(angle: deltaOrientationAngle,
                                                       axis: simd_float3(x: 0.0, y: 0.0, z: -1.0)).normalized
        
        spacecraftDeltaQuaternion = simd_mul(spacecraftDeltaQuaternion, pitchUpQuaternion).normalized
        //print("\(#function): spacecraftDeltaQuaterion: \(spacecraftFDAIDeltaQuaternion.debugDescription)")
        
        return spacecraftDeltaQuaternion
    }
    
    
    
    func doubleImpulsePitchDown() -> simd_quatf {
        //print("SpacecraftState doubleImpulsePitchUp()")
        
        pitchImpulseCounter -= 2
        //print("\(#function): pitchImpulseCounter: \(pitchImpulseCounter)")
        
        let pitchUpQuaternion: simd_quatf = simd_quatf(angle: deltaOrientationAngle * 2.0,
                                                       axis: simd_float3(x: 0.0, y: 0.0, z: -1.0)).normalized
        
        spacecraftDeltaQuaternion = simd_mul(spacecraftDeltaQuaternion, pitchUpQuaternion).normalized
        //print("\(#function): spacecraftDeltaQuaterion: \(spacecraftFDAIDeltaQuaternion.debugDescription)")
        
        return spacecraftDeltaQuaternion
    }
    
    
    //
    // MARK: - Yaw Orientation Change
    func singleImpulseYawStarboard() -> simd_quatf {
        print("SpacecraftState singleImpulseYawStarboard()")
        
        yawImpulseCounter -= 1
        print("\(#function): yawImpulseCounter: \(yawImpulseCounter)")

        let yawStarboardQuaternion: simd_quatf = simd_quatf(angle: deltaOrientationAngle,
                                                       axis: simd_float3(x: 0.0, y: -1.0, z: 0.0)).normalized
        
        spacecraftDeltaQuaternion = simd_mul(spacecraftDeltaQuaternion, yawStarboardQuaternion).normalized
        print("\(#function): spacecraftDeltaQuaterion: \(spacecraftDeltaQuaternion.debugDescription)")
        
        return spacecraftDeltaQuaternion
    }
    
    
    
    func doubleImpulseYawStarboard() -> simd_quatf {
        print("SpacecraftState doubleImpulseYawStarboard()")
        
        yawImpulseCounter -= 2
        print("\(#function): yawImpulseCounter: \(yawImpulseCounter)")

        let yawStarboardQuaternion: simd_quatf = simd_quatf(angle: deltaOrientationAngle * 2.0,
                                                       axis: simd_float3(x: 0.0, y: -1.0, z: 0.0)).normalized
        
        spacecraftDeltaQuaternion = simd_mul(spacecraftDeltaQuaternion, yawStarboardQuaternion).normalized
        print("\(#function): spacecraftDeltaQuaterion: \(spacecraftDeltaQuaternion.debugDescription)")
        
        return spacecraftDeltaQuaternion
    }
    
    
    
    func singleImpulseYawPort() -> simd_quatf {
        print("SpacecraftState singleImpulseYawPort()")
        
        yawImpulseCounter += 1
        print("\(#function): yawImpulseCounter: \(yawImpulseCounter)")

        let yawPortQuaternion: simd_quatf = simd_quatf(angle: deltaOrientationAngle,
                                                            axis: simd_float3(x: 0.0, y: 1.0, z: 0.0)).normalized
        
        spacecraftDeltaQuaternion = simd_mul(spacecraftDeltaQuaternion, yawPortQuaternion).normalized
        print("\(#function): spacecraftDeltaQuaterion: \(spacecraftDeltaQuaternion.debugDescription)")
        
        return spacecraftDeltaQuaternion
    }
    
    
    
    func doubleImpulseYawPort() -> simd_quatf {
        print("SpacecraftState doubleImpulseYawPort()")
        
        yawImpulseCounter -= 2
        print("\(#function): yawImpulseCounter: \(yawImpulseCounter)")

        
        let yawPortQuaternion: simd_quatf = simd_quatf(angle: deltaOrientationAngle * 2.0,
                                                            axis: simd_float3(x: 0.0, y: 1.0, z: 0.0)).normalized
        
        spacecraftDeltaQuaternion = simd_mul(spacecraftDeltaQuaternion, yawPortQuaternion).normalized
        print("\(#function): spacecraftDeltaQuaterion: \(spacecraftDeltaQuaternion.debugDescription)")
        
        return spacecraftDeltaQuaternion
    }

    
    
    //
    // MARK: - Update and Reset Orientation
    func spacecraftEulerAngles(from quaternion: simd_quatf) {
        print("SpacecraftState \(#function)")
        
        ///
        /// Thanks go to Thilo (https://stackoverflow.com/users/11655730/thilo) for this simple way of obtaining Euler angles
        /// of a node.
        ///
        /// for his post on Stack Overflow, (https://stackoverflow.com/a/71344720/1518544)
        ///
        let node = SCNNode()
        node.simdOrientation    = quaternion
        self.spacecraftEulerAngles = node.simdEulerAngles
    }
    
    
    
    func resetOrientation() -> simd_quatf {
        return simd_quatf(angle: 0, axis: simd_float3(x: 0.0, y: 0.0, z: 0.0))
    }
}
