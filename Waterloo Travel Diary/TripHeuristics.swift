//
//  TripHeuristics.swift
//  Waterloo Travel Diary
//
//  Created by Eddy on 2020-09-26.
//  Copyright © 2020 Eddy. All rights reserved.
//

import Foundation
import CoreLocation
import CoreMotion
import os.log

/*
 * While easier to do, constantly recording a user's location using
 * GPS drains their battery to the tune of 5-15% an hour depending on
 * the age and model of their iPhone.
 *
 * This class encodes all logic pertaining to deciding the accuracy of
 * location tracking as to conserve battery life.
 *
 * The trade-off is between battery life and the accuracy of locations,
 * which is important since the data collected is being used to determine
 * user activities, their mode of transportation, and their route choice
 * if walking or cycling.
 *
 * Based on the above trade-off, there are some scenarios where location
 * accuracy can be reduced, namely when the user isn't moving and when
 * they're moving very quickly (ie. on the highway or train).
 *
 */
class TripHeuristics {
    
    let currentScenario = Scenario.activelyMoving
    
    // Represents the radius a user needs to travel outside of until they
    // are considered to be travelling while in the stopped state.
    // Because GPS location accuracy is 100m in this state a radius of at
    // least 200 metres (about a 3-minute walk) should be used.
    // Used by userTravelling (stopped -> activelyMoving).
    let defaultStartedTravellingDistanceMetres = 250

    // Represents the length of time in which there had to be a non-stationary
    // motion activity in at least half of the recentmost minutes for the user
    // to be considered to be moving. For example, there was a non-stationary motion
    // in the last 5 minutes or in every other minute, when the value is set to 10.
    // Used by userMoving (notMoving -> stopped).
    let defaultStartedMovingMinutes = 10
    
    // Represents the length of time in which there had to be stationary motion
    // activity for the entire duration.
    // Used by userStationary ( -> notMoving).
    let defaultStoppedMovingStationaryMinutes = 15
    
    // Represents the radius a user needs to stay inside of for a certain length
    // of time until they are considered to no longer be travelling (ie. are walking
    // around a grocery store, school, or office).
    // Because location accuracy is set to 10 metres in activelyMoving, a smaller radius
    // can be used although it should be at least 50 metres.
    let defaultSameLocationDistanceMetres = 100
    // Corresponding length of time for defaultSameLocationDistanceMetres
    // Used by userNotTravelling (activelyMoving -> stopped).
    let defaultStopMovingSameLocationMinutes = 15
    
    // Represents the minimum speed required for the user to be considered
    // to be moving in a fast vehicle (along with the motion activity being
    // in a vehicle).
    let defaultFastSpeedKmh = 80
    // Represents the length of time in which there was either in-vehicle
    // or stationary motion for the entire duration.
    // Used by userInFastVehicle (activelyMoving -> inFastVehicle).
    let defaultInVehicleOrStationaryMinutes = 5
    
    // Represents the length of time in which only forms of active transportation
    // (walking/cycling/running) were used in the past few minutes.
    // Used by userActivelyMoving (inFastVehicle -> activelyMoving).
    let defaultActivelyMovingMinutes = 2
    
    
    var lastAccurateActiveLocation: CLLocation? = nil
    var recentmostActiveMotionTime: Date? = nil
    var recentmostStationaryMotionTime: Date? = nil
    var recentmostInVehicleMotionTime: Date? = nil
    
    // State representing the user's scenario based on motion activity and location tracking.
    enum Scenario {
        case activelyMoving
        case stopped
        case notMoving
        case inFastVehicle
    }
    
    func getLocationAccuracy(scenario: Scenario) -> CLLocationAccuracy {
        switch(scenario) {
        case .activelyMoving:
            return kCLLocationAccuracyNearestTenMeters // relies on GPS data.
        case .stopped:
            // In urban areas relies on cell tower and WiFi data, may use GPS if needed but to a lower accuracy.
            return kCLLocationAccuracyHundredMeters
        case .notMoving:
            return kCLLocationAccuracyThreeKilometers // relies on cell tower and WiFi data, possibly GPS in remote areas.
        case .inFastVehicle:
            return kCLLocationAccuracyKilometer // relies on cell tower and WiFi data, possibly GPS in remote areas.
        }
    }
    
    // Implement Transition Functions
    
    func userStationary() -> Bool {
        /* Determine if the user has not been moving for a while, more specifically has been
         * stationary for a certain length of time. */
        if (recentmostStationaryMotionTime == nil) {
            return false
        }
        if (recentmostActiveMotionTime == nil || Int(recentmostStationaryMotionTime!.timeIntervalSince(
            recentmostActiveMotionTime!)) < defaultStoppedMovingStationaryMinutes*60) {
            return false
        }
        if (recentmostInVehicleMotionTime == nil || Int(recentmostStationaryMotionTime!.timeIntervalSince(
            recentmostInVehicleMotionTime!)) < defaultStoppedMovingStationaryMinutes*60) {
            return false
        }
        return true
    }
    
    func userMoving() -> Bool {
        /* Determine if the user has started moving after having been stationary for a while, more
         * specifically, has been non-stationary at one point in the past few minutes. */
        // TODO - increase strictness for non-stationary at one point during the last N minutes
        if (recentmostStationaryMotionTime == nil) {
            return true
        }
        if (recentmostActiveMotionTime != nil && Int(recentmostActiveMotionTime!.timeIntervalSince(
            recentmostStationaryMotionTime!)) >= defaultStartedMovingMinutes*60) {
            return true
        }
        if (recentmostInVehicleMotionTime != nil && Int(recentmostInVehicleMotionTime!.timeIntervalSince(
            recentmostStationaryMotionTime!)) >= defaultStartedMovingMinutes*60) {
            return true
        }
        return false
    }
    
    func userTravelling() -> Bool {
        return false
    }
    
    func userNotTravelling() -> Bool {
        return false
    }
    
    func userInFastVehicle() -> Bool {
        return false
    }
    
    func userActivelyMoving() -> Bool {
        return false
    }

    // Update State

    func updateLocationAccuracy(recentmostLocation: CLLocation?, recentmostMotionActivity: CMMotionActivity?) {
        var newScenario = currentScenario
        if (currentScenario == .activelyMoving) {
            // Implementing #1
            if (userStationary()) {
                newScenario = .notMoving
            }
            // Implementing #2
            if (userInFastVehicle()) {
                newScenario = .inFastVehicle
            }
        }
        // Revert from #1
        if (currentScenario == .notMoving) {
            if (userMoving()) {
                newScenario = .stopped
            }
        }
        if (currentScenario == .stopped) {
            
        }
        // Revert from #2
        if (currentScenario == .inFastVehicle) {
            
        }
    }
    
}
