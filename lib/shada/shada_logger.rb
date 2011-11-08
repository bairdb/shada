module Shada
  module Logger
    def log_error msg
      log Shada::Config["ErrorLog"], msg, Time.now.getutc, 0
    end
    
    def log_access msg
      log Shada::Config["AccessLog"], msg, Time.now.getutc, 1
    end
    
    def log file_name, msg, timestamp, type
      file = File.open(file_name, "a+")
      trim_log file
      smsg = "#{type} | #{msg} | #{timestamp}\n"
      File.open(file_name, "a+") do |f|
        f.write smsg
      end
    end
    
    def trim_log file
      if File.size(file) > Shada::Config["MaxLogSize"]
        file.truncate 0
      end
    end
  end
end
