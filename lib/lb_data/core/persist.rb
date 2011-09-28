CACHE_DIR = "/Users/bairdlackner-buckingham/projects/ruby_framework/lb_data/lib/lb_data/cache/"

module LB
  module Persist
    def persist file_name, obj
      puts file_name
      File.open("#{CACHE_DIR}#{file_name}","wb") do |file|
         Marshal::dump(obj,file)
      end
    end

    def persist_load file_name
      unless not File.exist?("#{CACHE_DIR}#{file_name}")
        File.open("#{CACHE_DIR}#{file_name}","rb") {|f| return Marshal::load(f)}
      else
        0
      end
    end
  end
end