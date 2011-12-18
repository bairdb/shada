require 'fileutils'
require_relative 'shada_engine'

UPLOAD_ROOT = "/home/admin/base"

module Shada
  class Upload < Shada::Engine
    include Shada::Utils
    
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
          tmpf = "#{UPLOAD_ROOT}/tmp/#{@headers['x-mongrel2-upload-start'].split('/').pop().to_s}"
          parser = Shada::Multipart_Parser.new.parse tmpf
          
          parser.form_fields.each do |k,v|
            @form.set_header k, v, 'post'
          end
          
          parser.files.each do |k, v|
            @form.set_header k, v, 'post'
          end
          
          @form['Refresh']  = ''
          @form['Content-Type'] = 'text/html'
          route @form.get_path
        else
          save_file upload, @headers['PATH']
        end
      elsif @headers['x-mongrel2-upload-start']
        puts "Upload starting."
        puts "Will read file from: #{@headers['x-mongrel2-upload-start']}"
        response = :next
      else
        if @headers['content-type'] =~ /multipart\/form-data/
          tmpf = "#{UPLOAD_ROOT}/tmp/body.#{rand(1000..9999)}"
          f = File.open(tmpf, "wb"){|f|
            f.write(@body)
          }
          
          parser = Shada::Multipart_Parser.new.parse tmpf
          
          parser.form_fields.each do |k,v|
            @form.set_header k, v, 'post'
          end
          
          parser.files.each do |k, v|
            @form.set_header k, v, 'post'
          end
          
          @form['Refresh']  = ''
          @form['Content-Type'] = 'text/html'
          route @form.get_path
        else
          unless @headers['PATH'].nil?
            f = File.open("#{UPLOAD_ROOT}#{@headers['PATH'].split('/').pop().to_s}", "w"){|f|
              f.write(data.pop())
            }
          end
        end
        
      end
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