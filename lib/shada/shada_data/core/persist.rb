CACHE_DIR = "/Users/bairdlackner-buckingham/projects/ruby_framework/shada_data/lib/shada_data/cache/"

module Shada
  module Data
    module Persist
      def persist file_name, obj, dir=""
        if File.exists?()
          FileUtils.chmod 0777, "#{@dir}#{file_name}"
        end
        
        @dir = dir
        File.open("#{@dir}#{file_name}","wb") do |file|
           Marshal::dump(obj,file)
        end
        
        FileUtils.chmod 0777, "#{@dir}#{file_name}"
      end
      
      def flush file_name, dir=""
        @dir = dir
        FileUtils.chmod 0777, "#{@dir}#{file_name}"
        File.open("#{@dir}#{file_name}","wb")
      end

      def persist_load file_name
        unless not File.exist?("#{@dir}#{file_name}")
          File.open("#{@dir}#{file_name}","rb") {|f| return Marshal::load(f)}
        else
          0
        end
      end
    end
  end
end