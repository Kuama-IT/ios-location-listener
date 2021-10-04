//___Created by Kuama___

import Foundation
import CoreLocation
import Combine

@available(iOS 13.0, *)
class ForegroundLocationManagerDelegate: NSObject, CLLocationManagerDelegate {
    
    private var locationManager: CLLocationManager
    private var subject: PassthroughSubject<CLLocation, Never>
    
    init(locationManager: CLLocationManager, subject: PassthroughSubject<CLLocation, Never>) {
        self.locationManager = locationManager
        self.subject = subject
        super.init()
        self.locationManager.delegate = self
    }
    
    /// It will start to read the current position of the user with the best accuracy possible
    func start() {
        locationManager.startUpdatingLocation()
    }
    
    /// It will stop to read the current position of the user
    func stop() {
        locationManager.stopUpdatingLocation()
    }
    
    /// Callback triggered when a new location is available.
    /// It publishes a new location on the subject.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let mLocation = locations.last {
            subject.send(mLocation)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
}
