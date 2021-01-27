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
    
    var currentScenario = Scenario.activelyMoving
    
    // Represents the radius a user needs to travel outside of until they
    // are considered to be travelling while in the stopped state.
    // Because GPS location accuracy is 100m in this state a radius of at
    // least 200 metres (about a 3-minute walk) should be used.
    // Used by userTravelling (stopped -> activelyMoving).
    let defaultStartedTravellingDistanceMetres = 250
    
    // Represents the length of time in which there had to be stationary motion
    // activity for the entire duration.
    // Used by userStationary ( -> notMoving).
    let defaultStoppedMovingStationarySeconds = 600
    
    // Represents the radius a user needs to stay inside of for a certain length
    // of time until they are considered to no longer be travelling (ie. are walking
    // around a grocery store, school, or office).
    // Because location accuracy is set to 10 metres in activelyMoving, a smaller radius
    // can be used although it should be at least 50 metres.
    let defaultSameLocationDistanceMetres = 100
    // Corresponding length of time for defaultSameLocationDistanceMetres
    // Used by userNotTravelling (activelyMoving -> stopped).
    let defaultStopMovingSameLocationSeconds = 15*60
    
    // Represents the minimum speed required for the user to be considered
    // to be moving in a fast vehicle (along with the motion activity being
    // in a vehicle).
    let defaultFastSpeedKmh = 80
    // Represents the length of time in which there was either in-vehicle
    // or stationary motion for the entire duration.
    // Used by userInFastVehicle (activelyMoving -> inFastVehicle).
    let defaultInVehicleOrStationarySeconds = 300
    
    // Represents the length of time in which only forms of active transportation
    // (walking/cycling/running) were used in the past few minutes.
    // This value should be long enough to exclude someone picking up their phone
    // but short enough to invoke as it requires someone to move continously.
    // Used by userMoving (inFastVehicle -> activelyMoving and notMoving -> stopped).
    let defaultActivelyMovingSeconds = 20
    
    
    var lastActivelyMovingLocation: CLLocation? = nil
    // All locations recorded under the ActivelyMoving state except for the recentmost one.
    var lastActivelyMovingLocations: [CLLocation] = []
    // Get recent locations (anything between now and now-recentmostSeconds) to decide
    // whether to transition from activelyMoving to stopped.
    private func getLastActivelyMovingLocations(recentmostSeconds: Int) -> [CLLocation] {
        var lastActivelyMovingLocations: [CLLocation] = []

        // Whether the current data covers the full range of recentmostSeconds.
        var recentmostSecondsCoversFullDuration = false

        for location in lastActivelyMovingLocations {
            // Ensure only accurate activelyMoving locations are used.
            if location.horizontalAccuracy <= CLLocationAccuracy(20)
                && location.timestamp.timeIntervalSinceNow <= TimeInterval(recentmostSeconds) {
                lastActivelyMovingLocations.append(location)
            }
            if location.timestamp.timeIntervalSinceNow >= TimeInterval(recentmostSeconds) {
                recentmostSecondsCoversFullDuration = true
            }
        }
        
        if !recentmostSecondsCoversFullDuration {
            return [] // Do not yet have sufficient data based on recentmostSeconds so return an empty list.
        }
        return lastActivelyMovingLocations
    }
    // Used to determine whether there was consistent fast vehicle, stationary, or active motion (not states).
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
    
    private func getLocationAccuracy(scenario: Scenario) -> CLLocationAccuracy {
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
    
    private func userStationary() -> Bool {
        // -> notMoving
        /* Determine if the user has not been moving for a while, more specifically has been
         * stationary for a certain length of time. This is done by checking whether there has been
         * a more recent active or in-vehicle motion.
         */
        if recentmostStationaryMotionTime == nil {
            return false
        }
        if abs(Int(recentmostStationaryMotionTime!.timeIntervalSinceNow)) > defaultStoppedMovingStationarySeconds {
            // Return false as there was no stationary activity within threshold period.
            return false
        }
        if recentmostActiveMotionTime == nil {
            // Ensure that the stationary time threshold is greater than the duration of the trip so far.
            return false
        }
        if abs(Int(recentmostActiveMotionTime!.timeIntervalSinceNow)) < defaultStoppedMovingStationarySeconds {
            return false
        }
        if recentmostInVehicleMotionTime != nil {
            if abs(Int(recentmostInVehicleMotionTime!.timeIntervalSinceNow)) < defaultStoppedMovingStationarySeconds {
                return false
            }
        }
        return true
    }
    
    private func userTravelling(currentLocation: CLLocation) -> Bool {
        // stopped -> activelyMoving
        if lastActivelyMovingLocation == nil {
            return false
        }
        if abs(Int(currentLocation.distance(from: lastActivelyMovingLocation!))) >= defaultStartedTravellingDistanceMetres {
            return true
        }
        return false
    }
    
    private func userNotTravelling() -> Bool {
        // activelyMoving -> stopped
        let lastActivelyMovingLocations = getLastActivelyMovingLocations(
            recentmostSeconds: defaultStopMovingSameLocationSeconds
        )
        if lastActivelyMovingLocations.count == 0 {
            // Keep activelyMoving as we don't have enough data to tell whether user is stopped.
            return false
        }
        // Assume that all recent locations are in the radius unless otherwise.
        var allLocationsWithinRadius = true
        for location in lastActivelyMovingLocations {
            if lastActivelyMovingLocation == nil {
                continue
            }
            if abs(Int(location.distance(from: lastActivelyMovingLocation!))) > defaultSameLocationDistanceMetres {
                allLocationsWithinRadius = false
                break
            }
        }
        return allLocationsWithinRadius
    }
    
    private func userInFastVehicle(currentLocation: CLLocation) -> Bool {
        // activelyMoving -> inFastVehicle
        // Detect whether user is in a fast-moving vehicle based on both speed and motion inputs.
        // 3.6 is multiplier from m/s -> km/h.
        if Int(currentLocation.speed * 3.6) >= defaultFastSpeedKmh
            // Speed accuracy within 25% of fast speed threshold.
            && currentLocation.speedAccuracy <=
            CLLocationAccuracy(Double(defaultFastSpeedKmh) / 3.6 * 0.25) {
            if recentmostInVehicleMotionTime != nil &&
                abs(Int(recentmostInVehicleMotionTime!.timeIntervalSinceNow)) <= defaultInVehicleOrStationarySeconds {
                return true
            }
            if recentmostStationaryMotionTime != nil &&
                abs(Int(recentmostStationaryMotionTime!.timeIntervalSinceNow)) <= defaultInVehicleOrStationarySeconds {
                return true
            }
        }
        return false
    }

    private func userMoving() -> Bool {
        // inFastVehicle -> activelyMoving
        // notMoving -> stopped
        // Return true when only forms of active transportation (walking/cycling/running),
        // excluding breaks (ie. stationary), were used in the past few seconds defined by activelyMovingSeconds.
        if recentmostActiveMotionTime == nil {
            return false
        }
        if abs(Int(recentmostActiveMotionTime!.timeIntervalSinceNow)) > defaultActivelyMovingSeconds {
            return false
        }
        if recentmostStationaryMotionTime != nil {
            if abs(Int(recentmostStationaryMotionTime!.timeIntervalSinceNow)) < defaultActivelyMovingSeconds {
                return false
            }
        }
        if recentmostInVehicleMotionTime != nil {
            if abs(Int(recentmostInVehicleMotionTime!.timeIntervalSinceNow)) < defaultActivelyMovingSeconds {
                return false
            }
        }
        return true
    }

    // Update State
    
    private func getCurrentStateDescription(scenario: Scenario) -> String {
        switch(scenario) {
        case .activelyMoving:
            return "Actively Moving."
        case .stopped:
            return "Not travelling."
        case .notMoving:
            return "Not moving."
        case .inFastVehicle:
            return "In a fast-moving vehicle."
        }
    }

    func updateLocationAccuracy(
        recentmostLocation: CLLocation?, recentmostMotionActivity: CMMotionActivity?
    ) -> (CLLocationAccuracy, String) {
        var newScenario = currentScenario
        if recentmostMotionActivity != nil {
            if recentmostMotionActivity!.walking || recentmostMotionActivity!.cycling || recentmostMotionActivity!.running {
                recentmostActiveMotionTime = recentmostMotionActivity!.startDate
            }
            if recentmostMotionActivity!.automotive {
                recentmostInVehicleMotionTime = recentmostMotionActivity!.startDate
            }
            if recentmostMotionActivity!.stationary {
                recentmostStationaryMotionTime = recentmostMotionActivity!.startDate
            }
        }
        
        if recentmostLocation != nil {
            // See state transition map at https://github.com/EddyIonescu/Waterloo-Travel-Diary.
            if currentScenario == .activelyMoving {
                if lastActivelyMovingLocation != nil {
                    lastActivelyMovingLocations.append(lastActivelyMovingLocation!)
                }
                lastActivelyMovingLocation = recentmostLocation
                if userStationary() {
                    newScenario = .notMoving
                }
                if userNotTravelling() {
                    newScenario = .stopped
                }
                if userInFastVehicle(currentLocation: recentmostLocation!) {
                    newScenario = .inFastVehicle
                }
            }
            if currentScenario == .notMoving {
                if userMoving() {
                    newScenario = .stopped
                }
            }
            if currentScenario == .stopped {
                if userTravelling(currentLocation: recentmostLocation!) {
                    newScenario = .activelyMoving
                }
                if userStationary() {
                    newScenario = .notMoving
                }
            }
            if currentScenario == .inFastVehicle {
                if userMoving() {
                    newScenario = .activelyMoving
                }
            }
        }
        currentScenario = newScenario
        return (getLocationAccuracy(scenario: newScenario), getCurrentStateDescription(scenario: newScenario))
    }
}
