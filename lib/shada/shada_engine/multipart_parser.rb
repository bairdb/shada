require "iconv"

module Shada
  class Multipart_Parser
    
    attr_accessor :files, :fields
    
    def initialize content_type
      @ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
      @files = {}
      @fields = {}
      @tmp = ""
      @boundry = @ic.iconv(content_type.split('=')[1].to_s)
      @in = false
      return self
    end
    
    def parse file
      puts file
      @file = file
      File.foreach file do |line|        
        puts line.to_s.encoding.name
        
#        case @ic.iconv(line.to_s)
#        when /^#{@boundry}(\w+)/
#          @in = @in ? !@in : @in
#          puts @in
#          next
#        end
      end
      
      cleanup
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
