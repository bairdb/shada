require "iconv"

module Shada
  class Multipart_Parser
    
    attr_accessor :files, :fields
    
    def initialize content_type
      @ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
      @files = {}
      @fields = {}
      @tmp = ""
      #@boundry = content_type.split('=')[1].to_s.chomp
      @in = false
      return self
    end
    
    def parse file
      @file = file
      @boundry = File.open(file) {|f| f.readline}
      
      File.foreach file do |line|
        begin
          case line
          when /^#{@boundry}[.*]/
            @in = @in ? !@in : @in
            puts 'In'
            next
          end
        rescue => e
          puts "fail: #{e.message}"
          next
        end
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
