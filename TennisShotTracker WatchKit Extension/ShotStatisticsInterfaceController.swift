//
//  ShotStatisticsInterfaceController.swift
//  TennisShotTracker WatchKit Extension
//
//  Created by Artyom Tereshchenko on 05.09.2019.
//  Copyright © 2019 Artyom Tereshchenko. All rights reserved.
//

import WatchKit
import Foundation
import YOChartImageKit


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
    
    @IBOutlet weak var chartImage: WKInterfaceImage!
    
    @IBOutlet weak var minShotSpeedLabel: WKInterfaceLabel!
    @IBOutlet weak var maxShotSpeedLabel: WKInterfaceLabel!
    

    @IBOutlet weak var avgShotSpeedLabel: WKInterfaceLabel!

    
    @IBOutlet weak var avgServeSpeedLabel: WKInterfaceLabel!
    
    @IBOutlet weak var maxServeSpeedLabel: WKInterfaceLabel!
    @IBOutlet weak var minServeSpeedLabel: WKInterfaceLabel!
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
        
        let roundedMinShotSpeed = roundf(Float(workout!.minShotSpeed * 100) / 100)
        let roundedMaxShotSpeed = roundf(Float(workout!.maxShotSpeed * 100) / 100)
        let roundedMinServeSpeed = roundf(Float(workout!.minServeSpeed * 100) / 100)
        let roundedMaxServeSpeed = roundf(Float(workout!.maxServeSpeed * 100) / 100)
        let roundedAverageShotSpeed = roundf(Float(workout!.averageShotSpeed * 100) / 100)
        let roundedAverageServeSpeed = roundf(Float(workout!.averageServeSpeed * 100) / 100)
        
        minShotSpeedLabel.setText("\(roundedMinShotSpeed) km/h")
        maxShotSpeedLabel.setText("\(roundedMaxShotSpeed) km/h")
        minServeSpeedLabel.setText("\(roundedMinServeSpeed) km/h")
        maxServeSpeedLabel.setText("\(roundedMaxServeSpeed) km/h")
        avgShotSpeedLabel.setText("\(roundedAverageShotSpeed) km/h")
        avgServeSpeedLabel.setText("\(roundedAverageServeSpeed) km/h")
        totalShotsLabel.setText("\(workout!.totalShots)")
        
        let image = YODonutChartImage()
        image.donutWidth = 16.0                           // width of donut
      
        if (workout!.totalShots > 0) {
            // [optional] center label color
                   image.values = [NSNumber(value: Double(workout!.forehandSpinCount) / Double(workout!.totalShots)), NSNumber(value: Double(workout!.forehandSliceCount) / Double(workout!.totalShots)), NSNumber(value: Double(workout!.backhandSpinCount) / Double(workout!.totalShots)),
                   NSNumber(value: Double(workout!.backhandSliceCount) / Double(workout!.totalShots)),
                    NSNumber(value: Double(workout!.single_handed_backhandCount) / Double(workout!.totalShots))
                   ]                 // chart values
            

                   image.colors =  [
                    UIColor.init(cgColor: #colorLiteral(red: 0, green: 0.9768045545, blue: 0, alpha: 1)), UIColor.init(cgColor: #colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1)), UIColor.init(cgColor: #colorLiteral(red: 0.4392156899, green: 0.01176470611, blue: 0.1921568662, alpha: 1)), UIColor.init(cgColor: #colorLiteral(red: 0, green: 0.9914394021, blue: 1, alpha: 1)), UIColor.init(cgColor: #colorLiteral(red: 1, green: 0.2527923882, blue: 1, alpha: 1))]// colors of pieces
                   
                   let frame = CGRect(x: 0, y: 0, width: contentFrame.width / 3, height: contentFrame.height / 3)
                   
                   chartImage.setImage(image.draw(frame, scale: 2 * WKInterfaceDevice.current().screenScale))
        }
        
       

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
        
        formatter.dateFormat = "hh:mm dd-MM-yyyy"
        
        return formatter.string(from: date)
    }
    
    func formatTimeInterval(duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [ .hour, .minute, .second]
  
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .pad

        return formatter.string(from: duration)!
    }

}
