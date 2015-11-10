//
//  ViewController.swift
//  DroneSpike
//
//  Created by Diego Borges on 11/9/15.
//  Copyright © 2015 Bearch Inc. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate, DJIAppManagerDelegate, DJIDroneDelegate, DJIMainControllerDelegate {
   
    var drone: DJIDrone = DJIDrone(type: DJIDroneType.Phantom3Professional)
    
    @IBAction func startMission(sender: AnyObject) {
        let mission = drone.mainController.navigationManager.waypointMission
        let currentLocation = locationManager.location!
        let twoMetersAway = CLLocationCoordinate2D(latitude: currentLocation.coordinate.latitude + 0.00002, longitude: currentLocation.coordinate.longitude)
        let waypoint = DJIWaypoint(coordinate: currentLocation.coordinate)
        let waypointTwoMetersAway = DJIWaypoint(coordinate: twoMetersAway)
        
        mission.addWaypoint(waypoint)
        mission.addWaypoint(waypointTwoMetersAway)
        mission.finishedAction = DJIWaypointMissionFinishedAction.GoHome
        
        mission.uploadMissionWithResult { error -> Void in
            if error != nil {
                UIAlertView(title: "Error Uploading Mission", message: error.errorDescription, delegate: nil, cancelButtonTitle: "OK").show()
            } else {
                mission.startMissionWithResult { error -> Void in
                    UIAlertView(title: "Error Starting Mission", message: error.errorDescription, delegate: nil, cancelButtonTitle: "OK").show()
                }
            }
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
        DJIAppManager.registerApp("602797533f7b529cc9470265", withDelegate: self)
        
        if CLLocationManager.authorizationStatus() == .NotDetermined {
            locationManager.requestAlwaysAuthorization()
        }
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }

        self.drone.delegate = self
        self.drone.mainController.mcDelegate = self
        self.drone.connectToDrone()
        
        print("Loaded")
    }
    
    func droneOnConnectionStatusChanged(status: DJIConnectionStatus) {
        print("Drone status changed: \(status)")
    }
    
    func mainController(mc: DJIMainController!, didMainControlError error: MCError) {
        print("Main controller error: \(error.rawValue)")
    }
    
    func appManagerDidRegisterWithError(errorCode: Int32) {
        if errorCode == 0 {
            UIAlertView(title: "Register", message: "Success", delegate: nil, cancelButtonTitle: "OK").show()
        } else {
            UIAlertView(title: "Register", message: "Error: \(errorCode)", delegate: nil, cancelButtonTitle: "OK").show()
        }
    }
    
    func appManagerDidConnectedDroneChanged(newDrone: DJIDrone?) {
        if let drone = newDrone {
            self.drone = drone
            UIAlertView(title: "Creating Drone", message: "Found Existent One", delegate: nil, cancelButtonTitle: "OK").show()
        } else {
            self.drone = DJIDrone(type: DJIDroneType.Phantom3Professional)
            UIAlertView(title: "Creating Drone", message: "Fresh New One", delegate: nil, cancelButtonTitle: "OK").show()
        }
        
        drone.connectToDrone()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        drone.disconnectToDrone()
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        print("Auth status changed to \(status)")
        if status == .AuthorizedAlways || status == .AuthorizedWhenInUse {
            locationManager.startUpdatingLocation()
        }
    }
}

