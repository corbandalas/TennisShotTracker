/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This class manages the CoreMotion interactions and
         provides a delegate to indicate changes in data.
 */

import Foundation
import CoreMotion
import WatchKit
import CoreML

/**
 `MotionManagerDelegate` exists to inform delegates of motion changes.
 These contexts can be used to enable application specific behavior.
 */
protocol MotionManagerDelegate: class {
    func didUpdateForehandSwingCount(_ manager: MotionManager, forehandCount: Int)
    func didUpdateBackhandSwingCount(_ manager: MotionManager, backhandCount: Int)
}

extension Date {
    var millisecondsSince1970:Int64 {
        return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }
}

struct ModelConstants {
    
    static let predictionWindowSize = 100
    // The app is using 50hz data and the buffer is going to hold 2s worth of data.
      
    static let sensorsUpdateInterval = 1.0 / 50.0
  
}


class MotionManager {
    // MARK: Properties
    
    let motionManager = CMMotionManager()
    let queue = OperationQueue()
    let wristLocationIsLeft = WKInterfaceDevice.current().wristLocation == .left
    let wristLocationIsRight = WKInterfaceDevice.current().wristLocation == .right
    
    // MARK: Application Specific Constants
    
    // These constants were derived from data and should be further tuned for your needs.
    let yawThreshold = 1.95 // Radians
    let rateThreshold = 5.5    // Radians/sec
    let resetThreshold = 5.5 * 0.05 // To avoid double counting on the return swing.

    
    let rateAlongGravityBuffer = RunningBuffer(size: ModelConstants.predictionWindowSize)
    
    let rotationXBuffer = RunningBuffer(size: ModelConstants.predictionWindowSize)
    let rotationYBuffer = RunningBuffer(size: ModelConstants.predictionWindowSize)
    let rotationZBuffer = RunningBuffer(size: ModelConstants.predictionWindowSize)
    
    let accelerationXBuffer = RunningBuffer(size: ModelConstants.predictionWindowSize)
    let accelerationYBuffer = RunningBuffer(size: ModelConstants.predictionWindowSize)
    let accelerationZBuffer = RunningBuffer(size: ModelConstants.predictionWindowSize)
    
    let gravityXBuffer = RunningBuffer(size: ModelConstants.predictionWindowSize)
    let gravityYBuffer = RunningBuffer(size: ModelConstants.predictionWindowSize)
    let gravityZBuffer = RunningBuffer(size: ModelConstants.predictionWindowSize)
    
    let model = TennisShotClassifier_1()
    
   
    let predictionWindowDataArray = try? MLMultiArray(shape: [NSNumber(value: ModelConstants.predictionWindowSize)], dataType: MLMultiArrayDataType.double)
    
    
    weak var delegate: MotionManagerDelegate?

    /// Swing counts.
    var forehandCount = 0
    var backhandCount = 0

    var recentDetection = false
    var shotDetected = false
    
    
    // MARK: Initialization
    
    init() {
        // Serial queue for sample handling and calculations.
        queue.maxConcurrentOperationCount = 1
        queue.name = "MotionManagerQueue"
    }

    // MARK: Motion Manager

    func startUpdates() {
        if !motionManager.isDeviceMotionAvailable {
            print("Device Motion is not available.")
            return
        }

        // Reset everything when we start.
        resetAllState()

        motionManager.deviceMotionUpdateInterval = ModelConstants.sensorsUpdateInterval
        motionManager.startDeviceMotionUpdates(to: queue) { (deviceMotion: CMDeviceMotion?, error: Error?) in
            if error != nil {
                print("Encountered error: \(error!)")
            }

            if deviceMotion != nil {
                self.processDeviceMotion(deviceMotion!)
            }
        }
    }

    func stopUpdates() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.stopDeviceMotionUpdates()
        }
    }

    // MARK: Motion Processing
    
    func processDeviceMotion(_ deviceMotion: CMDeviceMotion) {
        
        let gravity = deviceMotion.gravity
        let rotationRate = deviceMotion.rotationRate
        
        let rateAlongGravity = rotationRate.x * gravity.x // r⃗ · ĝ
                                     + rotationRate.y * gravity.y
                                     + rotationRate.z * gravity.z

       
        if !rotationXBuffer.isFull() {
            
                   shotDetected = false
                   
                   rateAlongGravityBuffer.addSample(rateAlongGravity)
                   
                   rotationXBuffer.addSample(rotationRate.x)
                   rotationYBuffer.addSample(rotationRate.y)
                   rotationZBuffer.addSample(rotationRate.z)
                   
                   accelerationXBuffer.addSample(deviceMotion.userAcceleration.x)
                   accelerationYBuffer.addSample(deviceMotion.userAcceleration.y)
                   accelerationZBuffer.addSample(deviceMotion.userAcceleration.z)

                   gravityXBuffer.addSample(deviceMotion.gravity.x)
                   gravityYBuffer.addSample(deviceMotion.gravity.y)
                   gravityZBuffer.addSample(deviceMotion.gravity.z)
            
            print(
                String(deviceMotion.timestamp),           String(deviceMotion.userAcceleration.x),
                                 String(deviceMotion.userAcceleration.y),
                                 String(deviceMotion.userAcceleration.z),
                                 String(deviceMotion.rotationRate.x),
                                 String(deviceMotion.rotationRate.y),
                                 String(deviceMotion.rotationRate.z),
                                 String(deviceMotion.gravity.x),
                                 String(deviceMotion.gravity.y),
                                 String(deviceMotion.gravity.z),

                          separator: ",")
            
            
            return
        } else {
            print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
            
            if (!shotDetected) {
                let modelPrediction = performModelPrediction()
                
//                print("Predicted class: \(modelPrediction!)")
                  
                
                shotDetected = true
                
                rotationXBuffer.reset()
                rotationYBuffer.reset()
                rotationZBuffer.reset()
                               
                accelerationXBuffer.reset()
                accelerationYBuffer.reset()
                accelerationZBuffer.reset()
                
                gravityXBuffer.reset()
                gravityYBuffer.reset()
                gravityZBuffer.reset()
                
                rateAlongGravityBuffer.reset()
                
                if (modelPrediction! == "forehand") {
                    incrementForehandCountAndUpdateDelegate()
                } else if (modelPrediction! == "backhand") {
                    incrementBackhandCountAndUpdateDelegate()
                }
            }
            
            
        }
        
       
//        let accumulatedYawRot = rateAlongGravityBuffer.sum() * ModelConstants.sensorsUpdateInterval
//        let peakRate = accumulatedYawRot > 0 ?
//            rateAlongGravityBuffer.max() : rateAlongGravityBuffer.min()
//
//        if (accumulatedYawRot < -yawThreshold && peakRate < -rateThreshold) {
//            // Counter clockwise swing.
//            if (wristLocationIsLeft) {
//                incrementBackhandCountAndUpdateDelegate()
//            } else /*if (!wristLocationIsLeft && prediction.label == "forehand")*/{
//                incrementForehandCountAndUpdateDelegate()
//            }
//        } else if (accumulatedYawRot > yawThreshold && peakRate > rateThreshold) {
//            // Clockwise swing.
//            if (wristLocationIsLeft) {
//                incrementForehandCountAndUpdateDelegate()
//            } else /*if (!wristLocationIsLeft && prediction.label == "backhand")*/ {
//                incrementBackhandCountAndUpdateDelegate()
//            }
//        }
//
//        // Reset after letting the rate settle to catch the return swing.
//        if (recentDetection && abs(rateAlongGravityBuffer.recentMean()) < resetThreshold) {
//
////            guard let prediction = try? model.prediction(acc_x: convertToMLArray(accelerationXBuffer.buffer), acc_y: convertToMLArray(accelerationYBuffer.buffer), acc_z: convertToMLArray(accelerationZBuffer.buffer), rot_x: convertToMLArray(rotationXBuffer.buffer), rot_y: convertToMLArray(rotationYBuffer.buffer), rot_z: convertToMLArray(rotationZBuffer.buffer), stateIn: nil) else {
////                          return
////                      }
////
////                      print("Predicted class: \(prediction.label)  \(prediction.labelProbability)" )
//
//
//            recentDetection = false
//            rateAlongGravityBuffer.reset()
//
//
//
//                 rotationXBuffer.reset()
//                 rotationYBuffer.reset()
//                 rotationZBuffer.reset()
//
//                 accelerationXBuffer.reset()
//                 accelerationYBuffer.reset()
//                 accelerationZBuffer.reset()
//        }
    }

    // MARK: Data and Delegate Management
    
    func resetAllState() {
        rateAlongGravityBuffer.reset()
    
        rotationXBuffer.reset()
        rotationYBuffer.reset()
        rotationZBuffer.reset()
        
        accelerationXBuffer.reset()
        accelerationYBuffer.reset()
        accelerationZBuffer.reset()
        
        gravityXBuffer.reset()
        gravityYBuffer.reset()
        gravityZBuffer.reset()
    
        forehandCount = 0
        backhandCount = 0
        recentDetection = false

        updateForehandSwingDelegate()
        updateBackhandSwingDelegate()
    }

    func incrementForehandCountAndUpdateDelegate() {
//        if (!recentDetection) {
            forehandCount += 1
            recentDetection = true

//            print("Forehand swing. Count: \(forehandCount)")
            updateForehandSwingDelegate()
//        }
    }

    func incrementBackhandCountAndUpdateDelegate() {
//        if (!recentDetection) {
            backhandCount += 1
            recentDetection = true

//            print("Backhand swing. Count: \(backhandCount)")
            updateBackhandSwingDelegate()
//        }
    }

    func updateForehandSwingDelegate() {
        delegate?.didUpdateForehandSwingCount(self, forehandCount:forehandCount)
    }

    func updateBackhandSwingDelegate() {
        delegate?.didUpdateBackhandSwingCount(self, backhandCount:backhandCount)
    }
    
    func convertToMLArray(_ input: [Double]) -> MLMultiArray {

        let mlArray = try? MLMultiArray(shape: [100], dataType: MLMultiArrayDataType.double)


        for i in 0..<input.count {
            mlArray?[i] = NSNumber(value: input[i])
        }


        return mlArray!
    }
    
    func performModelPrediction () -> String? {
        

        guard let prediction = try? model.prediction(acc_x: convertToMLArray(accelerationXBuffer.buffer), acc_y: convertToMLArray(accelerationYBuffer.buffer), acc_z: convertToMLArray(accelerationZBuffer.buffer),giro_x: convertToMLArray(gravityXBuffer.buffer), giro_y: convertToMLArray(gravityYBuffer.buffer), giro_z: convertToMLArray(gravityZBuffer.buffer), rot_x: convertToMLArray(rotationXBuffer.buffer), rot_y: convertToMLArray(rotationYBuffer.buffer), rot_z: convertToMLArray(rotationZBuffer.buffer), stateIn: nil)
        else {
                return "N/A"
        }
                                   
//        print("Predicted class:  \(prediction.labelProbability)" )
    
        let predictPercent = prediction.labelProbability[prediction.label]
        
        if (Double(0.4).isLess(than: predictPercent!)) {
            return prediction.label
        } else {
            return "none"
        }
        
        
//        // Return the predicted activity - the activity with the highest probability
//        return prediction.label
    }
}
