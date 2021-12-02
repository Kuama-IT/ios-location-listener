Pod::Spec.new do |s|
  s.name             = 'ios-location-listener'
  s.version          = '0.4.2'
  s.summary          = 'A small framework to monitor user position even when your app is in background.'

  s.description      = <<-DESC
    A small framework to monitor user position even when your app is in background.
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
