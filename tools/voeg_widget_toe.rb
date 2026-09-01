# Voegt de YfWidget WidgetKit-extensie toe aan Runner.xcodeproj (eenmalig).
# Draait op Linux met de xcodeproj-gem — geen Mac/Xcode nodig.
require 'xcodeproj'

pad = '/opt/yessfish-flutter-app/ios/Runner.xcodeproj'
project = Xcodeproj::Project.open(pad)

if project.targets.any? { |t| t.name == 'YfWidget' }
  puts 'YfWidget-target bestaat al — niets te doen.'
  exit 0
end

runner = project.targets.find { |t| t.name == 'Runner' }
raise 'Runner-target niet gevonden' unless runner

target = project.new_target(:app_extension, 'YfWidget', :ios, '16.0')

# Bestandsgroep + bronbestanden.
groep = project.main_group.new_group('YfWidget', 'YfWidget')
swift = groep.new_file('YfWidget.swift')
groep.new_file('Info.plist')
groep.new_file('YfWidget.entitlements')
target.add_file_references([swift])

# Generated.xcconfig als basis zodat $(FLUTTER_BUILD_NAME/NUMBER) resolven —
# de extensie-versie MOET gelijk zijn aan de app-versie (App Store-eis).
generated = project.files.find { |f| f.path == 'Flutter/Generated.xcconfig' }

target.build_configurations.each do |config|
  config.base_configuration_reference = generated if generated
  bs = config.build_settings
  bs['PRODUCT_BUNDLE_IDENTIFIER'] = 'nl.sbuilder.yessfish.YfWidget'
  bs['INFOPLIST_FILE'] = 'YfWidget/Info.plist'
  bs['CODE_SIGN_ENTITLEMENTS'] = 'YfWidget/YfWidget.entitlements'
  bs['SWIFT_VERSION'] = '5.0'
  bs['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
  bs['TARGETED_DEVICE_FAMILY'] = '1,2'
  bs['PRODUCT_NAME'] = '$(TARGET_NAME)'
  bs['SKIP_INSTALL'] = 'YES'
  bs['CURRENT_PROJECT_VERSION'] = '$(FLUTTER_BUILD_NUMBER)'
  bs['MARKETING_VERSION'] = '$(FLUTTER_BUILD_NAME)'
  bs['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks', '@executable_path/../../Frameworks']
  bs['ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME'] = ''
  bs['ASSETCATALOG_COMPILER_WIDGET_BACKGROUND_COLOR_NAME'] = ''
  bs['GENERATE_INFOPLIST_FILE'] = 'NO'
end

# Inbedden in de app + bouwvolgorde.
runner.add_dependency(target)
embed = runner.copy_files_build_phases.find { |p| p.symbol_dst_subfolder_spec == :plug_ins } ||
        runner.new_copy_files_build_phase('Embed Foundation Extensions')
embed.symbol_dst_subfolder_spec = :plug_ins
bf = embed.add_file_reference(target.product_reference)
bf.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }

project.save
puts 'YfWidget-target toegevoegd en ingebed in Runner.'
