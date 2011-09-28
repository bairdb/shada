CACHE_DIR = "/Users/bairdlackner-buckingham/projects/ruby_framework/shada_data/lib/shada_data/cache/"

module Shada
  module Data
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
end