import Foundation
import MapKit
import UIKit
class MapViewController: UIViewController {
    
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var mapView: MKMapView!
    let regionRadius: CLLocationDistance = 1000
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let location = CLLocationCoordinate2D(latitude: 40.702866, longitude: -74.011391)
        mapView.showsBuildings = true
        mapView.mapType = MKMapType.Standard
        let camera = MKMapCamera(lookingAtCenterCoordinate: location, fromDistance: 900.0, pitch: 45.0, heading: 90.0)
        mapView.camera = camera
    }
    
    @IBAction func saveImage() {
        imageView.hidden = true
        UIGraphicsBeginImageContext(self.view.bounds.size);
        self.view.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let screenshot = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        imageView.hidden = false
        imageView.image = CVConverters.thresholding(screenshot)
        //UIImageWriteToSavedPhotosAlbum(screenShot, nil, nil, nil)

    }
}

