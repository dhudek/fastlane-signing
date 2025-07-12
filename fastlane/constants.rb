# Constants for download_provisions
MOBILEPROVISION_EXT = '.mobileprovision'.freeze
DEFAULT_API_KEY_DURATION = 500

# Constants for common values
NO_BUNDLE_ID = 'no_bundle_id'.freeze
MAIN_PLIST_PATH = 'Payload/*.app/Info.plist'.freeze
NOTIFICATION_PLIST_PATH = 'Payload/*.app/PlugIns/Notification*.appex/Info.plist'.freeze

# spaceship requires a tmp directory windows needs it? i guess
FileUtils.mkdir_p("/tmp/") 

# Set locale environment variables
ENV['LC_ALL'] = 'en_US.UTF-8'
ENV['LANG'] = 'en_US.UTF-8'

# Define paths
PATHS = {}
PATHS[:fast_file_dir] = Dir.pwd
PATHS[:root_dir] = File.dirname(PATHS[:fast_file_dir])
PATHS[:profile_path] = File.join(PATHS[:root_dir], 'profiles')
PATHS[:log_path] = File.join(PATHS[:root_dir], 'logs')
PATHS[:in_path] = File.join(PATHS[:root_dir], 'apps/in')
PATHS[:out_path] = File.join(PATHS[:root_dir], 'apps/out')
PATHS[:keys_path] = File.join(PATHS[:root_dir], 'keys')
PATHS[:keychain_path] = ENV['KEYCHAIN_PATH'] || "~/Library/Keychains/login.keychain-db"
PATHS[:keychain_password] = ENV['KEYCHAIN_PASSWORD'] # store in env variable
PATHS[:lock_file] = ENV['LOCK_FILE'] || '.lockfile'
PATHS[:username] = ENV['USERNAME'] || 'your_apple_id@example.com'

# used for testing ignore.
APP_LIST = {
  'content' => [
    {
      'versionId' => '',
      'application_id' => '',
      'package_id' => '',
      'bundle_id' => 'bundle id of the application',
      'platform' => 'i or a',
    }
  ],
  'pagination' => {
    'limit' => 20,
    'offset' => 0,
    'total' => 1
  }
}

APP_DOWNLOAD_RESPONSE = {
  response: '200',
  directory_in_path: File.join(PATHS[:root_dir], '/apps/in/'),
  directory_out_path: File.join(PATHS[:root_dir], '/apps/out/'),
  app_file: 'random_application.ipa'
}

# Default credentials for iOS
# creds[:connect_type] = "api_key" or leave blank for username/password auth 
# creds[:key_id] = "can be found when you create api key in appstore connect"
# creds[:issuer_id] = "can be found when you create api key in appstore connect"
# creds[:in_house] = true # if account is enterprise should be true, otherwise false
# creds[:key_filepath] = locatoin of your p8 file from appstore connect api
# creds[:sign_identity] = 'signing identy from certificate in keychain'
# creds[:team_id] = 'team id from developer.apple.com'
# creds[:team_name] = 'team name from developer.apple.com'
