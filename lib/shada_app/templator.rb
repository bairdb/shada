module Shada
  class Templator
    
    attr_accessor :registry
    
    def initialize
      @pattern = /^<!(.*?)>$/
      @registry = {}
    end
    
    def register key, val
      @registry[key] = val
    end
    
    def unregister key
      @registry.delete key
    end
    
    def open_template file
      File.read file
    end
    
    def parse file
      f = open_template file
      f.scan(/<!(.*?)>/m).each do |m|
        f.gsub!("<!#{m[0]}>", @registry[m[0]])
      end
      f
    end
    
  end
end