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
      @body = nil
      return self
    end
    
    def parse file
      @file = file
      @boundry = File.open(file){|f| f.readline} if @boundry.nil?
      
      f = File.new(file)
      f.seek(-(@boundry.size + 2), IO::SEEK_END)
      @lastline =  f.readline
      
      @isBoundry = false
      @isDisp = false
      @isType = false
      
      File.foreach file do |line|
        begin
          case @ic.iconv(line)
          when /#{@boundry}.*?/
            unless @type.nil?
              if @type == 'form-data'
                @fields[@name] = @tmp
              else
                puts @body
                @files[@name] = {:filename => @filename, :content => @tmp}
              end
              @tmp = ""
              @type = ""
              @filename =  nil
              @body = nil
            end
            
            next
          when /#{@lastline}.*?/
            unless @type.nil?
              if @type == 'form-data'
                @fields[@name] = @tmp
              else
                @files[@name] = {:filename => @filename, :content => @tmp}
              end
              @tmp = ""
              @type = ""
              @filename = nil
              @body = nil
            end
            
            next
          when /^Content-Disposition\: form-data\; name=\"(.*?)\"\; filename=\"(.*?)\"/
            @name = $1
            @filename = $2
            @isDisp = true
            @body = Tempfile.new('ShadaMultiPart')
            @body.binmode if @body.respond_to? :binmode
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
              if @filename
                @tmp += line
                @body << line
              else
                @tmp += line
              end
            else
              @isDisp = false
            end
          else
            @isType = false
          end
          
        rescue => e
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
