source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '12.0'
use_frameworks!
inhibit_all_warnings!

# MARK: - AppTest Pods

target 'AppTest' do
    # here maps
    # https://developer.here.com/documentation/ios-premium/3.16/dev_guide/topics/user-guide.html
    pod 'HEREMaps'
end

# MARK: - Post Install

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
            config.build_settings['EXCLUDED_ARCHS[sdk=watchsimulator*]'] = 'arm64'
            config.build_settings['EXCLUDED_ARCHS[sdk=appletvsimulator*]'] = 'arm64'
        end
    end
end
