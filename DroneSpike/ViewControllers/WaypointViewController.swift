import UIKit
import MapKit
import CoreLocation

class WaypointViewController: UIViewController, CLLocationManagerDelegate {
    var missionControl : MissionControl!
	lazy var drone = HomeViewController.drone
    
    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            missionControl = MissionControl(mapView: mapView)
            mapView.showsBuildings = true
            mapView.showsUserLocation = true
            mapView.showsPointsOfInterest = true
            let cameraLocation = CLLocation(latitude: locationManager.location!.coordinate.latitude, longitude: locationManager.location!.coordinate.longitude)
            var mapCamera = MKMapCamera(
                lookingAtCenterCoordinate: locationManager.location!.coordinate,
                fromEyeCoordinate: cameraLocation.coordinate,
                eyeAltitude: 350.0)
            
            print("Location: \(locationManager.location?.coordinate)")
            mapView.setCamera(mapCamera, animated: true)
        }
    }
    
    @IBOutlet weak var modeButton: UIButton!
    
    @IBOutlet weak var progressBar: UIProgressView!
	
    lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        return manager
    }()
	
    @IBAction func didTouchStartMission(sender: AnyObject) {
        missionControl.progressHandler = { progress -> Void in
            self.progressBar.progress = Float(progress) / 100.0
            print("progress: \(progress)")
        }
        
        missionControl.startWith(self.drone) { result in
            let message = result == 0 ? "Mission successfully started" : "Mission Failed with code : \(result.errorCode)"
            UIAlertView(title: "", message: message, delegate: nil, cancelButtonTitle: "OK").show()
        }
    }
    
    @IBAction func didTouchClearMission(sender: AnyObject) {
        missionControl.clear()
    }
    
    @IBAction func didTouchEditMission(sender: AnyObject) {
        let selected = !modeButton.selected
        let nextState = selected ? UIControlState.Selected : UIControlState.Normal

        modeButton.selected = selected
    }
    
    @IBAction func didTouchMap(sender: UITapGestureRecognizer) {
        if modeButton.selected {
            print("Dropping annotation!")
            let mapPoint = sender.locationInView(mapView)
            let location = mapView.convertPoint(mapPoint, toCoordinateFromView: mapView)
            let waypointAnnotation = Waypoint(coordinate: location)
            
            missionControl.addWaypoint(waypointAnnotation)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if CLLocationManager.authorizationStatus() == .NotDetermined {
            locationManager.requestAlwaysAuthorization()
        }
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
		
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		drone.connectToDrone()
        drone.mainController.startUpdateMCSystemState()
	}
    
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
		drone.disconnectToDrone()
	}
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedAlways || status == .AuthorizedWhenInUse {
            locationManager.startUpdatingLocation()
        }
    }
}

