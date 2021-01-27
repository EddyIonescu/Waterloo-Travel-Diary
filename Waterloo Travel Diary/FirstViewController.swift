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
        trip.setUpdateStateTextCallback(callback: setStateTextField)
        
        if (trip.inProgress()) {
            trip.startTrip() // Resume recording location and adding to existing trip if it exists.
            startNewTripButton.setTitle(stopTitle, for: .normal)
        }
    }
    @IBOutlet weak var startNewTripButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var batteryEfficientSwitch: UISwitch!
    @IBOutlet weak var state: UITextField!
    func setStateTextField(scenario: String?) {
        if scenario == nil {
            state.text = ""
            return
        }
        state.text = scenario
    }
    
    

    @IBAction func showLoginModal(_ sender: Any) {
        showLogin()
    }

    @IBAction func toggleBatteryEfficientMode(_ sender: Any) {
        let batteryEfficientMode = batteryEfficientSwitch.isOn
        let userDefaults = UserDefaults.standard
        userDefaults.set(batteryEfficientMode, forKey: "batteryEfficientMode")
    }

    @IBAction func startTrip(_ sender: Any) {
        os_log("Trip start/stop button pressed.", log: OSLog.default, type: .info)
        if (loginIsNeeded()) {
            showLogin()
            return
        }
        if (startNewTripButton.titleLabel!.text == stopTitle) {
            trip.stopTrip()
            startNewTripButton.setTitle(startTitle, for: .normal)
        }
        else {
            trip.startTrip(view: self)
            startNewTripButton.setTitle(stopTitle, for: .normal)
        }
    }
    
    func loginIsNeeded() -> Bool {
        let userDefaults = UserDefaults.standard
        return userDefaults.string(forKey: "email") == nil
    }
    
    func showLogin() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let loginController = storyboard.instantiateViewController(identifier: "LoginViewController")
        present(loginController, animated: true, completion: nil)
    }
}

