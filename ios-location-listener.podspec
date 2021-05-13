#
# Be sure to run `pod lib lint ios-location-listener.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ios-location-listener'
  s.version          = '0.1.0'
  s.summary          = 'A small framework to monitor user position even when your app gets killed'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
    A small framework to monitor user position even when your app gets killed. It will trigger a notification to let the user know we are tracking his position when the app is killed. Of course, it lets you start and stop the location tracking.
                       DESC

  s.homepage         = 'https://github.com/Kuama-IT/ios-location-listener'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Kuama Dev Team' => 'hello@kuama.net' }
  s.source           = { :git => 'https://github.com/Kuama-IT/ios-location-listener.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'

  s.source_files = 'ios-location-listener/Classes/**/*'
  
  # s.resource_bundles = {
  #   'ios-location-listener' => ['ios-location-listener/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'UIKit', 'UserNotifications', 'Combine'
  # s.dependency 'AFNetworking', '~> 2.3'
end
