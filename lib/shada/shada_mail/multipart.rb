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
  'video/x-m4v' => 'video'
}

module Shada
  class Multipart_Parser
    
    attr_accessor :files, :form_fields, :lastline, :alternative
    
    def initialize boundry=nil, alternative=nil
      @files = {}
      @form_fields = {}
      @tmp = ""
      @boundry = boundry
      @lastline = nil
      @first = true
      @in = false
      @type = nil
      @cnt = 0
      @name = ''
      @body = []
      @p = ''
      @content_disp = []
      @alternative = alternative
      return self
    end
    
    def parse file, path=nil
      @file = file
      @p = path ? path : '/home/admin/base/site/public/media/uploads/'
      @boundry = File.open(file){|f| f.readline} if @boundry.nil?
      
      unless @lastline.nil?
        f = File.new(file)
        f.seek(-(@boundry.size + 2), IO::SEEK_END)
        @lastline =  f.readline 
      end
      
      @firstBoundry = false
      @isBoundry = false
      @isDisp = false
      @isType = false
      
      File.open(file, 'rb').each do |line|
        begin
          case line.chomp
          when /#{@boundry}.*?/
            unless @type.nil?
              if @type == 'form-data'
                @form_fields[@name] = @tmp
              else
                #puts FILE_TYPES[@type]
                ext = @filename.split('.').pop
                @filename.gsub!(".#{ext}", '')
                @filename = "#{@filename.gsub(/[\s]+/, '_').gsub(/[\W]+/, '').downcase}.#{ext.gsub(/[\s]+/, '_').gsub(/[\W]+/, '').downcase}"
                
                unless @tmp.nil?
                  f = File.open "#{@p}#{@filename}", 'wb'
                  f.syswrite @tmp
                  f.close
                end
                
                @files[@name] = {:filename => @filename, :type => FILE_TYPES[@type], :path => @p}
                @filename =  nil
                @body = []
              end
              @tmp = ""
              @type = ""
            end
            
            @firstBoundry = true
            
            next
          when /#{@lastline}.*?/
            unless @type.nil?
              if @type == 'form-data'
                @form_fields[@name] = @tmp
              else
                unless @filename.nil?
                  ext = @filename.split('.').pop
                  @filename.gsub!(".#{ext}", '')
                  @filename = "#{@filename.gsub(/[\s]+/, '_').gsub(/[\W]+/, '').downcase}.#{ext.gsub(/[\s]+/, '_').gsub(/[\W]+/, '').downcase}"
                  
                  unless @tmp.nil?
                    f = File.open "#{@p}#{@filename}", 'wb'
                    f.syswrite @tmp
                    f.close
                  end

                  @files[@name] = {:filename => @filename, :type => FILE_TYPES[@type], :path => @p}
                  @filename =  nil
                  @body = []
                end
              end
              @tmp = ""
              @type = ""
            end
            
            next
          when /X-Attachment-Id:.*/
            @isDisp = false
            next
          when /Content-Transfer-Encoding:(.*)/
            @encoding = $1
            @isDisp = false
          when /^Content-Disposition: inline;/
            @content_disp = true
            @isDisp =  true
          when /^Content-Disposition:.*/
            @isDisp = false
            @content_disp = true
          when /.*filename=\"(.*?)\"/
            if @content_disp
              @name = $1
              @filename = $1
              @content_disp = false
            end
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
          when /.?#{@alternative}.*?/
            ''
            @isDisp = false
          end
          
          unless @isDisp
            if @firstBoundry == true
              if @filename
                @tmp << line
              else
                @tmp << line.chomp
              end
            end
          else
            @isDisp = false
          end
          
        rescue => e
          #puts "Error: #{e.message} - #{e.backtrace}"
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
      #File.unlink @file
    end
    
  end
end
