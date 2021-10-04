//___Created by Kuama___

import Foundation

enum Constants {
    enum Numbers {
        static let minRadius = 100.0 // in meters
        static let updateDelay = 10.0 // in seconds
    }
    
    enum ErrorDescription {
        static let negativeDelayError = "The provided delay is negative so invalid: "
    }
    
    enum Names {
        static let regionId = "ios-location-listener"
        static let bkgQueueLabel = "BKG"
        static let killedUpdateDelayKey = "killedUpdateDelayKey"
    }
}

/// Enum for the accuracy of the location updates
public enum Accuracy {
    case foot
    case car
    case bike
}

