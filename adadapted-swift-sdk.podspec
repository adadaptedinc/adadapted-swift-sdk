Pod::Spec.new do |s|
  s.name             = 'adadapted-swift-sdk'
  s.version          = '1.0.6'
  s.summary          = 'adadapted-swift-sdk'

  s.homepage         = 'https://github.com/smaksymov/adadapted-swift-sdk'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Stepan Maksymov' => 'maksymov.steve@gmail.com' }
  s.source           = { :git => 'https://github.com/smaksymov/adadapted-swift-sdk.git', :tag => s.version.to_s }

  s.resource_bundles = {"Privacy" => ["adadapted-swift-sdk/PrivacyInfo.xcprivacy"]}

  s.ios.deployment_target = '13.0'
  s.swift_version    = '5.0'
  s.static_framework = true

  s.source_files = 'Sources/adadapted-swift-sdk/core/**/*'

  s.resources = "Sources/adadapted-swift-sdk/Assets.xcassets/**/*.xib"

  s.dependency 'SwiftLog'

end
