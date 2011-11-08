require 'yaml'

module Shada
  class Lang
    @@values = {}
    class << self
      def load_lang *files
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
        #puts file
        config = file ? YAML.load(open(file)) : {}
        config
      end
    end
    
  end
end
