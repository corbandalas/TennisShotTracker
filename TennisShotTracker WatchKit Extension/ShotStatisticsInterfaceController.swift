//
//  ShotStatisticsInterfaceController.swift
//  TennisShotTracker WatchKit Extension
//
//  Created by Artyom Tereshchenko on 05.09.2019.
//  Copyright © 2019 Artyom Tereshchenko. All rights reserved.
//

import WatchKit
import Foundation


class ShotStatisticsInterfaceController: WKInterfaceController {

    var workout: Workout? = nil
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
       if let workoutString = context as? String {
        
          workout = try! JSONDecoder().decode(Workout.self, from: workoutString.data(using: .utf8)!)
        }
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    override init() {
        super.init()
        
       
      
    }

}
