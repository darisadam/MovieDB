platform :ios, '15.0'
inhibit_all_warnings!

project 'MovieDB.xcodeproj'

target 'MovieDB' do
  # Poster, backdrop and profile images with memory and disk cache.
  pod 'SDWebImage', '~> 5.21'

  # In-app inspector for views, network and the file system. Debug builds only.
  pod 'FLEX', '~> 5.22', :configurations => ['Debug']

  target 'MovieDBTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
    end
  end
end
