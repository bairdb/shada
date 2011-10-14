module Shada
  class Templator
    
    attr_accessor :registry
    
    def initialize
      @registry = {}
    end
    
    def register key, val
      @registry[key] = val
    end
    
    def unregister key
      @registry.delete key
    end
    
  end
end