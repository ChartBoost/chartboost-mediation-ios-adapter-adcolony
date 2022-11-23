Pod::Spec.new do |spec|
  spec.name        = 'ChartboostHeliumAdapterAdColony'
  spec.version     = '4.4.9.0.0'
  spec.license     = { :type => 'MIT', :file => 'LICENSE.md' }
  spec.homepage    = 'https://github.com/ChartBoost/helium-ios-adapter-adcolony'
  spec.authors     = { 'Chartboost' => 'https://www.chartboost.com/' }
  spec.summary     = 'Helium iOS SDK AdColony adapter.'
  spec.description = 'AdColony adapters for mediating through Helium. Supported ad formats: Banner, Interstitial, and Rewarded.'

  # Source
  spec.module_name  = 'HeliumAdapterAdColony'
  spec.source       = { :git => 'https://github.com/ChartBoost/helium-ios-adapter-adcolony.git', :tag => '#{spec.version}' }
  spec.source_files = 'Source/**/*.{swift}'
  spec.static_framework = true

  # Minimum supported versions
  spec.swift_version         = '5.0'
  spec.ios.deployment_target = '10.0'

  # System frameworks used
  spec.ios.frameworks = ['Foundation', 'UIKit']
  
  # This adapter is compatible with all Helium 4.X versions of the SDK.
  spec.dependency 'ChartboostHelium', '~> 4.0'

  # Partner network SDK and version that this adapter is certified to work with.
  spec.dependency 'AdColony', '4.9.0'
end
