#
# Be sure to run `pod lib lint WhiteCombinePlayer.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'WhiteCombinePlayer'
  s.version          = '0.1.0'
  s.summary          = 'let WhiteSDK\'s WhitePlayer and AVPlayer play and stop together'

  s.description      = <<-DESC
提供同步 Video 和 WhiteSDK WhitePlayer 播放状态功能，开放源码
                       DESC

  s.homepage         = 'https://github.com/netless-io/WhiteCombinePlayer'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'leavesster' => '11785335+leavesster@users.noreply.github.com' }
  s.source           = { :git => 'https://github.com/netless-io/WhiteCombinePlayer.git', :tag => s.version.to_s }
  s.ios.deployment_target = '9.0'

  s.source_files = 'WhiteCombinePlayer/Classes/**/*'
  
  # s.resource_bundles = {
  #   'WhiteCombinePlayer' => ['WhiteCombinePlayer/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'UIKit', 'AVFoundation'
  s.dependency 'White-SDK-iOS', '~> 2.1.0'
end
