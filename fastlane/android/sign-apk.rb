####
# Main function to sign an APK.
# This function orchestrates the zipalign, sign, and verify process.
####
def sign_apk(app)
  begin
    aligned_apk_path = zipalign_apk(app)
    app[:aligned_apk_path] = aligned_apk_path # Add the new path to the app hash

    signed_apk_path = sign_apk_file(app)
    logger.info "Successfully signed APK: #{signed_apk_path}"

    verification_result = verify_apk(app)
    logger.info "Verification result: #{verification_result}"

    # Rename the signed apk to its original filename in the output directory
    final_apk_path = File.join(app[:directory_out_path], app[:app_file])
    FileUtils.mv(signed_apk_path, final_apk_path)
    logger.info "Replaced original APK with signed version."

  rescue StandardError => e
    logger.error "Error in the APK signing process: #{e.message}"
    # Re-raise the exception to stop the lane
    raise
  end
end

####
# Zipalign the APK.
# This creates a new, aligned APK file.
####
def zipalign_apk(app)
  original_apk_path = File.join(app[:directory_in_path], app[:app_file])

  # Create the aligned APK in the output directory
  aligned_filename = app[:app_file].gsub('.apk', '-aligned.apk')
  aligned_apk_path = File.join(app[:directory_out_path], aligned_filename)

  # Store original path for later
  app[:original_apk_path] = original_apk_path

  logger.info "Aligning APK: #{original_apk_path}"

  # Ensure the old aligned file doesn't exist
  FileUtils.rm_f(aligned_apk_path)

  zipalign_cmd = [
    'zipalign',
    '-f', # Overwrite output file if it exists
    '-v', # Verbose output
    '4',
    original_apk_path,
    aligned_apk_path
  ]

  sh(zipalign_cmd, log: true) # Log the output for debugging

  logger.info "Successfully aligned APK to: #{aligned_apk_path}"
  return aligned_apk_path

rescue StandardError => e
  logger.error "Failed to zipalign APK. Error: #{e.message}"
  raise # Propagate the error
end

####
# Sign the aligned APK file.
####
def sign_apk_file(app)
  aligned_apk_path = app[:aligned_apk_path]
  logger.info "Signing APK: #{aligned_apk_path}"

  # Use an array for the command to handle spaces in paths correctly
  sign_cmd = [
    'apksigner', 'sign', '-v',
    '--ks', app[:keystore_path],
    '--ks-key-alias', app[:alias_name],
    '--ks-pass', "pass:#{app[:storepass]}",
    '--key-pass', "pass:#{app[:keypass]}",
    aligned_apk_path
  ]

  sh(sign_cmd.join(" "), log: true) # Using join here as sh with array has issues with pass:

  logger.info "APK signing command executed."
  return aligned_apk_path # Return path of the now-signed APK

rescue StandardError => e
  logger.error "Failed to sign APK. Error: #{e.message}"
  raise
end

####
# Verify the signature of the signed APK.
####
def verify_apk(app)
  signed_apk_path = app[:aligned_apk_path]
  logger.info "Verifying APK: #{signed_apk_path}"

  verify_cmd = ['apksigner', 'verify', '-v', signed_apk_path]

  output = sh(verify_cmd, log: true)

  # Check if the output contains "Verified"
  if output.include?("Verified")
    return "APK signature is valid."
  else
    raise "APK signature verification failed."
  end

rescue StandardError => e
  logger.error "Failed to verify APK. Error: #{e.message}"
  raise
end