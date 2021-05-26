//
//  LocationRequest.swift
//  LocationListener
//
//  Created by Kuama on 29/04/21.
//

import Foundation
import UIKit
import CoreLocation
import Combine

/// Enum for the accuracy of the location updates
enum Accuracy {
    case foot
    case car
    case bike
}

/// This class implements both UNUserNotificationCenterDelegate and  CLLocationManagerDelegate protocols.
/// It manages to read a stream of location both in foreground and background.
/// When the app gets killed or suspended it reads the location every 60 seconds minimum.
class StreamLocation: NSObject, UNUserNotificationCenterDelegate, CLLocationManagerDelegate {
    
    public let subject = PassthroughSubject<CLLocation, Never>()
    private var notificationBody: String = ""
    private var notificationTitle: String = "Location Update"
    private let requestIdentifier = UUID.init().uuidString
    private var notificationTimeInterval = 60.0
    private let locationManager = CLLocationManager()
    
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        self.setupLocationManager()
    }

    /// It sets up the location manager
    private func setupLocationManager(){
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.activityType = CLActivityType.other
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
        if(!checkLocationAuthorization()){
            print("Provide authorizations")
        }
    }
    
    /// Checks if we have the authorizations for retrieving the location
    private func checkLocationAuthorization() -> Bool{
        return CLLocationManager.locationServicesEnabled() && CLLocationManager.significantLocationChangeMonitoringAvailable()
    }
    
    /// Set the title and/or the body of the notification.
    public func setNotificationContent(title: String?, body: String?){
        notificationTitle = title ?? notificationTitle
        notificationBody = body ?? notificationBody
    }
    
    /// Set the accuracy for the locations updates.
    public func setAccuracy(accuracy: Accuracy){
        switch accuracy {
        case .bike, .foot:
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
        case .car:
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        }
    }
    
    /// It sets the notifications time interval. If it is less than 60 seconds, it will be set to 60 seconds.
    public func setNotificationTimeInterval(timeInterval: Double){
        if timeInterval < 60.0 {
            notificationTimeInterval = 60.0
        } else {
            notificationTimeInterval = timeInterval
        }
    }
    
    /// It requests the authorizations for displaying the notifications and schedule to launch a new notification
    func registerNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { (granted:Bool, error:Error?) in
            if error != nil { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
        UNUserNotificationCenter.current().delegate = self
        showNotification(notificationTitle: notificationTitle, notificationBody: notificationBody, timeInterval: notificationTimeInterval, repeats: true)
        locationManager.requestLocation()
    }
    
    /// Method overriden from the NotificationCenterDelegate, it is called before a notification will appear
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        locationManager.requestLocation()
        if let location = locationManager.location {
            subject.send(location)
        }
        // if there's already a notification displayed, no new notifications will appear
        UNUserNotificationCenter.current().getDeliveredNotifications(completionHandler: {notification in
            if !notification.isEmpty {
                UNUserNotificationCenter.current().removeAllDeliveredNotifications()
            }
        })
    }

    /// It plans to launch a notification
    func showNotification(notificationTitle: String, notificationBody: String, timeInterval: Double, repeats: Bool) {
        let content = UNMutableNotificationContent()
        let requestIdentifier = UUID.init().uuidString
        
        content.badge = 0
        content.title = notificationTitle
        content.body = notificationBody
        
        let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: timeInterval, repeats: repeats)
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        let request = UNNotificationRequest(identifier: requestIdentifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { (error:Error?) in
            print("Notification Register Success")
        }
        
    }
    
    /// Remove all the notifications, both pending and delivered
    func removeLocalNotifications(){
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
    }

    /// Start updating locations
    public func startUpdatingLocations(){
        registerNotifications()
        locationManager.startMonitoringSignificantLocationChanges()
        locationManager.startUpdatingLocation()
    }
    
    /// Stop updating locations
    public func stopUpdatingLocations(){
        locationManager.stopUpdatingLocation()
    }
    
    /// Stop both locations and notifications updates
    public func stopUpdates(){
        stopUpdatingLocations()
        locationManager.stopMonitoringSignificantLocationChanges()
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.removeAllDeliveredNotifications()
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    /// When it receives a new locations, it send it through the subject
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let mLocation = locations.last {
            subject.send(mLocation)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
    
}
