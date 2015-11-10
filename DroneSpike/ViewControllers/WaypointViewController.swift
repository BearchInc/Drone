//
//  ViewController.swift
//  DroneSpike
//
//  Created by Diego Borges on 11/9/15.
//  Copyright © 2015 Bearch Inc. All rights reserved.
//

import UIKit
import CoreLocation

class WaypointViewController: UIViewController, CLLocationManagerDelegate {

 	@IBOutlet weak var debugLabel: UILabel!
	
    lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        return manager
    }()
	
	lazy var drone = HomeViewController.drone
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if CLLocationManager.authorizationStatus() == .NotDetermined {
            locationManager.requestAlwaysAuthorization()
        }
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
		
	}
	
	func createMission() {
		let currentLocation = locationManager.location!
		let secondLocation = CLLocationCoordinate2D(latitude: currentLocation.coordinate.latitude + 0.00002, longitude: currentLocation.coordinate.longitude)

		let waypoint = DJIWaypoint(coordinate: locationManager.location!.coordinate)
		let secondWaypoint = DJIWaypoint(coordinate: secondLocation)
		
		let mission = drone.mainController.navigationManager.waypointMission
		mission.addWaypoint(waypoint)
		mission.addWaypoint(secondWaypoint)
		
		drone.mainController.navigationManager.enterNavigationModeWithResult { error -> Void in
			
			self.setDebugText("Enter Navigation: \(error.errorDescription)")
			
			mission.uploadMissionWithResult { error -> Void in
				self.setDebugText("Uploading: \(error.errorDescription)")
				
				mission.startMissionWithResult { error -> Void in
					self.setDebugText("Starting Mission: \(error.errorDescription)")
				}
			}
		}
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		drone.connectToDrone()
		createMission()
	}
    
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
		drone.disconnectToDrone()
	}
	
	func setDebugText(message: String) {
		debugLabel.text = debugLabel.text! + "\n" + message
	}
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
//        setDebugText("Auth status changed to \(status.rawValue)")
        if status == .AuthorizedAlways || status == .AuthorizedWhenInUse {
            locationManager.startUpdatingLocation()
        }
    }
}

