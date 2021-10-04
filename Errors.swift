//___Created by Kuama___

import Foundation

enum AuthorizationError: Error {
    case missingPermission(String)
}

enum InvalidUpdateDelayError: Error {
    case negativeDelay(String)
}
