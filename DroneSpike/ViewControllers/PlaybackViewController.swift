import UIKit
import Foundation

class PlaybackViewController: UIViewController {

	lazy var drone = HomeViewController.drone
	var camera: DJICamera!
    var camshiftUtil: CamShiftUtil?
    
    var selectionBox: CGRect?
    var topLeft: CGPoint!
	
	@IBOutlet weak var previewView: UIView!
	@IBOutlet weak var debugLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		addDebugInformation("Starting playback")
		camera = drone.camera
		camera.delegate = self

	}
	
	func addDebugInformation(message: String) {
		debugLabel.text = debugLabel.text! + "\n" + message
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		drone.connectToDrone()
		camera.startCameraSystemStateUpdates()
		
		VideoPreviewer.instance().start()
		VideoPreviewer.instance().setView(previewView)
        VideoPreviewer.instance().videoExtractor.frameProcessorDelegate = self
	}
	
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
		drone.disconnectToDrone()
		camera.stopCameraSystemStateUpdates()
		VideoPreviewer.instance().setView(nil)
	}
	
	override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
		
	}
    
	override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
		VideoPreviewer.instance().setView(previewView)
	}
    
    
    @IBAction func panGesture(sender: UIPanGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.Began {
            topLeft = sender.locationInView(previewView)
        } else if sender.state == .Ended {
            let bottomRight = sender.locationInView(previewView)
            let width = topLeft.x + bottomRight.x
            let height = topLeft.y + bottomRight.y
            
            selectionBox = CGRectMake(topLeft.x, topLeft.y, width, height)
        }
        
    }

}

extension PlaybackViewController : VideoFrameProcessorDelegate {
    func didReceiveFrame(frame: AVFrame) {
        
        //create uiimage and detect elements;
        var frameImage = CVConverters.imageFromAVFrame(frame)
        
        if camshiftUtil == nil {
            if let selectionBox = selectionBox {
                camshiftUtil = CamShiftUtil(box: selectionBox, andImage: frameImage)
            }
        }
        
        if camshiftUtil != nil {
            frameImage = camshiftUtil?.processImage(frameImage)
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            self.imageView.image = frameImage
        }
    }
}

extension PlaybackViewController: DJICameraDelegate {
	func camera(camera: DJICamera!, didReceivedVideoData videoBuffer: UnsafeMutablePointer<UInt8>, length: Int32) {
		// keep as var
		var buffer = UnsafeMutablePointer<UInt8>.alloc(Int(length))
        
		memcpy(buffer, videoBuffer, Int(length))
        
		VideoPreviewer.instance().dataQueue.push(buffer, length: length)
	}
	
	func camera(camera: DJICamera!, didUpdateSystemState systemState: DJICameraSystemState!) {
//		addDebugInformation("Sys state: \(systemState)")
	}
}
