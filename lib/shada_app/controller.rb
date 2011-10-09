require 'shada_engine'

module Shada
  class Controller
    @@paths = {}
    
    def initialize
    end
    
    def path
      @@paths[self.class.name.downcase]
    end
    
    class << self
      def path_map *args
        path = []
        args.each do |v|
          path.push v
          add_method v
        end
        @@paths[self.name.downcase] = path
        puts self.instance_variables
      end
      
      def add_method name
        define_method(name) do
         instance_variable_get("@#{name}")
        end

        define_method("#{name}=") do |val|
         instance_variable_set("@#{name}",val)
        end
      end
    end
    
    def render content, content_type='text/html'
      set_response_header 'Content-Type', content_type
      content
    end
  end
end

