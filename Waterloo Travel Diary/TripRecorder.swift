//
//  TripRecorder.swift
//  Waterloo Travel Diary
//
//  Created by Eddy on 2020-01-20.
//  Copyright © 2020 Eddy. All rights reserved.
//

import Foundation
import CoreLocation
import CoreMotion
import UIKit
import os.log


let trip = TripRecorder()

class TripRecorder: NSObject, CLLocationManagerDelegate {
    
    let locationManager = CLLocationManager()
    let motionActivityManager = CMMotionActivityManager()
    var tripLocations = [CLLocation]()
    var view: UIViewController? = nil

    struct TripLocation : Codable {
        var lat: Float
        var lon: Float
        var heading: Float
        var speed: Float
        var timestamp: Int64
        var accuracy: Float
        
        static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
        static let ArchiveURL = DocumentsDirectory.appendingPathComponent("tripLocations")
    }

    private func saveTripLocations() {
        if let dataToBeArchived = try? NSKeyedArchiver.archivedData(withRootObject: tripLocations, requiringSecureCoding: true) {
            try? dataToBeArchived.write(to: TripLocation.ArchiveURL)
        }
    }

    private func loadTripLocations() -> [CLLocation]?  {
        if let archivedData = try? Data(contentsOf: TripLocation.ArchiveURL),
            let tripLocations = (try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(archivedData)) as? [CLLocation] {
            return tripLocations
        }
        return nil
    }

    static func convertToMapCoordinate(tripLocations: [TripLocation]) -> [CLLocationCoordinate2D] {
        var tripCoordinates = [CLLocationCoordinate2D]()
        for tripLocation in tripLocations {
            tripCoordinates.append(CLLocationCoordinate2D(
                latitude: CLLocationDegrees(tripLocation.lat),
                longitude: CLLocationDegrees(tripLocation.lon)
            ))
        }
        return tripCoordinates
    }

    func convertToTripLocations(tripLocations: [CLLocation]) -> [TripLocation] {
        var _tripLocations = [TripLocation]()
        for tripLocation in tripLocations {
            let _tripLocation = TripLocation(
                lat: Float(tripLocation.coordinate.latitude),
                lon: Float(tripLocation.coordinate.longitude),
                heading: Float(tripLocation.course),
                speed: Float(tripLocation.speed),
                timestamp: Int64(tripLocation.timestamp.timeIntervalSince1970),
                accuracy: Float(tripLocation.horizontalAccuracy)
            )
            _tripLocations.append(_tripLocation)
        }
        return _tripLocations
    }
    
    func startTrip(view: UIViewController? = nil) {
        if (view != nil) {
            self.view = view!
        }
        tripLocations = loadTripLocations() ?? [] // Load existing trip in progress if it exists.
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.desiredAccuracy = CLLocationAccuracy(kCLLocationAccuracyNearestTenMeters)
        locationManager.distanceFilter = CLLocationDistance(5)
     //   locationManager.startUpdatingLocation()
        locationManager.startMonitoringVisits()
        locationManager.showsBackgroundLocationIndicator = true
        if CLLocationManager.significantLocationChangeMonitoringAvailable() {
            locationManager.startMonitoringSignificantLocationChanges()
        }
        locationManager.delegate = self
        if (CMMotionActivityManager.isActivityAvailable()) {
            motionActivityManager.startActivityUpdates(to: OperationQueue.main, withHandler: handleMotionActivity)
        }
    }
    
    func stopTrip() {
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringVisits()
        locationManager.allowsBackgroundLocationUpdates = false
        if CLLocationManager.significantLocationChangeMonitoringAvailable() {
            locationManager.stopMonitoringSignificantLocationChanges()
        }
        if (CMMotionActivityManager.isActivityAvailable()) {
            motionActivityManager.stopActivityUpdates()
        }

        tripLocations = loadTripLocations() ?? []
        os_log("Stopped Trip.", log: OSLog.default, type: .info)
        if (tripLocations.count > 0) {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let currentDateTime = df.string(from: tripLocations.last!.timestamp)
            // TODO - add in user ID to filename
            let filename: String = "tripLocations-" + currentDateTime + ".json"
            os_log("Saved new trip file %s", log: OSLog.default, type: .info, filename)
            Storage.store(convertToTripLocations(tripLocations: tripLocations), to: .documents, as: filename)
            tripLocations = [] // Empty tripLocations after ending a trip.
            saveTripLocations()
        }
    }
    
    func inProgress() -> Bool {
        return loadTripLocations() != nil
    }
    
    func userMessage(message: String, title: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(OKAction)
        self.view!.present(alertController, animated: true, completion: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        os_log("Trip Location Received, Accuracy: %{public}s", log: OSLog.default, type: .info, String(locations.last!.horizontalAccuracy))
        for location in locations {
            // TODO - remove cached locations
            tripLocations.append(location)
        }
        // locationManager.desiredAccuracy = CLLocationAccuracy(kCLLocationAccuracyKilometer)
        locationManager.desiredAccuracy = tripHeuristics.updateLocationAccuracy(tripLocations.last)
        saveTripLocations()
    }
    
    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        os_log("Received a visit.", log: OSLog.default, type: .info)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let error = error as? CLError, error.code == .denied {
            // Location updates are not authorized.
            print(error)
            print("Location not authorized")
            locationManager.stopUpdatingLocation()
            locationManager.stopMonitoringVisits()
            userMessage(
                message: "Open Settings, navigate to Waterloo Travel Diary, then change the location setting to Always Allow.",
                title: "Your Background Location is required")
            
        }
        print("Sorry, there was a location error")
        print(error)
        // Notify the user of any errors.
    }
    
    // called when the authorization status is changed for the core location permission
    // Must first request in-use authorization, then after getting that,
    // request always authorization.
    // https://developer.apple.com/documentation/corelocation/cllocationmanager/1620551-requestalwaysauthorization
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
            case .authorizedAlways:
                os_log("Set to Always Authorized.", log: OSLog.default, type: .info)
            case .authorizedWhenInUse:
                os_log("Set to When In Use.", log: OSLog.default, type: .info)
                locationManager.requestAlwaysAuthorization()
            case .denied:
                os_log("Location Permission Denied.", log: OSLog.default, type: .error)
                userMessage(
                    message: "Open Settings, navigate to Waterloo Travel Diary, then change the location setting to Always Allow.",
                    title: "Your Background Location is required")
            case .restricted:
                os_log("Parent Restrictions do now allow sharing location.", log: OSLog.default, type: .error)
            case .notDetermined:
                os_log("Location Sharing Status not determined.", log: OSLog.default, type: .info)
            @unknown default:
                os_log("Location Sharing Status - unknown status %s", log: OSLog.default, type: .error)
        }
    }
    
    func handleMotionActivity(motionActivity: CMMotionActivity?) {
        if (motionActivity != nil) {
            let motionChangeTime = motionActivity!.startDate
            let confidence: String = {
                switch(motionActivity!.confidence) {
                case CMMotionActivityConfidence.low:
                    return "Low"
                case CMMotionActivityConfidence.medium:
                    return "Medium"
                case CMMotionActivityConfidence.high:
                    return "High"
                @unknown default:
                    return "Unknown"
                }
            }()
            if (motionActivity!.automotive) {
                print("Auto")
            }
            if (motionActivity!.cycling) {
                print("Cycling")
            }
            if (motionActivity!.running) {
                print("Running")
            }
            if (motionActivity!.walking) {
                print("Walking")
            }
            if (motionActivity!.stationary) {
                print("Not moving")
            }
            if (motionActivity!.unknown) {
                print("Unknown") // throw this out.
            }
        }
    }
}
