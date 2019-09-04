//
//  InterfaceController.swift
//  TennisTracker WatchKit Extension
//
//  Created by Artyom Tereshchenko on 09.08.2019.
//  Copyright © 2019 Artyom Tereshchenko. All rights reserved.
//

import WatchKit
import Foundation


import WatchKit
import Foundation
import Dispatch
import HealthKit

class InterfaceController: WKInterfaceController,  HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate, MotionManagerDelegate {

    var active = false

    let healthStore = HKHealthStore()
    var configuration: HKWorkoutConfiguration!
    var session: HKWorkoutSession!
    var builder: HKLiveWorkoutBuilder!
   

    var forehandCount = 0
    var backhandCount = 0


    @IBOutlet weak var timer: WKInterfaceTimer!
    @IBOutlet weak var activeCaloriesLabel: WKInterfaceLabel!
    @IBOutlet weak var heartRateLabel: WKInterfaceLabel!
    @IBOutlet weak var distanceLabel: WKInterfaceLabel!
    
    @IBOutlet weak var forehandCountLabel: WKInterfaceLabel!
    @IBOutlet weak var backhandCountLabel: WKInterfaceLabel!
    override init() {
        super.init()
        
//        workoutManager.delegate = self
        setupMenuItemsForWorkoutSessionState(.notStarted)
       MotionManager.shared.delegate = self
      
    }

    // MARK: WKInterfaceController
    
    override func willActivate() {
        super.willActivate()
        active = true
       
      
    }

    override func didDeactivate() {
        super.didDeactivate()
        active = false
        
    }
    
    override func didAppear() {
        super.didAppear()
        
    }
    
    override func willDisappear() {
        super.didAppear()
        
    }
    

    
    /// Set up the contextual menu based on the workout session state.
    func setupMenuItemsForWorkoutSessionState(_ state: HKWorkoutSessionState) {
           clearAllMenuItems()
        
        if state == .notStarted {
            addMenuItem(with: .play, title: "Start", action: #selector(startWorkoutAction))
        }
        
        if state == .running {
               addMenuItem(with: .pause, title: "Pause", action: #selector(pauseWorkoutAction))
        } else if state == .paused {
               addMenuItem(with: .resume, title: "Resume", action: #selector(resumeWorkoutAction))
        }
        addMenuItem(with: .decline, title: "End", action: #selector(endWorkoutAction))
    }
       
       /// Action for the "Pause" menu item.
    @objc
       func pauseWorkoutAction() {
           pauseWorkout()
    }
       
       /// Action for the "Resume" menu item.
    @objc
    func resumeWorkoutAction() {
           resumeWorkout()
    }
       
       /// Action for the "End" menu item.
    @objc
    func endWorkoutAction() {
           endWorkout()
    }
    
    @objc
    func startWorkoutAction() {
           startWorkout()
    }
    
    // MARK: - State Control
       func pauseWorkout() {
           session.pause()
           setupMenuItemsForWorkoutSessionState(.paused)
        MotionManager.shared.stopUpdates()
       }
       
       func resumeWorkout() {
           session.resume()
           setupMenuItemsForWorkoutSessionState(.running)
        MotionManager.shared.startUpdates()
       }
       
       func endWorkout() {
           /// Update the timer based on the state we are in.
           /// - Tag: SaveWorkout
           session.end()
           MotionManager.shared.stopUpdates()
           builder.endCollection(withEnd: Date()) { (success, error) in
               self.builder.finishWorkout { (workout, error) in
                   // Dispatch to main, because we are updating the interface.
                   DispatchQueue.main.async() {
//                       self.dismiss()
//                    self.titleLabel.setText("Workout stopped")
                    self.timer.stop()
                    self.setupMenuItemsForWorkoutSessionState(.notStarted)
                   }
               }
           }
       }
    
    func startWorkout() {
        
//        titleLabel.setText("Workout started")
        
//        // If we have already started the workout, then do nothing.
//        if (session != nil) {
//            return
//        }
                
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
        session.delegate = self
        builder.delegate = self
                
        
        
        let dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)

        if let hr = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            dataSource.enableCollection(for: hr, predicate: nil)
        }
        if let distance = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) {
            dataSource.enableCollection(for: distance, predicate: nil)
        }

        if let activeEnergyBurned = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            dataSource.enableCollection(for: activeEnergyBurned, predicate: nil)
        }
        
        builder.dataSource = dataSource
        
        /// Set the workout builder's data source.
        // - Tag: SetDataSource
//        builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
//                                                             workoutConfiguration: configuration)
                
        // Start the workout session and begin data collection.
        // - Tag: StartSession
        session.startActivity(with: Date())
        builder.beginCollection(withStart: Date()) { (success, error) in
            self.setDurationTimerDate(.running)
        }
        MotionManager.shared.startUpdates()
        
        setupMenuItemsForWorkoutSessionState(.running)
    }


  
    
  

    // MARK: Convenience
    
   
    
    func setDurationTimerDate(_ sessionState: HKWorkoutSessionState) {
        /// Obtain the elapsed time from the workout builder.
        /// - Tag: ObtainElapsedTime
        let timerDate = Date(timeInterval: -self.builder.elapsedTime, since: Date())
        
        // Dispatch to main, because we are updating the interface.
        DispatchQueue.main.async {
            self.timer.setDate(timerDate)
        }
        
        // Dispatch to main, because we are updating the interface.
        DispatchQueue.main.async {
            /// Update the timer based on the state we are in.
            /// - Tag: UpdateTimer
            sessionState == .running ? self.timer.start() : self.timer.stop()
        }
    }
    
    /// Update the WKInterfaceLabels with new data.
    func updateLabel(_ label: WKInterfaceLabel?, withStatistics statistics: HKStatistics?) {
        // Make sure we got non `nil` parameters.
        guard let label = label, let statistics = statistics else {
            return
        }
        
        // Dispatch to main, because we are updating the interface.
//        DispatchQueue.main.async {
            switch statistics.quantityType {
            case HKQuantityType.quantityType(forIdentifier: .heartRate):
                /// - Tag: SetLabel
                let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                let value = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit)
                let roundedValue = Double( round( 1 * value! ) / 1 )
                label.setText("\(roundedValue)")
            case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
                let energyUnit = HKUnit.kilocalorie()
                let value = statistics.sumQuantity()?.doubleValue(for: energyUnit)
                let roundedValue = Double( round( 1 * value! ) / 1 )
                label.setText("\(roundedValue)")
                return
            case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning):
                let meterUnit = HKUnit.meter()
                let value = statistics.sumQuantity()?.doubleValue(for: meterUnit)
                let roundedValue = Double( round( 1 * value! ) / 1 )
                label.setText("\(roundedValue)")
                return
            default:
                return
            }
//        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        
    }
    
  // MARK: - HKLiveWorkoutBuilderDelegate
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else {
                return // Nothing to do.
            }
            
            /// - Tag: GetStatistics
            let statistics = workoutBuilder.statistics(for: quantityType)
            let label = labelForQuantityType(quantityType)
            
            updateLabel(label, withStatistics: statistics)
        }
    }
    
    /// Retreive the WKInterfaceLabel object for the quantity types we are observing.
       func labelForQuantityType(_ type: HKQuantityType) -> WKInterfaceLabel? {
           switch type {
           case HKQuantityType.quantityType(forIdentifier: .heartRate):
               return heartRateLabel
           case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
               return activeCaloriesLabel
           case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning):
               return distanceLabel
           default:
               return nil
           }
       }
    
     // Track elapsed time.
       func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
           // Retreive the workout event.
           guard let workoutEventType = workoutBuilder.workoutEvents.last?.type else { return }
           
           // Update the timer based on the event received.
           switch workoutEventType {
           case .pause: // The user paused the workout.
               setDurationTimerDate(.paused)
           case .resume: // The user resumed the workout.
               setDurationTimerDate(.running)
            
           default:
               return
               
           }
       }
    
    func updateLabels() {
           if active {
               forehandCountLabel.setText("\(forehandCount)")
               backhandCountLabel.setText("\(backhandCount)")
           }
    }
    
      func didUpdateForehandSwingCount(_ manager: MotionManager, forehandCount: Int) {
               /// Serialize the property access and UI updates on the main queue.
                     DispatchQueue.main.async {
                         self.forehandCount = forehandCount
                         self.updateLabels()
                     }
          }
          
          func didUpdateBackhandSwingCount(_ manager: MotionManager, backhandCount: Int) {
              /// Serialize the property access and UI updates on the main queue.
              DispatchQueue.main.async {
                  self.backhandCount = backhandCount
                  self.updateLabels()
              }
          }

}
