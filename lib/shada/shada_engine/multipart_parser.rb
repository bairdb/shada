require "iconv"

module Shada
  class Multipart_Parser
    
    attr_accessor :files, :fields
    
    def initialize boundry=nil
      @ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
      @files = {}
      @fields = {}
      @tmp = ""
      @boundry = boundry
      @in = false
      return self
    end
    
    def parse file
      @file = file
      @boundry = File.open(file) {|f| f.readline} if @boundry.nil?
      
      File.foreach file do |line|
        begin
          case @ic.iconv(line)
          when /#{@boundry}.*?/
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
