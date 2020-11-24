//
//  SecondViewController.swift
//  Waterloo Travel Diary
//
//  Created by Eddy on 2020-01-16.
//  Copyright © 2020 Eddy. All rights reserved.
//

import UIKit
import MapKit
import os.log

class SecondViewController: UIViewController, MKMapViewDelegate {

    override func viewWillAppear(_ animated: Bool) {
        loadMaps()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        super.viewDidAppear(true)
        // enable scrolling
        (view as! UIScrollView).contentSize = CGSize(width: view.frame.width, height: view.frame.height)
    }
    
    var createdViews: [UIView] = []

    func loadMaps() {
        for subView in createdViews {
            subView.removeFromSuperview()
        }
        let tripPaths = getTripFiles(tripLocationsOnly: true)
        var mapNum = 0
        for tripPath in tripPaths {
            makeMapView(mapNum: mapNum, numMaps: tripPaths.count, tripPath: tripPath)
            mapNum += 1
        }
    }
    
    func makeMapLabelView(
        trip: [TripRecorder.TripLocation],
        tripNumber: Int,
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        height: CGFloat) -> UILabel {
        let mapLabelView = UILabel(frame: CGRect(x: x, y: y, width: width, height: height))
        mapLabelView.numberOfLines = 2
        mapLabelView.lineBreakMode = .byWordWrapping
        mapLabelView.textColor = UIColor.black

        let startDateTime = Date(timeIntervalSince1970: TimeInterval(trip.first!.timestamp))
        let endDateTime = Date(timeIntervalSince1970: TimeInterval(trip.last!.timestamp))

        let format = DateFormatter()

        var mapLabelViewText = "Trip #" + String(tripNumber) + ". From "
        format.dateFormat = "h:mm a"
        mapLabelViewText += format.string(from: startDateTime) + " to "
        format.dateFormat = "h:mm a"
        mapLabelViewText += format.string(from: endDateTime) + ". \n"
        format.dateFormat = "EEEE MMMM d, yyyy"
        mapLabelViewText += format.string(from: startDateTime)
        
        mapLabelView.text = mapLabelViewText
        mapLabelView.textColor = UIColor.white
        return mapLabelView
    }

    func makeMapView(mapNum: Int, numMaps: Int, tripPath: String) {
        let mapView = MKMapView()

        mapView.delegate = self
        mapView.isZoomEnabled = true
        mapView.isPitchEnabled = true
        mapView.isScrollEnabled = true
        mapView.isRotateEnabled = false

        let startPadding:CGFloat = 300
        let heightPadding:CGFloat = 50
        let mapHeight:CGFloat = 300
        let mapLabelHeight:CGFloat = 60
        let mapTotalHeight:CGFloat = mapHeight + heightPadding + mapLabelHeight
        let mapWidth:CGFloat = view.frame.size.width - 40
        // set map position
        let leftMargin:CGFloat = 20
        let topMargin:CGFloat = startPadding + heightPadding + CGFloat(CGFloat(mapNum) * mapTotalHeight)

        mapView.frame = CGRect(x: leftMargin, y: topMargin, width: mapWidth, height: mapHeight)
        (view as! UIScrollView).contentSize = CGSize(
            width: view.frame.width,
            height: startPadding + CGFloat(numMaps)*mapTotalHeight)

        // Add the trip
        let trip = getTrip(tripPath: tripPath)
        let accurateTripLocations = trip.filter({
            (tripLocation: TripRecorder.TripLocation) -> Bool in return
                tripLocation.accuracy <= 25.0
        })
        if (accurateTripLocations.isEmpty) {
            return
        }
        let line = getTripLine(trip: accurateTripLocations)
        zoomToPolyLine(mapView: mapView, polyLine: line)
        mapView.addOverlay(line)

        let mapLabelView = makeMapLabelView(
            trip: trip,
            tripNumber: numMaps - mapNum,
            x: leftMargin,
            y: topMargin-mapLabelHeight,
            width: mapWidth,
            height: mapLabelHeight)
        view.addSubview(mapLabelView)
        view.addSubview(mapView)
        createdViews.append(mapLabelView)
        createdViews.append(mapView)
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
    
    func zoomToPolyLine(mapView: MKMapView, polyLine: MKPolyline) {
        mapView.setRegion(MKCoordinateRegion(polyLine.boundingMapRect), animated: false)
        let edgePadding = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        mapView.setVisibleMapRect(mapView.visibleMapRect, edgePadding: edgePadding, animated: false)
    }
    
    func getTripLine(trip: [TripRecorder.TripLocation]) -> MKPolyline {
        let coordinates = TripRecorder.convertToMapCoordinate(tripLocations: trip)
        let line = MKPolyline(coordinates: coordinates, count: coordinates.count)
        return line
    }
}

