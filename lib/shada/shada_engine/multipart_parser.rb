require "cgi"

FILE_TYPES = {
  'image/gif' => 'image',
  'image/jpeg' => 'image',
  'image/pjpeg' => 'image',
  'image/png' => 'image',
  'image/svg+xml' => 'image',
  'image/tiff' => 'image',
  'image/vnd.microsoft.icon' => 'image',
  'video/mpeg' => 'video',
  'video/mp4' => 'video',
  'video/ogg' => 'video',
  'video/quicktime' => 'video',
  'video/webm' => 'video',
  'video/x-ms-wmv' => 'video',
}

module Shada
  class Multipart_Parser
    
    attr_accessor :files, :fields
    
    def initialize boundry=nil
      @files = {}
      @fields = {}
      @tmp = ""
      @boundry = boundry
      @first = true
      @in = false
      @type = nil
      @cnt = 0
      @name = ''
      @body = []
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
      
      File.open(file, 'rb').each do |line|
        begin
          case line
          when /#{@boundry}.*?/
            unless @type.nil?
              if @type == 'form-data'
                @fields[@name] = @tmp
              else
                puts @type
                unless FILE_TYPES[@type].nil?
                  f = File.open "/home/admin/base/site/public/media/uploads/#{@filename}", 'wb'
                  f.syswrite @tmp
                  f.close
                end

                @files[@name] = {:filename => @filename, :content => @tmp, :type => @type}
                @filename =  nil
                @body = []
              end
              @tmp = ""
              @type = ""
            end
            
            next
          when /#{@lastline}.*?/
            unless @type.nil?
              if @type == 'form-data'
                @fields[@name] = @tmp
              else
                unless FILE_TYPES[@type].nil?
                  f = File.open "/home/admin/base/site/public/media/uploads/#{@filename}", 'wb'
                  f.syswrite @tmp
                  f.close
                end

                @files[@name] = {:filename => @filename, :content => @tmp, :type => @type}
                @filename =  nil
                @body = []
              end
              @tmp = ""
              @type = ""
            end
            
            next
          when /^Content-Disposition\: form-data\; name=\"(.*?)\"\; filename=\"(.*?)\"/
            @name = $1
            @filename = $2
            @isDisp = true
            next
          when /^Content-Disposition\: form-data\; name=\"(.*?)\"/
            @name = $1
            @type = 'form-data'
            @isDisp = true
            next
          when /^Content-Type\: (.*)/
            tmp = $1
            @type = tmp unless tmp == 'application/octet-stream'
            @isType = true
            next
          end
          
          unless @isDisp
            @filename ? @tmp << line : line.chomp
          else
            @isDisp = false
          end
          
        rescue => e
          next
        end
      end      
      cleanup
    end
    
    private
    
    def handle_file
      unless FILE_TYPES[@type].nil?
        f = File.open "/home/admin/base/site/public/media/uploads/#{@filename}", 'wb'
        f.syswrite @tmp
        f.close
      end

      @files[@name] = {:filename => @filename, :content => @tmp, :type => @type}
      @filename =  nil
      @body = []
    end
    
    def fields
      
    end
    
    def cleanup
      File.unlink @file
    end
    
  end
end
