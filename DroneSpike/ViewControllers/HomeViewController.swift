//
//  HomeViewController.swift
//  DroneSpike
//
//  Created by Fernando Heck on 11/10/15.
//  Copyright © 2015 Bearch Inc. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {

	var drone: DJIDrone!
	
	@IBOutlet weak var debugLabel: UILabel!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		DJIAppManager.registerApp("602797533f7b529cc9470265", withDelegate: self)
    }
	
	func setDebugText(message: String) {
		debugLabel.text = message
	}

}

extension HomeViewController: DJIAppManagerDelegate, DJIDroneDelegate {
	
	func droneOnConnectionStatusChanged(status: DJIConnectionStatus) {
		setDebugText("Status \(status)")
	}
	
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
			self.drone = drone
		} else {
			message = "error getting new drone"
		}
		
		setDebugText(message)
	}
	
}
