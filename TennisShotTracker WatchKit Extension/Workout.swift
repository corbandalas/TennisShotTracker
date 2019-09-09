//
//  Workout.swift
//  TennisShotTracker WatchKit Extension
//
//  Created by Artyom Tereshchenko on 07.09.2019.
//  Copyright © 2019 Artyom Tereshchenko. All rights reserved.
//

import Foundation

struct Workout: Codable {
    
    var date:Date
    var workoutInterval: TimeInterval
    var calBurned: Double
    var distance: Double
    var forehandSpinCount: Int
    var forehandSliceCount: Int
    var forehandVolleyCount: Int
    var backhandSpinCount: Int
    var backhandSliceCount: Int
    var backhandVolleyCount: Int
    var single_handed_backhandCount: Int
    var serveCount: Int
    var totalShots: Int
    var maxServeSpeed: Double
    var maxShotSpeed: Double
    var minServeSpeed: Double
    var minShotSpeed: Double
    var averageShotSpeed: Double
    var averageServeSpeed: Double
    
    
    
}
