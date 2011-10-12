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
    end
    
    def is_class? classname
      Object.const_defined?(classname)
    end
    
    def run_meth
      begin
        yield
      rescue => e
        puts e
      end
    end
  end
end