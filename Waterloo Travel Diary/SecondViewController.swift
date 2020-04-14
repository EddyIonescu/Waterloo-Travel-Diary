//
//  SecondViewController.swift
//  Waterloo Travel Diary
//
//  Created by Eddy on 2020-01-16.
//  Copyright © 2020 Eddy. All rights reserved.
//

import UIKit
import MapKit

class SecondViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.mapView.delegate = self
        mapView.isZoomEnabled = true
        mapView.isPitchEnabled = true
        mapView.isScrollEnabled = true
        mapView.isRotateEnabled = false
        // Do any additional setup after loading the view.
        let trip = getRecentmostTrip()
        let line = getTripLine(trip: trip)
        zoomToPolyLine(polyLine: line)
        mapView.addOverlay(line)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let overlayGeodesic = overlay as? MKPolyline
        {
            let overLayRenderer = MKPolylineRenderer(polyline: overlayGeodesic)
            overLayRenderer.lineWidth = 5
            overLayRenderer.strokeColor = UIColor.blue
            return overLayRenderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func zoomToPolyLine(polyLine: MKPolyline) {
        mapView.setRegion(MKCoordinateRegion(polyLine.boundingMapRect), animated: false)
        let edgePadding = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        mapView.setVisibleMapRect(mapView.visibleMapRect, edgePadding: edgePadding, animated: false)
    }
    
    func getTripLine(trip: [TripRecorder.TripLocation]) -> MKPolyline {
        let coordinates = TripRecorder.convertToMapCoordinate(tripLocations: trip)
        let line = MKPolyline(coordinates: coordinates, count: coordinates.count)
        return line
    }
    
    func getRecentmostTrip() -> [TripRecorder.TripLocation] {
        let storedTrip = Storage.retrieve(
            "tripLocations.json",
            from: .documents,
            as: [TripRecorder.TripLocation].self
        )
        print("retrieved:")
        print(storedTrip)
        return storedTrip
    }
    
    


}

