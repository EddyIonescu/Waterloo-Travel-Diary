//
//  FirstViewController.swift
//  Waterloo Travel Diary
//
//  Created by Eddy on 2020-01-16.
//  Copyright © 2020 Eddy. All rights reserved.
//

import UIKit

class FirstViewController: UIViewController {
    //MARK: Actions
    //MARK: Properties
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    @IBOutlet weak var startNewTripButton: UIButton!
    
    
    let trip = TripRecorder()
    @IBAction func startTrip(_ sender: Any) {
        print("trip button pressed")
        if (startNewTripButton.titleLabel!.text == "Stop Recording") {
            trip.stopTrip()
            startNewTripButton.setTitle("Start New Trip", for: .normal)
        }
        else {
            trip.startTrip()
            startNewTripButton.setTitle("Stop Recording", for: .normal)
        }
    }
    
}

