# Unzips an IPA file and identifies bundle IDs for main and notification extensions
def identify_bundles(app_config, profiles)
  temp_dir = File.join(PATHS[:root_dir], "_unpackaged_#{SecureRandom.hex(8)}")
  ipa_file_path = File.join(app_config[:directory_in_path], app_config[:app_file])

  logger.debug "IPA file path: #{ipa_file_path}"
  logger.debug "Temporary directory: #{temp_dir}"

  main_bundle_id = identify_bundle_id(ipa_file_path, MAIN_PLIST_PATH, temp_dir)
  notification_bundle_id = identify_bundle_id(ipa_file_path, NOTIFICATION_PLIST_PATH, temp_dir)

  logger.debug "Main bundle ID: #{main_bundle_id}"
  logger.debug "Notification bundle ID: #{notification_bundle_id}"

  build_bundle_mapping(main_bundle_id, notification_bundle_id, app_config[:app_id], profiles)
rescue Errno::ENOENT => e
  logger.error "File operation failed: #{e.message}"
  raise
rescue StandardError => e
  logger.error "Error identifying bundles: #{e.message}"
  raise
ensure
  FileUtils.rm_rf(temp_dir) if temp_dir && Dir.exist?(temp_dir)
end

# Identifies CFBundleIdentifier from an IPA file's Info.plist using rubyzip
def identify_bundle_id(ipa_file_path, plist_pattern, temp_dir)
  unless File.exist?(ipa_file_path)
    logger.warn "IPA file not found: #{ipa_file_path}"
    return NO_BUNDLE_ID
  end

  FileUtils.mkdir_p(temp_dir)
  plist_file = nil
  begin
    Zip::File.open(ipa_file_path) do |zip_file|
      entry = zip_file.glob(plist_pattern).first
      next unless entry

      plist_file = File.join(temp_dir, 'Info.plist')
      File.write(plist_file, entry.get_input_stream.read)
    end
  rescue Zip::Error => e
    logger.warn "Failed to unzip IPA for pattern: #{plist_pattern}: #{e.message}"
    return NO_BUNDLE_ID
  end

  unless plist_file && File.exist?(plist_file)
    logger.warn "Info.plist not found for pattern: #{plist_pattern}"
    return NO_BUNDLE_ID
  end

  plist = CFPropertyList::List.new(file: plist_file)
  data = CFPropertyList.native_types(plist.value)
  data['CFBundleIdentifier'] || NO_BUNDLE_ID
rescue CFPropertyList::ParseError => e
  logger.error "Failed to parse Info.plist: #{e.message}"
  NO_BUNDLE_ID
rescue StandardError => e
  logger.error "Error in identify_bundle_id: #{e.message}"
  NO_BUNDLE_ID
end

private

# Builds mapping of bundle IDs to provisioning profiles
def build_bundle_mapping(main_bundle_id, notification_bundle_id, app_id, profiles)
  if notification_bundle_id != NO_BUNDLE_ID
    notification_profile = profiles.find { |profile| profile.downcase.include?('notification') }
    return {} unless notification_profile

    main_profile_index = profiles.index(notification_profile) - 1
    main_profile = main_profile_index >= 0 ? profiles[main_profile_index] : profiles.first

    {
      main_bundle_id => main_profile,
      notification_bundle_id => notification_profile
    }
  else
    bundle_id = main_bundle_id == NO_BUNDLE_ID ? app_id : main_bundle_id
    { bundle_id => profiles.first }
  end
end