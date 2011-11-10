require 'shada/shada_engine'
require 'shada/shada_utils'
require 'shada/shada_logger'

module Shada
  class Controller
    @@paths = {}
    
    include Shada::Utils, Shada::Logger
    
    attr_accessor :form, :model, :rest_of_path
    
    def initialize
    end
    
    def index
      'This needs to be implemented.'
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
      
      def path
        @@paths[self.name.downcase]
      end
    end
    
    def error_page
      'There has been an error with your request'
    end
    
    def page_not_found
      'Page not found.'
    end
    
    def route var=@page
      unless var.nil?
        method = var.to_sym
        self.respond_to?(method) ? self.send(method) : index
      else
        index
      end
    end
    
    def render content
      content
    end
  end
end

