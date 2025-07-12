# A helper class to write to multiple IO streams simultaneously.
class MultiIO
  def initialize(*targets)
    @targets = targets
  end

  def write(*args)
    @targets.each { |t| t.write(*args) }
  end

  def close
    @targets.each(&:close)
  end
end

# Centralized logger instance.
# This method provides a singleton logger instance that logs to both
# the terminal and a date-stamped file.
def logger
  @logger ||= begin
    # Ensure the log directory from PATHS exists before creating the log file.
    log_directory = PATHS[:log_path]
    FileUtils.mkdir_p(log_directory) unless File.directory?(log_directory)
    
    log_filename = "#{Date.today.strftime('%d-%m-%Y')}-fastlane.log"
    log_file_path = File.join(log_directory, log_filename)
    
    # Create a log device that writes to both the file and STDOUT.
    log_file = File.open(log_file_path, 'a')
    log_file.sync = true # Ensure logs are written immediately.
    multi_io = MultiIO.new(STDOUT, log_file)
    
    log = Logger.new(multi_io)
    log.formatter = proc do |severity, datetime, progname, msg|
      "#{severity.upcase.ljust(5)} [#{datetime.strftime('%Y-%m-%dT%H:%M:%S')} ##{Process.pid}]: #{msg}\n"
    end
    log
  end
end