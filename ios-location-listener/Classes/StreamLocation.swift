//
//  StreamLocation.swift
//  LocationListener
//
//  Created by Kuama on 29/04/21.
//
import Combine
import CoreLocation
import Foundation
import os.log
import UIKit

/// Enum for the accuracy of the location updates
public enum Accuracy {
    case foot
    case car
    case bike
}

enum AuthorizationError: Error {
    case missingPermission(String)
}

enum InvalidUpdateDelayError: Error {
    case negativeDelay(String)
}

enum Constants {
    enum Numbers {
        static let minRadius = 100.0 // in meters
        static let updateDelay = 10.0 // in seconds
    }
    
    enum ErrorDescription {
        static let negativeDelayError = "The provided delay is negative so invalid: "
    }
    
    enum Names {
        static let bkgQueueLabel = "BKG"
        static let killedUpdateDelayKey = "killedUpdateDelayKey"
    }
}


/**
 This class reads the location of the user and shares it through Combine's PassthroughSubject.
 Once the location is started, It is possible to receive the updates calling the sink method on the subject.
 It implements CLLocationManagerDelegate protocol.
 When the app gets killed or suspended it reads the location every 60 seconds minimum.
 
 # Example: #
 \`\`\`
 let streamLocation = StreamLocation()
 var cancellable: AnyCancellable? = nil
 stream.start()
 DispatchQueue.main.async{
 self.cancellable = stream.subject.publisher.sink{ location in
 ...   }
 \`\`\`
 */
@available(iOS 14.0, *)
public class StreamLocation: NSObject, CLLocationManagerDelegate {
    public let subject = PassthroughSubject<CLLocation, Never>()
    private let locationManager = CLLocationManager()

    override public init() {
        super.init()
        locationManager.delegate = self
    }
    
    public func start() throws {
        try setupLocationManager()
        startUpdatingLocations()
    }

    /**
     This method sets the delegate for the location manager, the accuracy, the distance filter,
     grants the location updates when the app is in background, sets the activity type,
     requests permission for always reading the location and calls checkLocationAuthorization().
     
     # Notes: #
     1. This method is automatically called when a new StreamLocation object is created.
     */
    private func setupLocationManager() throws {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.activityType = CLActivityType.other
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
        if !checkLocationAuthorization() {
            throw AuthorizationError.missingPermission("Please provide the GPS authorizations")
        }
    }
    
    /**
     This method checks if the locations services are enabled and if it's possible to monitor the location.
     - returns:
     - True if the location services are enabled and if it's possible to monitor location changes.
     
     # Notes: #
     1.Both location services and permission to monitor location changes must be granted.
     */
    private func checkLocationAuthorization() -> Bool {
        return CLLocationManager.locationServicesEnabled() && CLLocationManager.significantLocationChangeMonitoringAvailable()
    }
    
    /**
     This method takes a value for accuracy and set the correspondant value for the location updates.
     
     - parameters
     -accuracy: The accuracy you expect from the location updates.
     # Notes: #
     1.Parameter must be a **Accuracy** type.
     2. If this method is not called, the accuracy is by default set to Accuracy.foot.
     
     # Example: #
     
     \`\`\`
     let streamLocation = StreamLocation()
     streamLocation.setAccuracy(Accuracy.foot)
     \`\`\`
     */
    public func setAccuracy(_ accuracy: Accuracy) {
        switch accuracy {
        case .bike, .foot:
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
        case .car:
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        }
    }
    
    /**
     When this method is invoked, it starts to read the location of the user.
     
     # Example: #
     \`\`\`
     let streamLocation = StreamLocation()
     streamLocation.startUpdatingLocations()
     \`\`\`
     */
    public func startUpdatingLocations() {
        locationManager.startMonitoringSignificantLocationChanges()
        locationManager.startUpdatingLocation()
    }
    
    /**
     When this method is invoked, it stops to read the location of the user when the app is foreground or in the background. To stop the updates also when the app is terminated, you should call stopUpdates.
     
     # Notes: #
     This method stops to read the location only when the app is in foreground or in the background, **not** when the app is terminated.
     
     # Example: #
     \`\`\`
     let streamLocation = StreamLocation()
     streamLocation.startUpdatingLocations()
     ...
     streamLocation.stopUpdatingLocations()
     \`\`\`
     */
    public func stopUpdatingLocations() {
        locationManager.stopUpdatingLocation()
    }
    
    /**
     This method stops to register the location of the user when it is in foreground, background and terminated.
     
     # Notes: #
     1.This method completely stops the location updates.
     2.This method **must** be invoked when the app should stop, otherwise it will continue to update locations.
     
     # Example: #
     \`\`\`
     let streamLocation = StreamLocation()
     streamLocation.startUpdatingLocations()
     ...
     streamLocation.stopUpdates()
     \`\`\`
     */
    public func stopUpdates() {
        stopUpdatingLocations()
        locationManager.stopMonitoringSignificantLocationChanges()
        
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
    }
    
    /**
     This method is inherited from the CLLocationManagerDelegate protocol and it is automatically called when a new location is available. If there is a new location, this method publishes it in the stream.
     
     # Notes: #
     This method shouldn't be invoked, it is automatically called by iOS.
     */
    public func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let mLocation = locations.last {
            subject.send(mLocation)
            
            // start to monitor a new region centered on where the user currently is
            // and request state for the current region (in or out) that will call didDetermineState
            let newLocationCoordinate = CLLocationCoordinate2D(latitude: mLocation.coordinate.latitude, longitude: mLocation.coordinate.longitude)
            let newRegion = CLCircularRegion(center: newLocationCoordinate, radius: Constants.Numbers.minRadius, identifier: "\(mLocation)")
            locationManager.startMonitoring(for: newRegion)
            locationManager.requestState(for: newRegion)
        }
    }
    
    /**
     This method is inherited from the CLLocationManagerDelegate protocol and it is automatically called when the locationManager fails.
     */
    public func locationManager(_: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
    
    /**
     This method is inherited from the CLLocationManagerDelegate protocol and it is automatically called to check if a user is inside a certain region
     */
    public func locationManager(_ manager: CLLocationManager, didDetermineState _: CLRegionState, for region: CLRegion) {
        locationManager.requestState(for: region)
        manager.requestLocation()
        if let location = manager.location {
            subject.send(location)
        }
    }
}
