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

class InterfaceController: WKInterfaceController, WorkoutManagerDelegate {
    // MARK: Properties


    @IBAction func startWorkOut() {
                titleLabel.setText("Workout started")
                       workoutManager.startWorkout()
    }
    
    @IBAction func stopWorkOut() {
        
         titleLabel.setText("Workout stopped")
                workoutManager.stopWorkout()
    }
    
    let workoutManager = WorkoutManager()
    var active = false
    var forehandCount = 0
    var backhandCount = 0

    @IBOutlet weak var titleLabel: WKInterfaceLabel!
    @IBOutlet weak var backhandCountLabel: WKInterfaceLabel!
    @IBOutlet weak var forehandCountLabel: WKInterfaceLabel!
    
    
    @IBOutlet weak var predictedShotLabel: WKInterfaceLabel!
    // MARK: Interface Properties
    
//    @IBOutlet weak var titleLabel: WKInterfaceLabel!
//    @IBOutlet weak var backhandCountLabel: WKInterfaceLabel!
//    @IBOutlet weak var forehandCountLabel: WKInterfaceLabel!

//    @IBOutlet weak var titleLabel: WKInterfaceLabel!
//    @IBOutlet weak var backhandCountLabel: WKInterfaceLabel!
//    @IBOutlet weak var forehandCountLabel: WKInterfaceLabel!
    // MARK: Initialization
    
    override init() {
        super.init()
        
        workoutManager.delegate = self
    }

    // MARK: WKInterfaceController
    
    override func willActivate() {
        super.willActivate()
        active = true

        // On re-activation, update with the cached values.
        updateLabels()
    }

    override func didDeactivate() {
        super.didDeactivate()
        active = false
    }

    // MARK: Interface Bindings
    
   
//    @IBAction func startWorkout() {
//        titleLabel.setText("Workout started")
//               workoutManager.startWorkout()
//    }
//    @IBAction func stopWorkout() {
//        titleLabel.setText("Workout stopped")
//        workoutManager.stopWorkout()
//    }
//    
    

    // MARK: WorkoutManagerDelegate
    
    func didUpdateForehandSwingCount(_ manager: WorkoutManager, forehandCount: Int) {
        /// Serialize the property access and UI updates on the main queue.
        DispatchQueue.main.async {
            self.forehandCount = forehandCount
            self.updateLabels()
        }
    }

    func didUpdateBackhandSwingCount(_ manager: WorkoutManager, backhandCount: Int) {
        /// Serialize the property access and UI updates on the main queue.
        DispatchQueue.main.async {
            self.backhandCount = backhandCount
            self.updateLabels()
        }
    }

    // MARK: Convenience
    
    func updateLabels() {
        if active {
            forehandCountLabel.setText("\(forehandCount)")
            backhandCountLabel.setText("\(backhandCount)")
        }
    }

}
