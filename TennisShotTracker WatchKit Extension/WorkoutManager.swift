/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This class manages the HealthKit interactions and provides a delegate
         to indicate changes in data.
 */

import Foundation
import HealthKit
import WatchKit

/**
 `WorkoutManagerDelegate` exists to inform delegates of swing data changes.
 These updates can be used to populate the user interface.
 */
protocol WorkoutManagerDelegate: class {
    func didUpdateForehandSwingCount(_ manager: WorkoutManager, forehandCount: Int)
    func didUpdateBackhandSwingCount(_ manager: WorkoutManager, backhandCount: Int)
}

class WorkoutManager: MotionManagerDelegate {
    // MARK: Properties
  

    weak var delegate: WorkoutManagerDelegate?
    var session: HKWorkoutSession!
    var builder: HKLiveWorkoutBuilder!
    let motionManager = MotionManager.shared
    let healthStore = HKHealthStore()
    
    
    // MARK: Initialization
    
    init() {
        motionManager.delegate = self
    }

    // MARK: WorkoutManager
    
    func startWorkout() {
        // If we have already started the workout, then do nothing.
        if (session != nil) {
            return
        }
        
        /// Requesting authorization.
        /// - Tag: RequestAuthorization
        // The quantity type to write to the health store.
        let typesToShare: Set = [
            HKQuantityType.workoutType()
        ]
               
        // The quantity types to read from the health store.
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        ]
               
        // Request authorization for those quantity types.
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
            // Handle error. No error handling in this sample project.
        }

        // Configure the workout session.
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .tennis
        workoutConfiguration.locationType = .outdoor

        
        
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: workoutConfiguration)
            builder = session.associatedWorkoutBuilder()
        } catch {
            fatalError("Unable to create the workout session!")
        }

        // Start the workout session and device motion updates.
        
        // Setup session and builder.
//        session.delegate = self
//        builder.delegate = self
        
        /// Set the workout builder's data source.
        /// - Tag: SetDataSource
//        builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
//                                                     workoutConfiguration: configuration)
        
        // Start the workout session and begin data collection.
        /// - Tag: StartSession
//        session.startActivity(with: Date())
//        builder.beginCollection(withStart: Date()) { (success, error) in
//            self.setDurationTimerDate(.running)
//        }
        motionManager.startUpdates()
    }

    func stopWorkout() {
        // If we have already stopped the workout, then do nothing.
        if (session == nil) {
            return
        }

        // Stop the device motion updates and workout session.
        motionManager.stopUpdates()
//        healthStore.end(session!)

        session?.end()
        
        // Clear the workout session.
        session = nil
    }

    // MARK: MotionManagerDelegate
    
    func didUpdateForehandSwingCount(_ manager: MotionManager, forehandCount: Int) {
        delegate?.didUpdateForehandSwingCount(self, forehandCount: forehandCount)
    }

    func didUpdateBackhandSwingCount(_ manager: MotionManager, backhandCount: Int) {
        delegate?.didUpdateBackhandSwingCount(self, backhandCount: backhandCount)
    }
}
