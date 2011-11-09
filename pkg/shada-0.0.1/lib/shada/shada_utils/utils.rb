require 'cgi'
FILECACHE = {}

module Shada
  module Utils
    
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def add_method name
        define_method(name) do
         instance_variable_get("@#{name}")
        end

        define_method("#{name}=") do |val|
         instance_variable_set("@#{name}",val)
        end
      end
    end
    
    def reload path, ext="rb"
      begin
        Dir["#{path}*.#{ext}"].each do |f| 
          filename = f.split("/").last
          if FILECACHE[filename]
            if FILECACHE[filename][:modified].to_i != File.ctime(f).to_i
              FILECACHE[filename] = {:modified => File.ctime(f)}
              puts "loaded existing - #{filename}"
              load "#{f}"
            end
          else
            FILECACHE[filename] = {:modified => File.ctime(f)}
            load "#{f}"
          end
        end
      rescue => e
        puts e
      end
    end
    
    def is_class? classname
      begin
        Object.const_defined?(classname.to_sym)
      rescue => e
        false
      end
    end
    
    def run_meth
      begin
        yield
      rescue => e
        puts e
      end
    end
    
    def escape html
      CGI.escape html
    end
    
    def unescape html
      CGI.unescape html
    end
    
    def escape_html html
      CGI.escapeHTML html
    end
    
    def unescape_html html
      CGI.unescapeHTML html
    end
  end
end