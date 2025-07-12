# Download_provisions method
def download_provisions(app_config)
  # Only convert to array if not nil and not empty
  profile_ids = if app_config[:signing_provision_profiles]&.any?
    Array(app_config[:signing_provision_profiles]).reject(&:nil?).reject(&:empty?)
  else
    []
  end

  # Add fallback ID if profile_ids is empty
  fallback_id = app_config[:app_id]
  profile_ids << fallback_id if profile_ids.empty? && fallback_id && !fallback_id.empty?
  raise ArgumentError, "No provisioning profile IDs provided, app_config: #{app_config.inspect}" if profile_ids.empty?

  downloaded_profiles = []
  profile_ids.each_with_index do |profile_id, index|
    raise ArgumentError, "Invalid profile_id: #{profile_id}" if profile_id.nil? || profile_id.empty?
    filename = "#{profile_id}#{MOBILEPROVISION_EXT}"
    output_path = PATHS[:profile_path]
    profile_full_path = File.join(output_path, filename)

    logger.info "Downloading profile ##{index + 1}  for ID: #{profile_id}"

    FileUtils.mkdir_p(output_path)

    if app_config[:connect_type] == 'api_key'
      validate_api_key_config(app_config)
      logger.info "Calling app_store_connect_api_key with key_id: #{app_config[:key_id]}, issuer_id: #{app_config[:issuer_id]}, key_filepath: #{app_config[:key_filepath]}"
      begin
        app_store_connect_api_key(
          key_id: app_config[:key_id],
          issuer_id: app_config[:issuer_id],
          key_filepath: app_config[:key_filepath],
          duration: app_config[:api_key_duration] || DEFAULT_API_KEY_DURATION,
          in_house: app_config[:in_house] || false
        )
      rescue NameError => e
        logger.error "app_store_connect_api_key not found: #{e.message}. Ensure Fastlane is updated or the plugin is installed."
        raise
      rescue StandardError => e
        logger.error "Failed to set up App Store Connect API key: #{e.message}"
        raise
      end
    end

    begin
      sigh(
        readonly: true,
        app_identifier: profile_id,
        username: PATHS[:username],
        team_id: app_config[:team_id],
        team_name: app_config[:team_name],
        output_path: output_path,
        filename: filename,
        skip_install: true,
        skip_certificate_verification: true
      )
      raise StandardError, "Profile not found at #{profile_full_path}" unless File.exist?(profile_full_path)
      downloaded_profiles << profile_full_path
    rescue FastlaneCore::Interface::FastlaneError => e
      logger.error "Failed to download profile for #{profile_id}: #{e.message}"
      raise
    end
  rescue StandardError => e
    logger.error "Error downloading profile ##{index + 1} (#{profile_id}): #{e.message}"
    raise
  end

  downloaded_profiles
end

private
# Validates App Store Connect API key configuration
def validate_api_key_config(app_config)
  missing_keys = %i[key_id issuer_id key_filepath].reject { |key| app_config[key] }
  unless missing_keys.empty?
    logger.error "Missing API key fields: #{missing_keys.join(', ')}"
    raise ArgumentError, "Missing API key fields: #{missing_keys.join(', ')}"
  end
  unless File.exist?(app_config[:key_filepath])
    logger.error "API key file not found: #{app_config[:key_filepath]}"
    raise ArgumentError, "API key file not found: #{app_config[:key_filepath]}"
  end
end