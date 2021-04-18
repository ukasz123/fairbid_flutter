#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'fairbid_flutter'
  s.version          = '0.0.1'
  s.summary          = 'Fyber FairBid for Flutter'
  s.description      = <<-DESC
Flutter plugin for FairBid 2.x.x
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'UkaszApps (Lukasz Huculak)' => 'ukasz.apps@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'

  s.dependency 'Flutter'
  s.dependency 'FairBidSDK', '~> 3.14.0'

  s.ios.deployment_target = '9.0'
end

