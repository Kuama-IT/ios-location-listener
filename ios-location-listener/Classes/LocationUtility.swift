//
//  LocationUtility.swift
//  LocationListener
//
//  Created by Kuama on 21/05/21.
//

import Foundation
import CoreLocation

/// Class that provides a static method to calculate a point from a given location and a converter between degrees and radians
class LocationUtility {
    
    /// Calculate a new point centered 150 meters from location and with angle bearing from location using Haversine inverted formula
    static func getCheckPointsLocation(location:CLLocation, bearing: Double)->CLLocation{
        // data
        let earthRadius = 6371e3 // in meters
        let distance = 150.0 // in meters
        let angularDistance = distance/earthRadius
        let startingLatitude = deg2rad(location.coordinate.latitude)
        let startingLongitude = deg2rad(location.coordinate.longitude)
        let mBearings = deg2rad(bearing)
        
        // new latitude
        var newLat = asin(sin(startingLatitude)*cos(angularDistance) +
                            cos(startingLatitude)*sin(angularDistance)*cos(mBearings))
        newLat = Double(round(rad2deg(newLat)*10e8)/10e8)
        // new longitude
        var newLon = startingLongitude + atan2(sin(mBearings)*sin(angularDistance)*cos(startingLatitude),
                                               cos(angularDistance)-sin(startingLatitude)*sin(newLat))
        newLon = Double(round(rad2deg(newLon)*10e8)/10e8)
        return CLLocation(latitude: newLat, longitude: newLon)
    }
    
    /// convert degrees to radians
    static func deg2rad(_ number: Double) -> Double {
        return number * .pi / 180
    }

    /// convert radians to degrees
    static func rad2deg(_ number: Double) -> Double {
        return number * 180 / .pi
    }
}

