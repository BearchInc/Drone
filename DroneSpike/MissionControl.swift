import Foundation

class MissionControl {
    var waypoints = [Waypoint]()
    
    func addWaypoint(waypoint: Waypoint) {
        waypoints.append(waypoint)
    }
    
    func startWith(drone: DJIDrone) {
        // TODO
    }
    
    func clear() {
        self.waypoints.removeAll()
    }
}