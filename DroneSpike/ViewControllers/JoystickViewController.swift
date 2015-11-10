import UIKit

class JoystickViewController: UIViewController, DJIDroneDelegate {
    var mThrottle : Float = 0.0
	lazy var drone = HomeViewController.drone
    
    @IBOutlet weak var label: UILabel!
    override func viewDidLoad() {
        drone.delegate = self
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        drone.connectToDrone()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func droneOnConnectionStatusChanged(status:DJIConnectionStatus) {
        print(status)
    }
    
    @IBAction func control(sender: AnyObject) {
        drone.mainController.navigationManager.enterNavigationModeWithResult { (error) -> Void in
            if error != nil {
                self.label.text = error.errorDescription
            }
        }
    }
    
    @IBAction func didTouchThrottleDown(sender: AnyObject) {
        mThrottle = 1
        udpateDrone()
    }
    
    @IBAction func didTouchThrottleUp(sender: AnyObject) {
        mThrottle = -1
        udpateDrone()
    }
    
    func udpateDrone() {
        var data = DJIFlightControlData()
        data.mThrottle = mThrottle
        drone.mainController.navigationManager.flightControl.sendFlightControlData(data, withResult: nil)
    }
    
    @IBAction func didTouchTakeOff(sender: AnyObject) {
        drone.mainController.startTakeoffWithResult { (error) -> Void in
            if error != nil {
                self.label.text = error.errorDescription
            } else {
                self.label.text = "success"
            }
        }
    
    }
}

extension JoystickViewController : DJIMainControllerDelegate {
    func mainController(mc: DJIMainController!, didMainControlError error: MCError) {
        
    }
    
    func mainController(mc: DJIMainController!, didReceivedDataFromExternalDevice data: NSData!) {
        
    }
    
    func mainController(mc: DJIMainController!, didUpdateLandingGearState state: DJIMCLandingGearState!) {
        
    }
    
    func mainController(mc: DJIMainController!, didUpdateSystemState state: DJIMCSystemState!) {
        
    }
}
