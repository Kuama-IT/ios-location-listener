//___Created by Kuama___

import Foundation
import CoreLocation
import Combine

@available(iOS 13.0, *)
class BackgroundLocationManagerDelegate: NSObject, CLLocationManagerDelegate {
    
    private var locationManager: CLLocationManager
    private var subject: PassthroughSubject<CLLocation, Never>
    
    private let cardinalAngles = [0.0, 90.0, 180.0, 270.0]
    
    init(locationManager: CLLocationManager, subject: PassthroughSubject<CLLocation, Never>) {
        self.locationManager = locationManager
        self.subject = subject
        super.init()
        self.locationManager.delegate = self
        locationManager.startMonitoringSignificantLocationChanges()
    }
    
    
    /// This method starts to monitor regions around the position of the user.
    /// When the user exits or enters in one of those regions, a callback will be triggered.
    /// If the user doesn't change the location, every 5 min approx (Apple doc.) it will read the current position.
    ///
    /// - Parameter location: a location around which it will start to monitor regions
    func startMonitoring(_ location: CLLocation) {
        let regionsToMonitor = createRegions(location)
        for region in regionsToMonitor {
            locationManager.startMonitoring(for: region)
            region.notifyOnEntry = true
            region.notifyOnExit = true
        }
    }
    
    
    /// This method creates 5 regions.
    /// One centered in the location and other 4 in front, back, left and right of the provided location.
    ///
    /// - Parameter location: the location around which it will create the regions
    /// - Returns: a set of 5 regions containing the region centered in the provided location and 4 around it.
    func createRegions(_ location: CLLocation) -> [CLRegion] {
        var createdRegions = [CLRegion]()
        let regionCenter = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let newRegion = CLCircularRegion(center: regionCenter, radius: Constants.Numbers.minRadius, identifier: Constants.Names.regionId)
        createdRegions.append(newRegion)
        for bearing in cardinalAngles {
            let regionCenter =  LocationUtility.getCheckPointsLocation(location: location, bearing: bearing)
            
            let newRegion = CLCircularRegion(center: regionCenter, radius: Constants.Numbers.minRadius, identifier: Constants.Names.regionId + "\(bearing)")
            createdRegions.append(newRegion)
        }
        
        return createdRegions
    }
    
    
    /// The callback triggered when the user enters in a monitored region.
    /// This will stops to monitor all the regions and will request a location.
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        stopMonitoringRegions()
        locationManager.startUpdatingLocation()
    }
    
    /// The callback triggered when the user exits in a monitored region.
    /// This will stops to monitor all the regions and will request a location.
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        stopMonitoringRegions()
        locationManager.startUpdatingLocation()
    }
    
    /// The callback triggered when the location manager reads a new location.
    /// The location will be sent to the subject and it will restart to monitor regions around this location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let mLocation = locations.last {
            locationManager.stopUpdatingLocation()
            startMonitoring(mLocation)
            subject.send(mLocation)
        }
    }
    
    /// It stops to monitor all the regions currently monitored
    func stopMonitoringRegions() {
        let monitoredRegions = locationManager.monitoredRegions
        for region in monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
    }
    
    /// It stops to monitor all the regions currently monitored and it will stop also monitoring significant location changes
    func stop() {
        stopMonitoringRegions()
        locationManager.stopMonitoringSignificantLocationChanges()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
}
