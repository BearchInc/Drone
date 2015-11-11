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
    
	lazy var drone = HomeViewController.drone
    lazy var mission : DJIWaypointMission = {
        let mission = self.drone.mainController.navigationManager.waypointMission
        mission.maxFlightSpeed = 14.0
        mission.autoFlightSpeed = 10.0
        mission.headingMode = .Auto
        mission.finishedAction = .GoHome
        mission.flightPathMode = .Normal
        
        return mission
    }()

 	@IBOutlet weak var debugLabel: UILabel!
    
    @IBOutlet weak var progressBar: UIProgressView!
    
    @IBAction func didTouchTakeOff(sender: AnyObject) {
        self.drone.mainController.startTakeoffWithResult { error -> Void in
            self.setDebugText("Taking off: \(error.errorDescription)")
        }
    }
    
    @IBAction func didTouchUploadMission(sender: AnyObject) {
        let currentLocation = locationManager.location!
        let secondLocation = CLLocationCoordinate2D(latitude: currentLocation.coordinate.latitude + 0.00002, longitude: currentLocation.coordinate.longitude)
        
        let waypoint = DJIWaypoint(coordinate: locationManager.location!.coordinate)
        waypoint.addAction(DJIWaypointAction(actionType: .RotateAircraft, param: 90))
        
        let secondWaypoint = DJIWaypoint(coordinate: secondLocation)
        secondWaypoint.addAction(DJIWaypointAction(actionType: .RotateAircraft, param: 180))
        
        mission.addWaypoint(waypoint)
        mission.addWaypoint(secondWaypoint)
        
        if (mission.isValid) {
            mission.setUploadProgressHandler { (progress) -> Void in
                self.progressBar.progress = Float(progress)/100.0
            }
            
            mission.uploadMissionWithResult { error -> Void in
                self.setDebugText("Uploading: \(error.errorDescription)")
                
                self.mission.startMissionWithResult { error -> Void in
                    self.setDebugText("Starting Mission: \(error.errorDescription)")
                }
            }
        } else {
            self.setDebugText("Invalid Mission: \(mission.debugDescription)")
        }
        
    }
	
    lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        return manager
    }()
	
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
        self.drone.mainController.navigationManager.enterNavigationModeWithResult { error -> Void in
            self.setDebugText("Enter Navigation: \(error.errorDescription)")
        }
    }
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		drone.connectToDrone()
        drone.mainController.startUpdateMCSystemState()
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

