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
    var session: HKWorkoutSession!
    var builder: HKLiveWorkoutBuilder!
   

    var forehandSpinCount = 0
    var forehandSliceCount = 0
    var forehandVolleyCount = 0
    var backhandSpinCount = 0
    var backhandSliceCount = 0
    var backhandVolleyCount = 0
    var single_handed_backhandCount = 0
    var serveCount = 0
    
    var workoutState: HKWorkoutSessionState!
    var workoutDistance = 0.0
    var burnedCalories = 0.0
    
    @IBOutlet weak var timer: WKInterfaceTimer!
    @IBOutlet weak var activeCaloriesLabel: WKInterfaceLabel!
    @IBOutlet weak var heartRateLabel: WKInterfaceLabel!
    @IBOutlet weak var distanceLabel: WKInterfaceLabel!
    
    @IBOutlet weak var forehandSpinCountLabel: WKInterfaceLabel!
    @IBOutlet weak var forehandSliceCountLabel: WKInterfaceLabel!
    @IBOutlet weak var forehandVolleyCountLabel: WKInterfaceLabel!
    
    @IBOutlet weak var workoutStartButton: WKInterfaceButton!
    
    @IBOutlet weak var workoutStopButton: WKInterfaceButton!
    
    @IBOutlet weak var backhandSpinCountLabel: WKInterfaceLabel!
    
    @IBOutlet weak var backhandSliceCountLabel: WKInterfaceLabel!
    @IBOutlet weak var backhandVolleyCountLabel: WKInterfaceLabel!
    @IBOutlet weak var backhandSingleHandedCountLabel: WKInterfaceLabel!
    
    @IBOutlet weak var serveCountLabel: WKInterfaceLabel!
    
    override init() {
        super.init()
        
        workoutState = .notStarted


        setupMenuItemsForWorkoutSessionState(workoutState!)
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
        
        if (workoutState! == .running) {
            workoutStartButton.setTitle("Pause")
            workoutStopButton.setHidden(false)
            
        } else if (workoutState! == .paused) {
            workoutStartButton.setTitle("Resume")
            workoutStopButton.setHidden(false)
        } else if (workoutState! == .notStarted) {
            workoutStopButton.setHidden(true)
            workoutStartButton.setTitle("Start")
        }
        
        updateLabels()
        
        
//        clearAllMenuItems()
//
//        if state == .notStarted {
//            addMenuItem(with: .play, title: "Start", action: #selector(startWorkoutAction))
//        }
//
//        if state == .running {
//               addMenuItem(with: .pause, title: "Pause", action: #selector(pauseWorkoutAction))
//        } else if state == .paused {
//               addMenuItem(with: .resume, title: "Resume", action: #selector(resumeWorkoutAction))
//        }
//        addMenuItem(with: .decline, title: "End", action: #selector(endWorkoutAction))
        
        
    }
    
    @IBAction func startButtonTapped() {
        if (workoutState! == .notStarted) {
            startWorkout()
            workoutState = .running
             WKInterfaceDevice.current().play(.start)
        } else if (workoutState! == .running) {
            pauseWorkout()
            workoutState = .paused
            WKInterfaceDevice.current().play(.stop)
        } else if (workoutState! == .paused) {
            resumeWorkout()
            workoutState = .running
            WKInterfaceDevice.current().play(.start)
        }
        
        setupMenuItemsForWorkoutSessionState(workoutState!)
    }
    
    @IBAction func stopButtonTapped() {
        endWorkout()
        workoutState = .notStarted
        WKInterfaceDevice.current().play(.stop)
        setupMenuItemsForWorkoutSessionState(workoutState!)
    }
       
       /// Action for the "Pause" menu item.
    @objc func pauseWorkoutAction() {
           pauseWorkout()
    }
       
       /// Action for the "Resume" menu item.
    @objc func resumeWorkoutAction() {
           resumeWorkout()
    }
       
       /// Action for the "End" menu item.
    @objc func endWorkoutAction() {
           endWorkout()
    }
    
    @objc func startWorkoutAction() {
           startWorkout()
    }
    
    // MARK: - State Control
       func pauseWorkout() {
        session.pause()
//        setupMenuItemsForWorkoutSessionState(.paused)
        MotionManager.shared.stopUpdates()
//        updateLabels()
    }
       
       func resumeWorkout() {
           
        session.resume()
//        setupMenuItemsForWorkoutSessionState(.running)
        MotionManager.shared.startUpdates()
//        updateLabels()
    
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
                    self.saveWorkout()
//                    self.setupMenuItemsForWorkoutSessionState(.notStarted)
//                    self.updateLabels()
                   }
               }
           }
       }
    
    func startWorkout() {
        

                
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
                
        
        
        let dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: workoutConfiguration)

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
        

                
        // Start the workout session and begin data collection.
        // - Tag: StartSession
        session.startActivity(with: Date())
        builder.beginCollection(withStart: Date()) { (success, error) in
            self.setDurationTimerDate(.running)
            
        }
        
        
        forehandSpinCount = 0
        forehandSliceCount = 0
        forehandVolleyCount = 0
        backhandSpinCount = 0
        backhandSliceCount = 0
        backhandVolleyCount = 0
        single_handed_backhandCount = 0
        serveCount = 0
        
//        workoutState = .running
        
//        updateLabels()
        
        MotionManager.shared.startUpdates()
        
//        setupMenuItemsForWorkoutSessionState(.running)
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
                burnedCalories = roundedValue
                return
            case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning):
                let meterUnit = HKUnit.meter()
                let value = statistics.sumQuantity()?.doubleValue(for: meterUnit)
                let roundedValue = Double( round( 1 * value! ) / 1 )
                label.setText("\(roundedValue)")
                workoutDistance = roundedValue
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
            
          
            
                forehandSpinCountLabel.setText("\(forehandSpinCount)")
                forehandSliceCountLabel.setText("\(forehandSliceCount)")
//                forehandVolleyCountLabel.setText("\(forehandVolleyCount)")
                backhandSpinCountLabel.setText("\(backhandSpinCount)")
                backhandSliceCountLabel.setText("\(backhandSliceCount)")
//                backhandVolleyCountLabel.setText("\(backhandVolleyCount)")
                backhandSingleHandedCountLabel.setText("\(single_handed_backhandCount)")
                serveCountLabel.setText("\(serveCount)")
           }
    }
    
    func didUpdateShotCount(_ manager: MotionManager, shotType: String, count: Int) {
           /// Serialize the property access and UI updates on the main queue.
           DispatchQueue.main.async {
            
                if (shotType == "forehand_spin") {
                    self.forehandSpinCount = count
                } else if (shotType == "forehand_slice") {
                    self.forehandSliceCount = count
                } else if (shotType == "forehand_volley") {
                   self.forehandVolleyCount = count
                } else if (shotType == "backhand_spin") {
                    self.backhandSpinCount = count
                } else if (shotType == "backhand_slice") {
                    self.backhandSliceCount = count
                } else if (shotType == "backhand_volley") {
                    self.backhandVolleyCount = count
                } else if (shotType == "serve") {
                    self.serveCount = count
                } else if (shotType == "single_handed_backhand") {
                    self.single_handed_backhandCount = count
                }
            
               self.updateLabels()
           }
       }
    
    func saveWorkout() {
        
        let workoutObject = Workout(date: builder.startDate!, workoutInterval: builder.elapsedTime, calBurned: burnedCalories, distance: workoutDistance, forehandSpinCount: forehandSpinCount, forehandSliceCount: forehandSliceCount, forehandVolleyCount: forehandVolleyCount, backhandSpinCount: backhandSpinCount, backhandSliceCount: backhandSliceCount, backhandVolleyCount: backhandVolleyCount, single_handed_backhandCount: single_handed_backhandCount, serveCount: serveCount, totalShots: forehandSpinCount + forehandSliceCount + forehandVolleyCount + backhandSpinCount + backhandSliceCount + backhandVolleyCount + single_handed_backhandCount)
   
        let encodedData = try? JSONEncoder().encode(workoutObject)
        
        let defaults = UserDefaults.standard
        var myarray = defaults.stringArray(forKey: "workoutResults") ?? [String]()
             
        myarray.append(encodedData!.description)
             
        defaults.set(myarray, forKey: "workoutResults")
    }
   

}
