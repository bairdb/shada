require "cgi"
require "time"

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
  'video/x-m4v' => 'video',
  'text/calendar' => 'calendar',
  'application/octet-stream' => 'calendar'
}

module Shada
  class Multipart_Parser
    
    attr_accessor :files, :form_fields
    
    def initialize boundry=nil
      @files = {}
      @form_fields = {}
      @tmp = ""
      @boundry = boundry
      @first = true
      @in = false
      @type = nil
      @cnt = 0
      @name = ''
      @body = []
      @p = ''
      return self
    end
    
    def parse file, path=nil
      @file = file
      @p = path ? path : '/home/admin/base/site/public/media/uploads/'
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
                @form_fields[@name] = @tmp
              else
                unless @filename.nil?
                  ext = @filename.split('.').pop
                  @filename.gsub!(".#{ext}", '')
                  @filename = "#{@filename.gsub(/[\s]+/, '_').gsub(/[\W]+/, '').downcase}-#{Time.now.to_i}.#{ext.gsub(/[\s]+/, '_').gsub(/[\W]+/, '').downcase}"
                
                  unless FILE_TYPES[@type].nil? or @tmp.nil?
                    f = File.open "#{@p}#{@filename}", 'wb'
                    f.syswrite @tmp
                    f.close
                  end
                
                  @files[@name] = {:filename => @filename, :type => FILE_TYPES[@type], :path => @p, :file_type => @type}
                end
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
                @form_fields[@name] = @tmp
              else
                unless @filename.nil?
                  ext = @filename.split('.').pop
                  @filename.gsub!(".#{ext}", '')
                  @filename = "#{@filename.gsub(/[\s]+/, '_').gsub(/[\W]+/, '').downcase}-#{Time.now.to_i}.#{ext.gsub(/[\s]+/, '_').gsub(/[\W]+/, '').downcase}"
                
                  unless FILE_TYPES[@type].nil? or @tmp.nil?
                    f = File.open "#{@p}#{@filename}", 'wb'
                    f.syswrite @tmp
                    f.close
                  end
                
                  @files[@name] = {:filename => @filename, :type => FILE_TYPES[@type], :path => @p, :file_type => @type}
                end
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
            @type = tmp.strip.chomp
            @isType = true
            next
          end
          
          unless @isDisp
            if @filename
              @tmp << line
            else
              @tmp << line.chomp
            end
          else
            @isDisp = false
          end
          
        rescue => e
          #puts "Error: #{e.message}"
          next
        end
      end      
      cleanup
      
      return self
    end
    
    private
    
    def handle_file
      unless FILE_TYPES[@type].nil?
        f = File.open "#{@p}#{@filename}", 'wb'
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
