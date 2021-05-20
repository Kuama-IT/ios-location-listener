//
//  UserNotificationDelegate.swift
//  
//
//  Created by Kuama on 13/05/21.
//

import Foundation
import CoreLocation
import UIKit
import UserNotifications

/**
 This extension provides the possibility to create notifications that keeps alive the location updates even if the app is terminated.
 */
extension CLLocationManager: UNUserNotificationCenterDelegate {
    
    func registerNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.badge]) { (granted:Bool, error:Error?) in
            if error != nil { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
        UNUserNotificationCenter.current().delegate = self
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.badge)
    }
    
    func scheduleLocalNotification(alert:String) {
        let content = UNMutableNotificationContent()
        let requestIdentifier = UUID.init().uuidString
        
        content.badge = 0
        content.title = "Location Update"
        content.body = alert
        
        let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 1.0, repeats: false)
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        let request = UNNotificationRequest(identifier: requestIdentifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { (error:Error?) in
            print("Notification Register Success")
        }
    }
    
    func removeLocalNotifications(){
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getPendingNotificationRequests(completionHandler: {
            _ in
            notificationCenter.removeAllPendingNotificationRequests()
        })
    }
    
}

