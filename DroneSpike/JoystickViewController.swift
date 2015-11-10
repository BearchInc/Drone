import UIKit

class JoystickViewController: UIViewController, DJIDroneDelegate {
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
