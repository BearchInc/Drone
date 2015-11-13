import UIKit
import Foundation

class PlaybackViewController: UIViewController {
    
    var flag = true
	lazy var drone = HomeViewController.drone
	var camera: DJICamera!
	
	@IBOutlet weak var previewView: UIView!
	@IBOutlet weak var debugLabel: UILabel!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		addDebugInformation("Starting playback")
		camera = drone.camera
		camera.delegate = self
	}
	
	func addDebugInformation(message: String) {
		debugLabel.text = message + "\n" + debugLabel.text!
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		drone.connectToDrone()
		camera.startCameraSystemStateUpdates()
		
		VideoPreviewer.instance().start()
		VideoPreviewer.instance().setView(previewView)
        VideoPreviewer.instance().videoExtractor.delegate = self
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
    @IBOutlet weak var imageView: UIImageView!
}

extension PlaybackViewController : VideoDataProcessDelegate {
    func processVideoData(start: UnsafeMutablePointer<UInt8>, length: Int32) {
        
//        let bytes = UnsafeBufferPointer<UInt8>(start:decodedData, count:Int(length))
//
//        NSLog("######### Length: %d", length)
//        for i in 0 ..< Int(length) {
//            NSLog("######### Byte: %@", bytes[i])
//        }
//
//        NSLog("####### process video data of length %d", bytes.count)
//        if length > 0 {
//            let data = NSData()
//            data.getBytes(start, length: Int(length))
//            let data = NSData(bytesNoCopy: start, length: Int(length))
//            NSLog("####### decoded data %@, length %@", data, length)
//        }
    }
}

extension PlaybackViewController: DJICameraDelegate {
//
//    private func imageFromUnsafeMutablePointer(buffer: UnsafeMutablePointer<UInt8>, length: Int) -> UIImage {
//        let data  = NSData()
//        data.getBytes(buffer, length: length)
//        return UIImage(data: data)!
//    }
    


    
    
	func camera(camera: DJICamera!, didReceivedVideoData videoBuffer: UnsafeMutablePointer<UInt8>, length: Int32) {
		// keep as var
		var buffer = UnsafeMutablePointer<UInt8>.alloc(Int(length))
        
		memcpy(buffer, videoBuffer, Int(length))
    
        
        var pixelBuffer = VideoPreviewer.instance().getPixelBuffer()
        var pbm = pixelBuffer.memory?.takeUnretainedValue()

//        if flag && length > 0 {
        NSLog("#################################  Pixel buffer: \(pbm)")
        
            
        var image = CIImage(CVPixelBuffer: pbm!, options: nil)
    
        var temporaryContext = CIContext(options: nil)
        
        let width = CGFloat(CVPixelBufferGetWidth(pbm!))
        let height = CGFloat(CVPixelBufferGetHeight(pbm!))
        var videoImage = temporaryContext.createCGImage(image, fromRect: CGRectMake(0, 0, width, height))
        var uiimage = UIImage(CIImage: image)
    
        NSLog("Will put image somewhere")
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            NSLog("Will put image somewhere")
            self.imageView.image = uiimage
            let imageData = UIImagePNGRepresentation(uiimage)
            NSLog("\(imageData)")
            NSLog("\(imageData?.length)")
        })
        
		VideoPreviewer.instance().dataQueue.push(buffer, length: length)
	}
	
	func camera(camera: DJICamera!, didUpdateSystemState systemState: DJICameraSystemState!) {
//		addDebugInformation("Sys state: \(systemState)")
	}
	
}
