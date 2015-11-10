import UIKit

class JoystickViewController: UIViewController, DJIDroneDelegate {
    var mThrottle : Float = 0.0
    var drone : DJIDrone = DJIDrone(type: DJIDroneType.Phantom3Professional)
    
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
    
    @IBAction func didTouchThrottleDown(sender: AnyObject) {
        mThrottle--
    }
    
    @IBAction func didTouchThrottleUp(sender: AnyObject) {
        mThrottle++
    }
    
    func udpateDrone() {
        let data = DJIFlightControlData(mPitch: 0.0, mRoll: 0.0, mYaw: 0.0, mThrottle: mThrottle)
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
