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
      @first = true
      @in = false
      @type = ""
      @cnt = 0
      @name = ''
      return self
    end
    
    def parse file
      @file = file
      @boundry = File.open(file) {|f| f.readline} if @boundry.nil?
      @isBoundry = false
      @isDisp = false
      @isType =false
      
      File.foreach file do |line|
        begin
          
          case @ic.iconv(line)
          when /#{@boundry}.*?/
            unless @first
              if @type == 'form-data'
                @fields[@name] = @tmp
              else
                @files[@name] = {:filename => @filename, :content => @tmp}
              end
              @tmp = ""
            end
            @first = !@first unless !@first
            next
          when /^Content-Disposition\: form-data\; name=\"(.*?)\"\; filename=\"(.*?)\"/
            @name = $1
            @filename = $2
            @isDisp = true
            puts "File Content Disposition: #{@name} - #{@filename}"
            next
          when /^Content-Disposition\: form-data\; name=\"(.*?)\"/
            @name = $1
            @type = 'form-data'
            @isDisp = true
            puts "Regular Content Disposition: #{@name}"
            next
          when /^Content-Type\: (.*)/
            @type = $1
            @isType = true
            puts "File Content Type: #{@type}"
            next
          end
          
          unless @isType
            unless @isDisp
              @tmp += line
            else
              @isDisp = false
            end
          else
            unless @isDisp
              @tmp += line
            else
              @isDisp = false
            end
            @isType = false
          end
          
        rescue => e
          #puts "fail: #{e.message}"
          next
        end
      end
      
      puts @files
      puts @fields
      
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
