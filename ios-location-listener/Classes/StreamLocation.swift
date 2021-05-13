//
// StreamLocation.swift
// StreamLocation
//
// Created by Kuama on 13/05/21.
//

import Foundation
import UIKit
import Combine
import CoreLocation

/**
 This class manages to create a stream of location that will continue to update the user even if the app is terminated
 */
public class StreamLocation: NSObject, CLLocationManagerDelegate{
    
    public var subject: PassthroughSubject<CLLocation, Never>?
    
    private let locationManager = CLLocationManager()
    
    private var alertString: String?
    private let minRadius = 1.0 // min radius for creating a new region
    private let identifier = "Location Stream"
    
    /**
     Setup the location manager and creates a PassthroughSubject that manages the stream of locations
     */
    public override init() {
        super.init()
        self.setupLocationManager()
        subject = PassthroughSubject()
    }
    
    /**
     Setup the location manager: max accuracy, asks for backgroundupdates and the permission to retrieve the location when in the state of in use and always.
     */
    private func setupLocationManager(){
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
        if(!checkAuthorization()){
            print("No location services active, please activate the GPS")
        }
        locationManager.registerNotifications()
        
    }
    
    /**
     Check if the user has the GPS active
     */
    private func checkAuthorization() -> Bool{
        return CLLocationManager.locationServicesEnabled() && CLLocationManager.significantLocationChangeMonitoringAvailable()
    }
    
    /**
     It starts to update locations
     */
    public func startUpdatingLocations(){
        locationManager.startUpdatingLocation()
    }
    
    /**
     It stops the updates of locations
     */
    public func stopUpdatingLocations(){
        locationManager.stopUpdatingLocation()
    }
    
    /**
     It stops the updates of locations and the monitoring of regions. The monitoring keeps alive the app even if it is closed
     */
    public func stopUpdates(){
        stopUpdatingLocations()
        let monitoredRegions = locationManager.monitoredRegions
        if(!monitoredRegions.isEmpty){
            for region in monitoredRegions {
                locationManager.stopMonitoring(for: region)
            }
        }
    }
    
    /**
     Inherited from the CLLocationManagerDelegate. This method is called when there is an update of location.
     */
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            
            subject?.send(location)
            if(!(UIApplication.shared.applicationState == .active)){
                self.createRegion(location: location)
            }
        }
    }
    
    /**
     Inherited from the CLLocationManagerDelegate.  This method is called when the user exits from a region. If the app was terminated, the call to scheduleLocalNotification reactivates the app to restart the location updates.
     */
    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        let circRegion = region as! CLCircularRegion
        if(alertString != nil){
            CLLocationManager.scheduleLocalNotification(manager)(alert: alertString!)
        } else {
            CLLocationManager.scheduleLocalNotification(manager)(alert: "Last position lat:\(circRegion.center.latitude) long: \(circRegion.center.longitude)")
        }
        locationManager.stopMonitoring(for: region)
        locationManager.startUpdatingLocation()
    }
    
    public func setAlertMessage(string: String){
        alertString = string
    }
    
    /**
     This method creates a region centered in the current location and it asks to be notified when the user exits from the region. The radius of the region is set to 1mt but the minimum radius is approx. 150mt and it's decided by iOS.
     */
    private func createRegion(location: CLLocation){
        if(CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self)){
            let region = CLCircularRegion(center: location.coordinate, radius: minRadius, identifier: identifier)
            region.notifyOnExit = true
            region.notifyOnEntry = false
            
            locationManager.stopUpdatingLocation()
            locationManager.startMonitoring(for: region)
        }
    }
}

