//
//  TennisShotStatisticsController.swift
//  TennisShotTracker WatchKit Extension
//
//  Created by Artyom Tereshchenko on 03.09.2019.
//  Copyright © 2019 Artyom Tereshchenko. All rights reserved.
//

import WatchKit
import Foundation


class TennisShotStatisticsController: WKInterfaceController, MotionManagerDelegate {
    
    var forehandCount = 0
    var backhandCount = 0
    var active = false
    

    @IBOutlet weak var foreHandCount: WKInterfaceLabel!
    
    @IBOutlet weak var backHandCount: WKInterfaceLabel!
    
     override init() {
            super.init()
            
    //        workoutManager.delegate = self
//            setupMenuItemsForWorkoutSessionState(.notStarted)
        MotionManager.shared.delegate = self
        }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }

    override func willActivate() {
        super.willActivate()
        active = true
        print("TennisShotStatisticsController willActivate active=\(active)")
        
        updateLabels()
      
    }

    override func didDeactivate() {
        super.didDeactivate()
        active = false
        print("TennisShotStatisticsController didDeactivate active=\(active)")
    }
    
    override func didAppear() {
        super.didAppear()
        print("TennisShotStatisticsController didAppear active=\(active)")
        
    }
    
    override func willDisappear() {
        super.didAppear()
        print("TennisShotStatisticsController willDisappear active=\(active)")
    }
    
    func updateLabels() {
           if active {
                print("TennisShotStatisticsController updateLabels active=\(active)")
               foreHandCount.setText("\(forehandCount)")
               backHandCount.setText("\(backhandCount)")
           }
    }
    
    func didUpdateForehandSwingCount(_ manager: MotionManager, forehandCount: Int) {
           /// Serialize the property access and UI updates on the main queue.
//                 DispatchQueue.main.async {
                     self.forehandCount = forehandCount
                     self.updateLabels()
//                 }
      }
      
      func didUpdateBackhandSwingCount(_ manager: MotionManager, backhandCount: Int) {
          /// Serialize the property access and UI updates on the main queue.
//          DispatchQueue.main.async {
              self.backhandCount = backhandCount
              self.updateLabels()
//          }
      }

}
