import UIKit
import MapKit
import CoreLocation

class WaypointViewController: UIViewController, CLLocationManagerDelegate {
    
	lazy var drone = HomeViewController.drone
    lazy var missionControl = MissionControl()
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var modeButton: UIButton!
    
    @IBOutlet weak var progressBar: UIProgressView!
	
    lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        return manager
    }()
	
    @IBAction func didTouchStartMission(sender: AnyObject) {
        missionControl.startWith(self.drone)
    }
    
    @IBAction func didTouchClearMission(sender: AnyObject) {
        missionControl.clear()
    }
    
    @IBAction func didTouchEditMission(sender: AnyObject) {
        let selected = !modeButton.selected
        let nextState = selected ? UIControlState.Selected : UIControlState.Normal

        modeButton.selected = selected
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

