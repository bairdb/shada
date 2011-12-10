require 'shada/shada_engine'
require 'shada/shada_utils'
require 'shada/shada_logger'

module Shada
  class Controller
    @@paths = {}
    @@secure = {}
    
    include Shada::Utils, Shada::Logger
    
    attr_accessor :form, :model, :rest_of_path, :base_link
    
    def initialize
      @pagemodel = PagesModel.new
      @base_link = self.class.name.downcase.gsub('controller', '') != Shada::Config['DefaultController'] ? "/#{self.class.name.downcase.gsub('controller', '')}" : ""
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
      end
      
      def path
        @@paths[self.name.downcase]
      end
      
      def secure *args
        secure = []
        args.each do |v|
          secure.push v
        end
        @@paths[self.name.downcase] = secure
      end
    end
    
    def error_page msg=''
      "There has been an error with your request: #{msg}"
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
    
    
    def list
      str = "<a href=\"#{@base_link}/edit\">Add</a><br>"
      
      @model.find.records.each do |r|
        str.insert(-1, "<a href=\"#{@base_link}/edit/id/#{r.id}\">#{r.id} | #{r.title}</a><br/>")
      end
    
      str
    end
  
    def edit
      build = Shada::HTML.build @model.fields, self do |html|
        html.a({:href => "#{@base_link}/list",  :inner_text => 'Back'})
      
        action = @rest_of_path.empty? ? "#{@base_link}/save" : "#{@base_link}/save/#{@rest_of_path[0]}/#{@rest_of_path[1]}"
        html.form({:id => 'form', :method => 'post', :action => action}) {
          @model.find @rest_of_path[0].to_sym => @rest_of_path[1] unless @rest_of_path.empty?

          @model.fields.each do |v|
            val = ""
            html.div({:class => 'form_row'}){
              html.label({:class => "something", :inner_text => v}) 
              html.div(){}
              val = @model.instance_variable_get("@#{v}")
              if val.is_a? String
                if val.length < 100
                  html.input({:type => 'text', :name => v, :value => val})
                else
                  html.textarea(val, {:name => v})
                end
              else
                html.input({:type => 'text', :name => v, :value => val})
              end
            }
          end

          html.input({:type => 'submit', :value => 'submit'})
        }
      end
      
      str = "<html><title></title><style>textarea{height:350px; width:600px;} input{width:350px}</style><body>"
      str += build.html
      str += str = "</body></html>"

    end

    def save
      unless @rest_of_path.empty?
        @model.find @rest_of_path[0].to_sym => @rest_of_path[1]
      end
      @model.fields.each do |field|
        @model.instance_variable_set("@#{field}", @form[field.to_sym]) unless @form[field.to_sym] == ''
      end
      @model.save
    
      build = Shada::HTML.build [], self do |html|
        html.a({:href => "#{@base_link}/list",  :inner_text => 'Back'})
      end
      
      @form.redirect "http://#{Shada::Config['Host']}#{@base_link}/list"
      
      ""
    end
    
    def render content
      content
    end
  end
end

