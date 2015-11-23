import UIKit
import Foundation

class PlaybackViewController: UIViewController {

	lazy var drone = HomeViewController.drone
	var camera: DJICamera!
	var camshiftUtil: CamshiftUtil?
	
	@IBOutlet weak var previewView: UIView!
	@IBOutlet weak var debugLabel: UILabel!
	@IBOutlet weak var imageView: UIImageView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		addDebugInformation("Starting playback")
		camera = drone.camera
		camera.delegate = self
		
		NSThread.currentThread().name = "Main thread"
		
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
	
	
	@IBAction func didPan(sender: UIPanGestureRecognizer) {
		
		NSLog(">>>>>>>>>>>>>>> IS PANNING")
		
		if sender.state == .Ended {
			
			NSLog(">>>>>>>>>>>>>>> FINISHED PAN")
			let translation = sender.translationInView(self.imageView)
			let endPoint = sender.locationInView(self.imageView)
			
			let x = endPoint.x - translation.x
			let y = endPoint.y - translation.y
			let width = translation.x
			let height = translation.y
			
			let selection = CGRectMake(x, y, width, height)
			camshiftUtil = CamshiftUtil(selection: selection)
			printCGRect(selection)
		}
	}
	
	private func printCGRect(box: CGRect) {
		NSLog(">>>>>>>>>>>>>>> x:%f y:%f - w:%f h%f", box.origin.x, box.origin.y, box.size.width, box.size.height)
	}
}

var frameCount = 1

extension PlaybackViewController : VideoFrameProcessorDelegate {
    func didReceiveFrame(frame: AVFrame) {
		
		frameCount++
		
		if frameCount % 4 != 0 {
			return
		}
		
        var uiframe = CVConverters.imageFromAVFrame(frame)
//		
		if let camshiftUtil = camshiftUtil {
//			NSLog(">>>>>>>>>>>>>>> Will process image")
			uiframe = camshiftUtil.meanShift(uiframe)
		}
	
		NSLog("Thread - %@", NSThread.currentThread().name!)
		
        dispatch_async(dispatch_get_main_queue()) {
            self.imageView.image = uiframe
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
