module Shada
  class Multipart_Parser
    
    attr_accessor :files, :fields
    
    def initialize content_type
      @files = {}
      @fields = {}
      @tmp = ""
      @boundry = content_type.split('=')[1]
      return self
    end
    
    def parse file
      puts file
      return @boundry
    end
    
    private
    
    def file
      
    end
    
    def fields
      
    end
    
  end
end
