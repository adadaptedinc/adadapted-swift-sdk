Pod::Spec.new do |s|
  s.name             = 'adadapted-swift-sdk'
  s.version          = '1.0.6'
  s.summary          = 'adadapted-swift-sdk'

  s.source           = { :git => 'https://github.com/smaksymov/adadapted-swift-sdk', :tag => s.version.to_s }
  s.resource_bundles = {"Privacy" => ["adadapted-swift-sdk/PrivacyInfo.xcprivacy"]}

  s.ios.deployment_target = '13.0'
  s.swift_version    = '5.0'
  s.static_framework = true

  s.source_files = 'Sources/adadapted-swift-sdk/**/*'

  s.resources = "Sources/adadapted-swift-sdk/Assets/**/*.xib"

  s.dependency 'SwiftLog'

end
