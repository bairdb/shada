module Shada
  class Generator
    
    include Shada::Utils
    
    attr_accessor :name, :path, :dir, :both
    
    def initialize name, path=""
      @both = false
      puts "Creating #{name.downcase}"
      @name = name.propercase
      @name_lower = name.downcase
      @database = 'reelfinatics'
      @path = path
      @dir = File.dirname(__FILE__)
    end
    
    def generate
      begin
        @both = true
        generate_controller
        generate_model
      rescue => e
        puts e.message
        puts e.backtrace
      end
    end
    
    def generate_controller name=""
      @name = name unless name == ""
      controller_name = @both ? "controller" : "controller_no_model"
      tokens = {"name" => @name, "name_lower" => @name_lower}
      controller = File.read "#{@dir}/scaffolding/#{controller_name}.tmp"
      rcontroller = parse tokens, controller
      unless File.exists? "#{@path}controllers/#{@name_lower}controller.rb"
        puts "Creating Controller #{@name}Controller"
        File.open("#{@path}controllers/#{@name_lower}controller.rb","w") do |file|
           file.write rcontroller
        end
      else
        puts 'File already exists.'
      end
    end
    
    def generate_model name=""
      @name = name unless name == ""
      tokens = {"name" => @name, "name_lower" => @name_lower, "database" => @database}
      model = File.read "#{@dir}/scaffolding/model.tmp"
      rmodel = parse tokens, model
      unless File.exists? "#{@path}models/#{@name_lower}model.rb"
        File.open("#{@path}models/#{@name_lower}model.rb","w") do |file|
           file.write rmodel
        end
        puts "Creating Model #{@name}Model"
        Shada::Data::Core.connect :database => @database, :dont_setup => true
        Shada::Data::Core.create @name_lower do |s|
          create_row :name => "title", :type => "text"
        end
      else
        puts 'File already exists.'
      end
    end
    
    private
    
    def parse tokens, str
      rstr = str
      tokens.each do |key, val|
        begin
        rstr.scan(/%%#{key}%%/).each do |m|
          rstr.gsub!("%%#{key}%%", val) unless rstr.nil?
        end
        rescue => e
          puts e.message
        end
      end
      rstr
    end
    
  end
end