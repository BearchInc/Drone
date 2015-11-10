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

    lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        return manager
    }()
    
    lazy var drone = DJIDrone(type: DJIDroneType.Phantom3Professional)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        drone.connectToDrone()
        
        if CLLocationManager.authorizationStatus() == .NotDetermined {
            locationManager.requestAlwaysAuthorization()
        }
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
        
        print("Loaded")
        
        let waypoint = DJIWaypoint(coordinate: locationManager.location!.coordinate)
        let mission = drone.mainController.navigationManager.waypointMission
        mission.addWaypoint(waypoint)
        mission.uploadMissionWithResult { error -> Void in
            print("Error \(error.errorDescription)")
        }
        
        mission.startMissionWithResult { error -> Void in
            print("Error \(error.errorDescription)")
        }
    }
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		drone.connectToDrone()
	}
    
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
		drone.disconnectToDrone()
	}
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        print("Auth status changed to \(status)")
        if status == .AuthorizedAlways || status == .AuthorizedWhenInUse {
            locationManager.startUpdatingLocation()
        }
    }
}

