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
    private let minRadius = 100.0 // min radius for creating a new region
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
        locationManager.activityType = CLActivityType.other
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
        locationManager.startMonitoringSignificantLocationChanges()
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
    func stopUpdates(){
        stopUpdatingLocations()
        removeMonitoredRegions()
        locationManager.stopMonitoringSignificantLocationChanges()
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.removeAllDeliveredNotifications()
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    /**
     Inherited from the CLLocationManagerDelegate. This method is called when there is an update of location.
     */
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            
            subject?.send(location)
            if(!(UIApplication.shared.applicationState == .active)){
                self.createMonitoredRegions(location: mLocation)
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
    
    /**
     Inherited from the CLLocationManagerDelegate.  This method is called when the user enters in a region. If the app was terminated, the call to scheduleLocalNotification reactivates the app to restart the location updates.
     */
    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        let circRegion = region as! CLCircularRegion
        if(alertString != nil){
            CLLocationManager.scheduleLocalNotification(manager)(alert: alertString!)
        } else {
            CLLocationManager.scheduleLocalNotification(manager)(alert: "Last position lat:\(circRegion.center.latitude) long: \(circRegion.center.longitude)")
        }
        locationManager.stopMonitoring(for: region)
        locationManager.startUpdatingLocation()
    }
    
    /// Inherited from the CLLocationManagerDelegate. This method is called when there is an update of location.
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
    
    /// If set, it changes the alert message that will be displayed in the alert
    public func setAlertMessage(string: String){
        alertString = string
    }
    
    /*
     It creates three new regions in front, at the right and at the left of the current position
     based on the direction in which the user is currently moving
     */
    func createMonitoredRegions(location: CLLocation){
        if(CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self)){
          
            var regions = Set<CLCircularRegion>()

            // region centered in the current position
            let mRegion = createRegion(location: location, radius: minRadius, id: identifier)
            regions.update(with: mRegion)
            
            // region in front of the current position
            let nBearing = location.course
            let nLocation = LocationUtility.getCheckPointsLocation(location: location, bearing: nBearing)
            let nRegion = createRegion(location: nLocation, radius: minRadius, id: "n" + identifier)
            regions.update(with: nRegion)
            
            // region on the right of the current position
            let eBearing = location.course + 90
            let eLocation = LocationUtility.getCheckPointsLocation(location: location, bearing: eBearing)
            let eRegion = createRegion(location: eLocation, radius: minRadius, id: "e" + identifier)
            regions.update(with: eRegion)

            // region on the left of the current position
            let wBearing = location.course - 90
            let wLocation = LocationUtility.getCheckPointsLocation(location: location, bearing: wBearing)
            let wRegion = createRegion(location: wLocation, radius: minRadius, id: "w" + identifier)
            regions.update(with: wRegion)

            
            locationManager.stopUpdatingLocation()
            for region in regions {
                locationManager.startMonitoring(for: region)
            }
        }
    }
    
    /**
     This method creates a region centered in the current location and it asks to be notified when the user exits from the region. The radius of the region is set to 1mt but the minimum radius is approx. 150mt and it's decided by iOS.
     */
    private func createRegion(location: CLLocation, radius: Double, id: String)-> CLCircularRegion{
        let region = CLCircularRegion(center: location.coordinate, radius: minRadius, identifier: id)
        region.notifyOnEntry = true
        region.notifyOnExit = true
        return region
    }
    
    /// It removes all monitored regions
    private func removeMonitoredRegions(){
        let monitoredRegions = locationManager.monitoredRegions
        for region in monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
    }

}

