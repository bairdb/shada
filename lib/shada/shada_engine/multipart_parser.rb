require "iconv"

module Shada
  class Multipart_Parser
    
    attr_accessor :files, :fields
    
    def initialize content_type
      @ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
      @files = {}
      @fields = {}
      @tmp = ""
      @boundry = content_type.split('=')[1].to_s.chomp
      @in = false
      return self
    end
    
    def parse file
      puts file
      @file = file
      File.foreach file do |line|
        puts "start"
        begin
          case line.to_s.chomp
          when /^#{@boundry}[.*]/
            @in = @in ? !@in : @in
            puts 'In'
            next
          end
        rescue => e
          puts 'fail'
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
