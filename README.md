# ios-location-listener
This library provides the possibility to read the user location even if the user or the system stops the app.

## Installation

ios-location-listener is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'ios-location-listener'
```

## Usage

In order to use this library you must:

1) Modify the Info.plist file as follows: a) add a new element key[NSLocationAlwaysAndWhenInUseUsageDescription] = value["Why you need to always access location"] b) add a new element key[NSLocationWhenInUseUsageDescription] = value["Why you need to always access location"]

2) Select your project, select the "Signing & Capabilities" tab, click on the "+" button and add "Background Modes". Check and activate "Location updates", "Backgroud Fetch" and "Background Processing".

3) Verify that the user has the GPS service active. 

4) Inside your project, create an instance of the class StreamLocation and a var of the type AnyCancellable.

```swift
let stream = StreamLocation()
@State var cancellable: AnyCancellable? = nil
let publisher = stream.subject
```
5) When you want to start updating the stream of the locations, simply call startUpdatingLocations on stream and read from the stream, as follows:

```swift
stream.startUpdatingLocations()
DispatchQueue.main.async{
    self.cancellable = publisher?.sink{
        s in
        print("\(s.coordinate.latitude)-\(s.coordinate.longitude)")
    }
}
```
NOTE: this will remain active even when the app is terminated unless you force closed the stream. If the app is terminated the location will be monitored every 150mt approx. - the minimum refresh is decided by iOS.

6) When you want to stop updating the stream of locations, call the method stopUpdates on stream and cancel the stream do as follows:

```swift
stream.stopUpdates()
DispatchQueue.main.async {
    self.cancellable?.cancel
```

7) By default the message in the UserNotification will be "Last position lat:\(currentLat), long: \(currentLong)". If you want to personalize it, you can call the method setAlertMessage on the stream and pass a string with the custom message you want to be displayed. 


## Author

Kuama Dev Team with ✌️

## License

ios-location-listener is available under the MIT license. See the LICENSE file for more info.
