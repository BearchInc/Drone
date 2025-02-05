import Foundation
import MapKit
import UIKit
class MapViewController: UIViewController {
    
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var button: UIButton!
    let regionRadius: CLLocationDistance = 1000
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let location = CLLocationCoordinate2D(latitude: 30.264781, longitude: -97.744461)
//        let location = CLLocationCoordinate2D(latitude:37.7899, longitude:-122.3969)
        mapView.showsBuildings = true
        mapView.showsPointsOfInterest = false
        mapView.mapType = MKMapType.Standard
        let camera = MKMapCamera(lookingAtCenterCoordinate: location, fromDistance: 600.0, pitch: 45.0, heading: 0.0)
        mapView.camera = camera
    }
    
    @IBAction func saveImage() {
        let screenshot = captureScreen()
        
        imageView.image = CVConverters.measureHeights(screenshot)
//        UIImageWriteToSavedPhotosAlbum(screenshot, nil, nil, nil)

    }
    
    func captureScreen() -> UIImage {
        imageView.hidden = true
        button.hidden = true
        UIGraphicsBeginImageContext(self.view.bounds.size);
        self.view.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let screenshot = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        imageView.hidden = false
        button.hidden = false
        return screenshot
//        return UIImage(named:"grid")!

    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        return
        let touch = event?.allTouches()?.first! as UITouch!
        let point = touch.locationInView(self.view)
        showColorInPoint(point)
        
    }
    
    func showColorInPoint(point: CGPoint) {
        let screenshot = captureScreen()
        let result = CVConverters.colorIn(screenshot, atX: Int32(point.x), andY: Int32(point.y))
        imageView.image = result
    }
}

