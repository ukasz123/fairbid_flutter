require 'yaml'

# Returns the version number for a package.json file
pkg_version = lambda do 
  path = File.join(__dir__, '..', 'pubspec.yaml')
  content = YAML.load(File.read(path))
  content["version"]
end
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'fairbid_flutter'
  s.version          = pkg_version.call
  s.summary          = 'Fyber FairBid for Flutter'
  s.description      = <<-DESC
Flutter plugin for FairBid
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'UkaszApps (Lukasz Huculak)' => 'ukasz.apps@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'

  s.dependency 'Flutter'
  s.dependency 'FairBidSDK', '~> 3.2.0'

  s.ios.deployment_target = '9.0'
end

