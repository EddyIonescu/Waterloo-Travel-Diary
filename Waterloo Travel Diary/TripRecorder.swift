//
//  TripRecorder.swift
//  Waterloo Travel Diary
//
//  Created by Eddy on 2020-01-20.
//  Copyright © 2020 Eddy. All rights reserved.
//

import Foundation
import CoreLocation


class TripRecorder: NSObject, CLLocationManagerDelegate {
    
    let locationManager = CLLocationManager()
    var tripLocations = [CLLocation]()

    struct TripLocation : Codable {
        var lat: Float
        var lon: Float
        var heading: Float
        var speed: Float
        var timestamp: Int64
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
            // TOOD - tripLocation should use CLLocation types
            var _tripLocation = TripLocation(
                lat: Float(tripLocation.coordinate.latitude),
                lon: Float(tripLocation.coordinate.longitude),
                heading: Float(tripLocation.course),
                speed: Float(tripLocation.speed),
                timestamp: Int64(tripLocation.timestamp.timeIntervalSince1970)
            )
            // TODO - add in fields
            _tripLocations.append(_tripLocation)
        }
        var _fakeLocations = [TripLocation]()
        _fakeLocations.append(TripLocation(
            lat: 43.4703017,
            lon: -80.5433984,
            heading: 0,
            speed: 100,
            timestamp: 0
        ))
        _fakeLocations.append(TripLocation(
            lat: 43.4733451,
            lon: -80.541371,
            heading: 0,
            speed: 100,
            timestamp: 0
        ))
        _fakeLocations.append(TripLocation(
            lat: 43.462149,
            lon: -80.5237405,
            heading: 0,
            speed: 100,
            timestamp: 0
        ))
        _fakeLocations.append(TripLocation(
            lat: 43.4660041,
            lon: -80.5267112,
            heading: 0,
            speed: 100,
            timestamp: 0
        ))
        // return _fakeLocations
        return _tripLocations
    }
    
    func startTrip() {
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.delegate = self
    }
    
    func stopTrip() {
        locationManager.stopUpdatingLocation()
        // do stuff with locations here - end the trip
        print(tripLocations)
        Storage.store(convertToTripLocations(tripLocations: tripLocations), to: .documents, as: "tripLocations.json")
        // TODO - add timestamp to filename
    }
    
    func locationManager(_ manager: CLLocationManager,  didUpdateLocations locations: [CLLocation]) {
        let lastLocation = locations.last!
        print(lastLocation)
        tripLocations.append(lastLocation)
        // also check timestamp of location as it might be a cached location
        // Do something with the location.
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let error = error as? CLError, error.code == .denied {
            // Location updates are not authorized.
            manager.stopUpdatingLocation()
            print(error)
            return
        }
        print("Sorry, there was a location error")
        // Notify the user of any errors.
    }
    
    // called when the authorization status is changed for the core location permission
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("location manager authorization status changed")
        
        switch status {
        case .authorizedAlways:
            print("user allow app to get location data when app is active or in background")
        case .authorizedWhenInUse:
            print("user allow app to get location data only when app is active")
        case .denied:
            print("user tap 'disallow' on the permission dialog, cant get location data")
        case .restricted:
            print("parental control setting disallow location data")
        case .notDetermined:
            print("the location permission dialog haven't shown before, user haven't tap allow/disallow")
        }
    }
}
