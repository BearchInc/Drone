import UIKit

class HomeViewController: UIViewController {

	static var drone: DJIDrone?
	
	@IBOutlet weak var debugLabel: UILabel!
	
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
		DJIAppManager.registerApp("602797533f7b529cc9470265", withDelegate: self)
    }
	
	func setDebugText(message: String) {
		debugLabel.text = debugLabel.text! + "\n" + message
	}
    

}

extension HomeViewController: DJIDroneDelegate {
	func droneOnConnectionStatusChanged(status: DJIConnectionStatus) {
        if (status == DJIConnectionStatus.ConnectionSucceeded) {
            HomeViewController.drone!.mainController.navigationManager.enterNavigationModeWithResult({ error -> Void in
                if error.errorCode == DJIErrorCode.None.rawValue {
                    UIAlertView(title: "Connection Status", message: "Entered Navigation Mode!", delegate: nil, cancelButtonTitle: "OK").show()
                }
            })
        }
	}
}

extension HomeViewController: DJIAppManagerDelegate {
		
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
			HomeViewController.drone = drone
			HomeViewController.drone!.delegate = self
		} else {
			message = "error getting new drone"
		}
		
		setDebugText(message)
	}
	
}
