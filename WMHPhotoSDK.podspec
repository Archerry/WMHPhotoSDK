#
# Be sure to run `pod lib lint WMHPhotoSDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'WMHPhotoSDK'
  s.version          = '1.0.0'
  s.summary          = '图片选择器组件'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  一个图片选择器组件,逻辑和微信一样但没有图片编辑功能
  A image picker tool，and the logic is the same as WeChat but no editing function
                       DESC

  s.homepage         = 'https://github.com/Archerry/WMHPhotoSDK'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'minhangwang' => '925592454@qq.com' }
  s.source           = { :git => 'https://github.com/Archerry/WMHPhotoSDK.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'

  s.source_files = 'Sources/**/*.{swift,h,m}'
  s.public_header_files = "Sources/*.h"
  
  s.swift_version = '5.3'
  s.static_framework = true

  s.dependency 'SnapKit'
  s.dependency 'EGOCache', '~> 2.1.3'
  
  s.resource_bundles = {
      'WMHPhotoAssets' => ['Sources/*.{xcassets,xib}']
  }
end

