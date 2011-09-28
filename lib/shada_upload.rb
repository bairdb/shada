require 'fileutils'
require_relative 'shada_engine'

UPLOAD_ROOT = "/Users/bairdlackner-buckingham/projects/ruby_framework/build"

USENDER_ID = "34DE25A5-1CB5-4279-B4FF-AF99F118CD3D"
USEND_ADDR = "tcp://127.0.0.1:9981"
URECV_ADDR = "tcp://127.0.0.1:9980"

module Shada
  class Upload < Shada::Engine
    
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

Shada::Upload.new.start USENDER_ID, URECV_ADDR, USEND_ADDR do
  on_connect do
    puts "Connecting to server: #{@sender_id}"
  end
  
  on_read do |data|
    if @headers["x-mongrel2-upload-done"]
      expected = @headers["x-mongrel2-upload-start"] || "BAD"
      upload = @headers["x-mongrel2-upload-done"] || ""

      if expected != upload
        puts "Wrong file: #{expected}, #{upload}"
        response = :next
      end

      body = File.open("#{UPLOAD_ROOT}#{upload}", "r")
      puts "Done: #{body.size}, #{@headers["content-length"]}"
      if @headers['content-type'] =~ /multipart\/form-data/
        Shada::Multipart_Parser.new @headers['content-type'], body
        body.close
        response = "<html><head><title>Return</title><body><pre>\nSENDER: #{data[0]}, \nIDENT: #{data[1]}, \nPATH: #{data[2]}, HEADERS: #{data[3]}, \nBODY: #{data[4]}</pre>\n</body></html>"
      else
        body.close
        save_file upload, @headers['PATH']
        response = "<html><head><title>Return</title><body><pre>\nSENDER: #{data[0]}, \nIDENT: #{data[1]}, \nPATH: #{data[2]}, HEADERS: #{data[3]}, \nBODY: #{data[4]}</pre>\n</body></html>"
      end
    elsif @headers['x-mongrel2-upload-start']
      puts "Upload starting."
      puts "Will read file from: #{@headers['x-mongrel2-upload-start']}"
      response = :next
    else
      response = "<html><head><title>Return</title><body><pre>\nSENDER: #{data[0]}, \nIDENT: #{data[1]}, \nPATH: #{data[2]}, HEADERS: #{data[3]}, \nBODY: #{data[4]}</pre>\n</body></html>"
      f = File.open("#{UPLOAD_ROOT}#{@headers['PATH'].split('/').pop().to_s}", "w"){|f|
        f.write(data.pop())
      }
    end
    
    return response
  end
  
  on_disconnect do
    puts 'Disconnecting'
  end
end