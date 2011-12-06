require 'fileutils'
require_relative 'shada_engine'

UPLOAD_ROOT = "/home/admin/base"

module Shada
  class Upload < Shada::Engine
    def on_connect
      puts "Connecting to server: #{@sender_id}"
    end
    
    def handle data
      if @headers["x-mongrel2-upload-done"]
        expected = @headers["x-mongrel2-upload-start"] || "BAD"
        upload = @headers["x-mongrel2-upload-done"] || ""

        if expected != upload
          puts "Wrong file: #{expected}, #{upload}"
          response = :next
        end
        
        if @headers['content-type'] =~ /multipart\/form-data/
          filename = "#{UPLOAD_ROOT}/tmp/#{@headers['x-mongrel2-upload-start'].split('/').pop().to_s}"
          test = Shada::Multipart_Parser.new(@headers['content-type']).parse filename
          response = "<html><head><title>Return</title><body><pre>1\nSENDER: #{data[0]}, \nIDENT: #{data[1]}, \nPATH: #{data[2]}, \nHEADERS: #{data[3]}, \nBODY: #{data[4]} \nTest: #{test}</pre>\n</body></html>"
        else
          save_file upload, @headers['PATH']
          response = "<html><head><title>Return</title><body><pre>2\nSENDER: #{data[0]}, \nIDENT: #{data[1]}, \nPATH: #{data[2]}, HEADERS: #{data[3]}, \nBODY: #{data[4]}</pre>\n</body></html>"
        end
      elsif @headers['x-mongrel2-upload-start']
        puts "Upload starting."
        puts "Will read file from: #{@headers['x-mongrel2-upload-start']}"
        response = :next
      else
        if @headers['content-type'] =~ /multipart\/form-data/
          tmpf = "#{UPLOAD_ROOT}/tmp/body.#{rand(1000..9999)}"
          f = File.open(tmpf, "w"){|f|
            f.write(@body.to_s)
          }
          
          Shada::Multipart_Parser.new(@headers['content-type']).parse tmpf
          
          response = "<html><head><title>Return</title><body>#{@body}</body></html>"
        else
          response = "<html><head><title>Return</title><body><pre>3\nSENDER: #{data[0]}, \nIDENT: #{data[1]}, \nPATH: #{data[2]}, HEADERS: #{data[3]}, \nBODY: #{data[4]}</pre>\n</body></html>"
          f = File.open("#{UPLOAD_ROOT}#{@headers['PATH'].split('/').pop().to_s}", "w"){|f|
            f.write(data.pop())
          }
        end
        
      end
    
      @form['Content-Type'] = 'text/html'
      return response
    end
    
    def save_file tmp_name, real_name
      begin
        filename = "#{UPLOAD_ROOT}/uploads/#{real_name.split('/').pop().to_s}"
        ext = filename.split(".").pop
        unless File.exists?(filename)
          FileUtils.mv "#{UPLOAD_ROOT}#{tmp_name}", filename
        else
          f = filename.gsub(".#{ext}", "")
          srch = Dir["#{f}_*.#{ext}"]
          append = srch.count + 1
          f2 = "#{f}_#{append}.#{ext}"
          FileUtils.mv "#{UPLOAD_ROOT}#{tmp_name}", f2
        end
      rescue => e
        puts e
        "Error"
      end
    end
  end
end

#Shada::Upload.new.start do
#  on_connect do
#    puts "Connecting to server: #{@sender_id}"
#  end
#  
#  handle do |data|
#    if @headers["x-mongrel2-upload-done"]
#      expected = @headers["x-mongrel2-upload-start"] || "BAD"
#      upload = @headers["x-mongrel2-upload-done"] || ""
#
#      if expected != upload
#        puts "Wrong file: #{expected}, #{upload}"
#        response = :next
#      end
#
#      body = File.open("#{UPLOAD_ROOT}#{upload}", "r")
#      puts "Done: #{body.size}, #{@headers["content-length"]}"
#      if @headers['content-type'] =~ /multipart\/form-data/
#        filename = "#{UPLOAD_ROOT}/#{@headers['x-mongrel2-upload-start'].split('/').pop().to_s}"
#        Shada::Multipart_Parser.new(@headers['content-type']).parse filename
#        body.close
#        response = "<html><head><title>Return</title><body><pre>\nSENDER: #{data[0]}, \nIDENT: #{data[1]}, \nPATH: #{data[2]}, HEADERS: #{data[3]}, \nBODY: #{data[4]}</pre>\n</body></html>"
#      else
#        body.close
#        save_file upload, @headers['PATH']
#        response = "<html><head><title>Return</title><body><pre>\nSENDER: #{data[0]}, \nIDENT: #{data[1]}, \nPATH: #{data[2]}, HEADERS: #{data[3]}, \nBODY: #{data[4]}</pre>\n</body></html>"
#      end
#    elsif @headers['x-mongrel2-upload-start']
#      puts "Upload starting."
#      puts "Will read file from: #{@headers['x-mongrel2-upload-start']}"
#      response = :next
#    else
#      response = "<html><head><title>Return</title><body><pre>\nSENDER: #{data[0]}, \nIDENT: #{data[1]}, \nPATH: #{data[2]}, HEADERS: #{data[3]}, \nBODY: #{data[4]}</pre>\n</body></html>"
#      f = File.open("#{UPLOAD_ROOT}#{@headers['PATH'].split('/').pop().to_s}", "w"){|f|
#        f.write(data.pop())
#      }
#    end
#    
#    set_response_header 'Content-Type', 'text/html'
#    return response
#  end
#  
#  on_disconnect do
#    puts 'Disconnecting'
#  end
#end