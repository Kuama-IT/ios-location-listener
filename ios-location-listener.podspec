Pod::Spec.new do |s|
  s.name             = 'ios-location-listener'
  s.version          = '0.2.0'
  s.summary          = 'A small framework to monitor user position even when your app gets killed'

  s.description      = <<-DESC
    A small framework to monitor user position even when your app gets killed. It will trigger a notification to let the user know we are tracking his position when the app is killed. Of course, it lets you start and stop the location tracking.
                       DESC

  s.homepage         = 'https://github.com/Kuama-IT/ios-location-listener'
  
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Kuama Dev Team' => 'hello@kuama.net' }
  s.source           = { :git => 'https://github.com/Kuama-IT/ios-location-listener.git', :tag => s.version.to_s }
  

  s.ios.deployment_target = '13.0'

  s.source_files = 'ios-location-listener/Classes/**/*'
  s.frameworks = 'UIKit', 'UserNotifications', 'Combine'
  s.swift_versions = '5.0'
end
