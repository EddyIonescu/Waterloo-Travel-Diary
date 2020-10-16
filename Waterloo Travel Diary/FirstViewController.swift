//
//  FirstViewController.swift
//  Waterloo Travel Diary
//
//  Created by Eddy on 2020-01-16.
//  Copyright © 2020 Eddy. All rights reserved.
//

import UIKit
import os.log

class FirstViewController: UIViewController {
    
    let startTitle = "Start New Trip"
    let stopTitle = "Stop Recording"

    //MARK: Actions

    //MARK: Properties
    override func viewDidLoad() {
        super.viewDidLoad()
        if (trip.inProgress()) {
            trip.startTrip() // Resume recording location and adding to existing trip if it exists.
            startNewTripButton.setTitle(stopTitle, for: .normal)
        }
    }
    @IBOutlet weak var startNewTripButton: UIButton!
    
    

    @IBAction func startTrip(_ sender: Any) {
        os_log("Trip start/stop button pressed.", log: OSLog.default, type: .info)
        if (startNewTripButton.titleLabel!.text == stopTitle) {
            trip.stopTrip()
            startNewTripButton.setTitle(startTitle, for: .normal)
        }
        else {
            trip.startTrip(view: self)
            startNewTripButton.setTitle(stopTitle, for: .normal)
        }
    }
    
}

