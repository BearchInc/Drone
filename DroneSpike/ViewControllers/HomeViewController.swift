//
//  HomeViewController.swift
//  DroneSpike
//
//  Created by Fernando Heck on 11/10/15.
//  Copyright © 2015 Bearch Inc. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {

	static var drone: DJIDrone!
	
	@IBOutlet weak var debugLabel: UILabel!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		DJIAppManager.registerApp("602797533f7b529cc9470265", withDelegate: self)
    }
	
	func setDebugText(message: String) {
		debugLabel.text = debugLabel.text! + "\n" + message
	}

}

extension HomeViewController: DJIDroneDelegate {
	func droneOnConnectionStatusChanged(status: DJIConnectionStatus) {
		setDebugText("Status \(status.rawValue)")
	}
}

extension HomeViewController: DJIAppManagerDelegate {
	
	
	func appManagerDidRegisterWithError(statusCode: Int32) {
		if statusCode == RegisterSuccess {
			setDebugText("Registered successfully")
		} else {
			setDebugText("Error registering \(statusCode)")
		}
	}
	
	func appManagerDidConnectedDroneChanged(newDrone: DJIDrone!) {
		
		var message = "New drone found"
		if let drone = newDrone {
			HomeViewController.drone = drone
			HomeViewController.drone.delegate = self
		} else {
			message = "error getting new drone"
		}
		
		setDebugText(message)
	}
	
}
