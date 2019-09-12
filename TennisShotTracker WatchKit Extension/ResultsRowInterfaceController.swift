//
//  ResultsRowInterfaceController.swift
//  TennisShotTracker WatchKit Extension
//
//  Created by Artyom Tereshchenko on 09.09.2019.
//  Copyright © 2019 Artyom Tereshchenko. All rights reserved.
//

import WatchKit
import Foundation


class ResultsRowInterfaceController: WKInterfaceController {

    @IBOutlet weak var table: WKInterfaceTable!
    
    fileprivate func drawTableResults() {
        let defaults = UserDefaults.standard
        
        let myArray = defaults.stringArray(forKey: "workoutResults") ?? [String]()
        
        table.setNumberOfRows(myArray.count, withRowType: "ResultsRowType")
        
        var index = 0
        
        for item in myArray {
            let row  = self.table.rowController(at: index) as! ResultsRowController
            
            let workout: Workout = try! JSONDecoder().decode(Workout.self, from: item.data(using: .utf8)!)
        
            row.data.setText(getFormattedDate(date: workout.date))
            
            row.interval.setText(formatTimeInterval(duration: workout.workoutInterval))
            
            row.distance.setText("\(workout.totalShots) shots")
            
            
            index = index + 1
        }
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        drawTableResults()
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    @IBAction func clearWorkouts() {
        let defaults = UserDefaults.standard
        
        var myArray = defaults.stringArray(forKey: "workoutResults") ?? [String]()
        
        myArray.removeAll()
        defaults.set(myArray, forKey: "workoutResults")
        
        drawTableResults()
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        
        let defaults = UserDefaults.standard
        
        let myArray = defaults.stringArray(forKey: "workoutResults") ?? [String]()
        
        let workoutString = myArray[rowIndex]
        
        presentController(withName: "showWorkoutStat", context: workoutString)
    }
    
    func getFormattedDate(date: Date) -> String {
        let formatter = DateFormatter()
        
        formatter.dateFormat = "hh:mm dd-MM-yyyy"
        
        return formatter.string(from: date)
    }
    
     func formatTimeInterval(duration: TimeInterval) -> String {
           let formatter = DateComponentsFormatter()
           formatter.allowedUnits = [.hour, .minute, .second]
     
           formatter.unitsStyle = .abbreviated
           formatter.zeroFormattingBehavior = .pad

           return formatter.string(from: duration)!
       }
}
