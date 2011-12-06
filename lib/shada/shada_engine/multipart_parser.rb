module Shada
  class Multipart_Parser
    
    attr_accessor :files, :fields
    
    def initialize content_type
      @files = {}
      @fields = {}
      @tmp = ""
      @boundry = content_type.split('=')[1]
      @in = false
      return self
    end
    
    def parse file
      puts file
      @file = file
      File.foreach file do |line|
        case line
        when @boundry
          @in = @in ? !@in : @in
          puts @in
          next
        end
      end
    end
    
    private
    
    def file
      
    end
    
    def fields
      
    end
    
    def cleanup
      File.unlink @file
    end
    
  end
end
