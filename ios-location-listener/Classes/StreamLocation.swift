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
public enum Accuracy {
    case foot
    case car
    case bike
}


/**
 This class registers the location of the user, even when the app is terminated.
 
 This class reads the location of the user and shares it through Combine's PassthroughSubject.
 Once the location is started, It is possible to receive the updates calling the sink method on the subject.
 It implements both UNUserNotificationCenterDelegate and  CLLocationManagerDelegate protocols.
 When the app gets killed or suspended it reads the location every 60 seconds minimum.
 
 # Example: #
 let streamLocation = StreamLocation()
 var cancellable: AnyCancellable? = nil
 stream.startUpdatingLocations()
 DispatchQueue.main.async{
     self.cancellable = stream.subject.publisher.sink{ location in
      ...   }
 */
public class StreamLocation: NSObject, UNUserNotificationCenterDelegate, CLLocationManagerDelegate {
    
    public let subject = PassthroughSubject<CLLocation, Never>()
    private var notificationBody: String = ""
    private var notificationTitle: String = "Location Update"
    private let requestIdentifier = UUID.init().uuidString
    private var notificationTimeInterval = 60.0 // default value in seconds
    private let locationManager = CLLocationManager()
    private let minimumTimeInterval = 60.0 // in seconds
    
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        self.setupLocationManager()
    }

    /**
     This method setups the location manager.

     This method sets the delegate for the location manager, the accuracy, the distance filter, 
     grants the location updates when the app is in background, sets the activity type,
     requests permission for always reading the location and calls checkLocationAuthorization().
 
     # Notes: #
     1. This method is automatically called when a new StreamLocation object is created.
     */
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
    
    /**
    This method checks if there are the authorizations to read the location and returns.
 
    This method checks if the locations services are enabled and if it's possible to monitor the location.

     - returns:
        - True if the location services are enabled and if it's possible to monitor location changes.
        
     # Notes: #
     1.Both location services and permission to monitor location changes must be granted.
     */
    private func checkLocationAuthorization() -> Bool{
        return CLLocationManager.locationServicesEnabled() && CLLocationManager.significantLocationChangeMonitoringAvailable()
    }
    
    /**
    This method sets the title and/or the text of the notification.
 
    This method takes a value for the title and a value for the body content for the notification.
 
    - parameters:
        -title: The title you want to display in the notification.
        -body: The text content you want to display inside the notification.
 
     # Notes: #
     1.Parameters must be **String** type.
     2.Both parameters are optional. If one is set to nil, the default value is set.
     3.The default values are:
        \`\`\`
        title = "Location Update"
        body = ""
        \`\`\`
     4. This method must be called **before** invoking startUpdatingLocations()
            

     # Example: #
 
         \`\`\`
         let streamLocation = StreamLocation()
        streamLocation.setNotificationContent(title:"My First Alert", body: nil)
         \`\`\`
     */
    public func setNotificationContent(title: String?, body: String?){
        notificationTitle = title ?? notificationTitle
        notificationBody = body ?? notificationBody
    }
    
    /**
     This method sets the accuracy for the location updates.
     
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
    public func setAccuracy(accuracy: Accuracy){
        switch accuracy {
        case .bike, .foot:
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
        case .car:
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        }
    }
    
    /**
     This method sets the time interval between each notification.
 
     This method sets the time interval between each notification
     that appears when the app goes in background or is terminated.
     
     - parameters
        -timeInterval: a Double value in seconds that will pass between two notifications.
        
    # Notes: #
     1.Parameter must be **Double** type.
     2.Parameter can't be less than 60.0 seconds.
     3.If the parameter is set less than 60.0 seconds, it is automatically set to 60.0.
     
     # Example: #
     \`\`\`
     let streamLocation = StreamLocation()
     streamLocation.setNotificationTimeInterval(timeInterval: 90.0)
     \`\`\`
     */
    public func setNotificationTimeInterval(timeInterval: Double){
        if timeInterval < minimumTimeInterval {
            notificationTimeInterval = minimumTimeInterval
        } else {
            notificationTimeInterval = timeInterval
        }
    }
    
    /**
    This method requests the authorizations to schedule the launch of a new notifications.
     
    This method asks for the authorizations to display notifications and it schedule the launch of a new notification.
     
     # Notes:#
    It is possible to customize the notification using the methods:
        *setNotificationTimeInterval: to modify the time interval between each notification. The default value is 60.0 seconds.
        *setNotificationContent: to change the title and the text content of the notification
     */
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
    
    /**
     This method is called before a notification appears.
     
     This method ovverrides from the NotificationCenterDelegate protocol. This method is automatically called before the notification appears on the screen. When this method is invoked, it requests for a new location update and it sends it to the stream.
     */
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

    /**
     This method sets the trigger that will launch a notification.
     
     This method prepares a trigger that will launch a new notification. The notification can be customized with parametres passed.
    
    - parameters
        - notificationTitle: the string value for the title of the notification
        - notificationBody: the string value for the text content of the notification
        - timeInterval: the double value in seconds that will pass before a new notification will appear
        - repeats: the boolean value that will enable the repetition of the notification
 
    # Notes:#
    1.notificationTitle must be **String** type.
    2.notificationBody must be **String** type.
    3.timeInterval must be **Double** type.
    4.repeats must be **Bool** type.
     */
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
    
    /**
    This method removes both pending and delivered notifications.
    
    This method removes all the notifications, both pending (planned) and delivered.
     
     #Notes: #
    1. This method is called within stopUpdates
     */
    func removeLocalNotifications(){
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
    }

    /**
     This method starts to register the location of the user.
     
     When this method is invoked, it starts to read the location of the user and register a notification that will start to appear when the app goes in background.
     
     #Notes: #
     1. If you want to customize the notification appearance (title, content, timeInterval), you should do it before calling this method.
     
     #Example: #
     \`\`\`
        let streamLocation = StreamLocation()
        streamLocation.startUpdatingLocations()
     \`\`\`
     */
    public func startUpdatingLocations(){
        registerNotifications()
        locationManager.startMonitoringSignificantLocationChanges()
        locationManager.startUpdatingLocation()
    }
    
    /**
     This method stops to register the location of the user.
     
     When this method is invoked, it stops to read the location of the user when the app is foreground or in the background. To stop the updates also when the app is terminated, you should call stopUpdates.
 
     #Notes: #
     This method stops to read the location only when the app is in foreground or in the background, **not** when the app is terminated.
     
     #Example: #
     \`\`\`
        let streamLocation = StreamLocation()
        streamLocation.startUpdatingLocations()
        ...
        streamLocation.stopUpdatingLocations()
     \`\`\`
     */
    public func stopUpdatingLocations(){
        locationManager.stopUpdatingLocation()
    }
    
    /**
     This method stops to register the location of the user and to update the notifications.
     
     This method stops to register the location of the user when it is in foreground, background and terminated. It also removes all the notifications, both pending and delivered.
     
     #Notes: #
     1.This method completely stops the updates both of notification and location updates.
     2.This method **must** be invoked when the app should stop, otherwise it will continue to update locations and notifications.
     
     #Example: #
     \`\`\`
        let streamLocation = StreamLocation()
        streamLocation.startUpdatingLocations()
        ...
        streamLocation.stopUpdates()
    \`\`\`
     */
    public func stopUpdates(){
        stopUpdatingLocations()
        locationManager.stopMonitoringSignificantLocationChanges()
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.removeAllDeliveredNotifications()
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    /**
    This method is called when a new location is available.
     
     This method is inherited from the CLLocationManagerDelegate protocol and it is automatically called when a new location is available. If there is a new location, this method publishes it in the stream.
     
     #Notes: #
     This method shouldn't be invoked, it is automatically called by iOS.
     */
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let mLocation = locations.last {
            subject.send(mLocation)
        }
    }
    
    /**
     This method is called when an error is thrown during the reading of the location.
     
     This method is inherited from the CLLocationManagerDelegate protocol and it is automatically called when the locationManager fails.
     */
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
    
}
