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
      @type = nil
      @cnt = 0
      @name = ''
      return self
    end
    
    def parse file
      @file = file
      @boundry = File.open(file){|f| f.readline} if @boundry.nil?
      
      f = File.new(file)
      f.seek(-(@boundry.size + 2), IO::SEEK_END)
      puts f.readline
      
      @isBoundry = false
      @isDisp = false
      @isType = false
      
      File.foreach file do |line|
        begin
          case @ic.iconv(line)
          when /#{@boundry}.*?/
            unless @type.nil?
              puts "Type: #{@type}"
              if @type == 'form-data'
                @fields[@name] = @tmp
              else
                @files[@name] = {:filename => @filename, :content => @tmp}
              end
              @tmp = ""
              @type = ""
            end
            
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
            puts "Regular Content Disposition: #{@name} - #{@type}"
            next
          when /^Content-Type\: (.*)/
            @type = $1
            @isType = true
            puts "File Content Type: #{@type}"
            next
          end
          
          unless @isType
            unless @isDisp
              @tmp += line.chomp
            else
              @isDisp = false
            end
          else
            @isType = false
          end
          
        rescue => e
          #puts "fail: #{e.message}"
          next
        end
      end
      
      unless @type.nil?
        @tmp = @tmp.chomp.gsub(/#{@boundry}--/, "")
        if @type == 'form-data'
          @fields[@name] = @tmp
        else
          @files[@name] = {:filename => @filename, :content => @tmp}
        end
        @tmp = ""
        @type = ""
      end
      
      #puts @files
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
