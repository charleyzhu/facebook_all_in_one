#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint facebook_all_in_one.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'facebook_all_in_one'
  s.version          = '0.0.2'
  s.summary          = 'FaceBook Plugin All in One'
  s.description      = <<-DESC
  aceBook Plugin All in One.
                       DESC
  s.homepage         = 'https://github.com/charleyzhu/facebook_all_in_one'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'VistaTeam' => '2555085@gmai.com,hqg931907015' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'

  s.dependency 'FBSDKCoreKit', '~> 11.0.0'
  s.dependency 'FBSDKLoginKit','~> 11.0.0'

  s.platform = :ios, '9.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
end
