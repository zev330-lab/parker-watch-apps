#!/usr/bin/env ruby
require 'xcodeproj'
require 'fileutils'

APPS_DIR = File.expand_path("~/dev/parker-watch-apps/Apps")
TEAM_ID   = "DU52C58N97"

apps = [
  {
    dir:          "ParkersHeart",
    project:      "ParkersHeart.xcodeproj",
    main_target:  "ParkersHeart",
    main_bundle:  "com.zevgt.parkersheart",
    ext_target:   "ParkersHeartComplication",
    ext_bundle:   "com.zevgt.parkersheart.complication",
    display_name: "Parker's Heart",
  },
  {
    dir:          "PowerUp",
    project:      "PowerUp.xcodeproj",
    main_target:  "PowerUp",
    main_bundle:  "com.zevgt.powerup",
    ext_target:   "PowerUpComplication",
    ext_bundle:   "com.zevgt.powerup.complication",
    display_name: "Power Up",
  },
  {
    dir:          "HeroGarage",
    project:      "HeroGarage.xcodeproj",
    main_target:  "HeroGarage",
    main_bundle:  "com.zevgt.herogarage",
    ext_target:   "HeroGarageComplication",
    ext_bundle:   "com.zevgt.herogarage.complication",
    display_name: "Hero Garage",
  },
  {
    dir:          "RightNow",
    project:      "RightNow.xcodeproj",
    main_target:  "RightNowComplication",
    main_bundle:  "com.zevgt.rightnow",
    ext_target:   "RightNowComplication",
    ext_bundle:   "com.zevgt.rightnow.complication",
    display_name: "Right Now",
  },
]

# Fix RightNow main target name
apps[-1][:main_target] = "RightNow"

apps.each do |app|
  proj_path = File.join(APPS_DIR, app[:dir], app[:project])
  complication_dir = File.join(APPS_DIR, app[:dir], "Complication")

  puts "\n=== #{app[:dir]} ==="

  project = Xcodeproj::Project.open(proj_path)

  # Remove existing complication target if present so we can re-add cleanly
  existing = project.targets.find { |t| t.name == app[:ext_target] }
  if existing
    existing.remove_from_project
    puts "  Removed existing complication target."
  end

  # Find main app target
  main = project.targets.find { |t| t.name == app[:main_target] }
  unless main
    puts "  ERROR: main target '#{app[:main_target]}' not found!"
    next
  end

  # Create widget extension target
  ext = project.new_target(
    :app_extension,                     # XcodeProj type
    app[:ext_target],
    :watchos,
    "10.0",
    project.products_group,
    :swift
  )

  ext.product_type = "com.apple.product-type.app-extension"

  # Build settings
  ext.build_configurations.each do |config|
    config.build_settings.merge!(
      "PRODUCT_BUNDLE_IDENTIFIER"      => app[:ext_bundle],
      "DEVELOPMENT_TEAM"               => TEAM_ID,
      "CODE_SIGN_STYLE"                => "Automatic",
      "INFOPLIST_FILE"                 => "Complication/Info.plist",
      "SWIFT_VERSION"                  => "5.0",
      "TARGETED_DEVICE_FAMILY"         => "4",
      "WATCHOS_DEPLOYMENT_TARGET"      => "10.0",
      "CURRENT_PROJECT_VERSION"        => "1",
      "MARKETING_VERSION"              => "1.0",
      "PRODUCT_NAME"                   => app[:ext_target],
      "APPLICATION_EXTENSION_API_ONLY" => "YES",
      "LD_RUNPATH_SEARCH_PATHS"        => "$(inherited) @executable_path/../../Frameworks @executable_path/../Frameworks",
    )
  end

  # Add Complication source group
  complication_group = project.main_group.new_group(
    "Complication",
    complication_dir,
    :absolute
  )

  swift_file = complication_group.new_file(
    File.join(complication_dir, "ComplicationWidget.swift")
  )
  info_plist = complication_group.new_file(
    File.join(complication_dir, "Info.plist")
  )

  # Add Swift file to sources build phase
  ext.source_build_phase.add_file_reference(swift_file)

  # Add dependency from main app to extension
  main.add_dependency(ext)

  # Add "Embed App Extensions" copy phase in main app
  embed_phase = main.build_phases.find { |p|
    p.is_a?(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase) &&
    p.name == "Embed App Extensions"
  }

  unless embed_phase
    embed_phase = project.new(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase)
    embed_phase.name = "Embed App Extensions"
    embed_phase.dst_subfolder_spec = "13" # PlugIns
    embed_phase.dst_path = ""
    main.build_phases << embed_phase
  end

  ext_ref = ext.product_reference
  build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
  build_file.file_ref = ext_ref
  build_file.settings = { "ATTRIBUTES" => ["RemoveHeadersOnCopy"] }
  embed_phase.files << build_file

  project.save
  puts "  Added #{app[:ext_target]} ✓"
end

puts "\nDone."
