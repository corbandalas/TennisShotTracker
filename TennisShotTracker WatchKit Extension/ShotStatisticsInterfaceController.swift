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
    
    @IBOutlet weak var workoutDate: WKInterfaceLabel!
    @IBOutlet weak var workoutInterval: WKInterfaceLabel!
    
    @IBOutlet weak var forehandSpinCount: WKInterfaceLabel!
    @IBOutlet weak var forehandSliceCount: WKInterfaceLabel!
    @IBOutlet weak var backhandSpinCount: WKInterfaceLabel!
    @IBOutlet weak var backhandSliceCount: WKInterfaceLabel!
    @IBOutlet weak var backhandSingleCount: WKInterfaceLabel!
    @IBOutlet weak var serveCount: WKInterfaceLabel!
    
    @IBOutlet weak var workoutDistance: WKInterfaceLabel!
    
    @IBOutlet weak var totalShotsLabel: WKInterfaceLabel!
    
   
    @IBOutlet weak var minShotSpeedLabel: WKInterfaceLabel!
    @IBOutlet weak var maxShotSpeedLabel: WKInterfaceLabel!
    
    @IBOutlet weak var maxServeSpeedLabel: WKInterfaceLabel!
    @IBOutlet weak var minServeSpeedLabel: WKInterfaceLabel!
    @IBOutlet weak var avgShotSpeedLabel: WKInterfaceLabel!
    @IBOutlet weak var avgServeSpeedLabel: WKInterfaceLabel!
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
       if let workoutString = context as? String {
        
          workout = try! JSONDecoder().decode(Workout.self, from: workoutString.data(using: .utf8)!)
        }
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        workoutDate.setText(getFormattedDate(date: workout!.date))
        workoutInterval.setText(formatTimeInterval(duration: workout!.workoutInterval))
        forehandSpinCount.setText("\(workout!.forehandSpinCount)")
        forehandSliceCount.setText("\(workout!.forehandSliceCount)")
        backhandSliceCount.setText("\(workout!.backhandSliceCount)")
        backhandSpinCount.setText("\(workout!.backhandSpinCount)")
        backhandSingleCount.setText("\(workout!.single_handed_backhandCount)")
        serveCount.setText("\(workout!.serveCount)")
        workoutDistance.setText("\(workout!.distance) m")
        minShotSpeedLabel.setText("\(workout!.minShotSpeed)")
        maxShotSpeedLabel.setText("\(workout!.maxShotSpeed)")
        minServeSpeedLabel.setText("\(workout!.minServeSpeed)")
        maxServeSpeedLabel.setText("\(workout!.maxServeSpeed)")
        avgShotSpeedLabel.setText("\(workout!.averageShotSpeed)")
        avgServeSpeedLabel.setText("\(workout!.averageServeSpeed)")
        totalShotsLabel.setText("\(workout!.totalShots)")

    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    override init() {
        super.init()
        
       
      
    }
    
    func getFormattedDate(date: Date) -> String {
        let formatter = DateFormatter()
        
        formatter.dateFormat = "dd-MM-yyyy hh:mm"
        
        return formatter.string(from: date)
    }
    
    func formatTimeInterval(duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute, .second]
  
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .pad

        return formatter.string(from: duration)!
    }

}
