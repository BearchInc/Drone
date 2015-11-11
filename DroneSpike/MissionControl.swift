import MapKit
import Foundation

class MissionControl {
    var waypoints = [Waypoint]()
    var mapView : MKMapView
    var progressHandler : DJIWaypointMissionUploadProgressHandler = { progress -> Void in
    }
    
    init(mapView: MKMapView) {
        self.mapView = mapView
    }
    
    func addWaypoint(waypoint: Waypoint) {
        waypoints.append(waypoint)
        mapView.addAnnotation(waypoint)
    }
    
    func startWith(drone: DJIDrone, andResultHandler handler: DJIExecuteResultBlock) {
        let mission = drone.mainController.navigationManager.waypointMission
        mission.maxFlightSpeed = 14.0
        mission.autoFlightSpeed = 10.0
        mission.headingMode = .UsingWaypointHeading
        mission.finishedAction = .GoHome
        mission.addWaypoints(waypoints)
        
        if (mission.isValid) {
            mission.setUploadProgressHandler(progressHandler)
            mission.uploadMissionWithResult({ error -> Void in
                if error.errorCode == 0 {
                    mission.startMissionWithResult(handler)
                } else {
                    handler(DJIError(errorCode: 667))
                }
            })
        } else {
            handler(DJIError(errorCode: 666))
        }
    }
    
    func clear() {
        mapView.removeAnnotations(waypoints)
        waypoints.removeAll()
    }
}