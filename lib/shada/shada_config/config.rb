require 'yaml'

module Shada
  class Config
    @@values = {}
    class << self
      def load_config *files
        puts files
        #begin
          files.each do |file|
            self.load_file(file).each do |key, val|
              @@values[key] = val
            end
          end
        #rescue => e
        #   puts e
        #end
      end
      
      def load_vals
        self.load_config
        @@values
      end
      
      def [] key
        @@values[key]
      end
      
      def []= key, val
        @@values[key] = val
      end
      
      def value
        @@values
      end
      
      def load_file(file)
        puts file
        begin
          config = file ? YAML.load(open(file)) : {}
          config
        rescue => e
          puts e
          config = {}
        end
        config        
      end
    end
    
  end
end
