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

/**
 This class reads the location of the user and shares it through Combine's PassthroughSubject.
 Once the location is started, It is possible to receive the updates calling the sink method on the subject.
 It implements CLLocationManagerDelegate protocol.
 When the app gets killed or suspended it reads the location every 200mt. or if still, every 5 min approx.
 
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
public class StreamLocation {
    public let subject = PassthroughSubject<CLLocation, Never>()
    private let foregroundLocationManager = CLLocationManager()
    private let backgroundLocationManager = CLLocationManager()
    
    private var backgroundDelegate: BackgroundLocationManagerDelegate
    private var foregroundDelegate: ForegroundLocationManagerDelegate
    
    

    public init() throws {
        backgroundDelegate = BackgroundLocationManagerDelegate.init(locationManager: backgroundLocationManager, subject: subject)
        foregroundDelegate = ForegroundLocationManagerDelegate.init(locationManager: foregroundLocationManager, subject: subject)
        try setupLocationManager(backgroundLocationManager)
        try setupLocationManager(foregroundLocationManager)
    }
    
    
    /// It starts for the first time the foreground delegate
    /// Since it is the first time, it won't stop the background delegate
    public func start() {
        foregroundDelegate.start()
    }
    
    /**
     This method stops to register the location of the user when it is in foreground, background and terminated.
     
     # Notes: #
     1.This method completely stops the location updates.
     2.This method **must** be invoked when the app should stop, otherwise it will continue to update locations.
     
     # Example: #
     \`\`\`
     let streamLocation = StreamLocation()
     streamLocation.start()
     ...
     streamLocation.stopUpdates()
     \`\`\`
     */
    public func stopUpdates() {
        foregroundDelegate.stop()
        backgroundDelegate.stop()
    }
    
    /// Starts the background manager and stops the foreground manager
    /// It will switch method used to retrive the location
    public func startBackground() {
        foregroundDelegate.stop()
        if let lastKnownLocation = foregroundLocationManager.location {
            backgroundDelegate.startMonitoring(lastKnownLocation)
        }
    }
    
    /// Starts the foreground manager and stops the background manager
    /// Call this method when the app is coming back from being closed/killed
    public func startForeground() {
        backgroundDelegate.stop()
        foregroundDelegate.start()
    }

    /**
     This method sets the delegate for the location manager, the accuracy, the distance filter,
     grants the location updates when the app is in background, sets the activity type,
     requests permission for always reading the location and calls checkLocationAuthorization().
     
     # Notes: #
     1. This method is automatically called when a new StreamLocation object is created.
     - Parameter locationManager: the location manager to setup
     */
    private func setupLocationManager(_ locationManager: CLLocationManager) throws {
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
     
     - Parameters:
     - accuracy: The accuracy you expect from the location updates.
     # Notes: #
     1.Parameter must be a **Accuracy** type.
     2. If this method is not called, the accuracy is by default set to Accuracy.foot.
     - foreground: true if this accuracy setting is meant to be for the foreground manager
     
     # Example: #
     
     \`\`\`
     let streamLocation = StreamLocation()
     streamLocation.setAccuracy(Accuracy.foot)
     \`\`\`
     */
    public func setAccuracy(_ accuracy: Accuracy, foreground: Bool) {
        switch accuracy {
        case .bike, .foot:
            if foreground {
                foregroundLocationManager.desiredAccuracy = kCLLocationAccuracyBest
            } else {
                backgroundLocationManager.desiredAccuracy = kCLLocationAccuracyBest
            }
        case .car:
            if foreground {
                foregroundLocationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            } else {
                backgroundLocationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            }
        }
    }
    
    
    
    

    
 
}
