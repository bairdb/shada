require_relative 'core/cache'
require_relative 'core/benchmark'

require_relative 'mysql2'
require_relative 'mysql2/mysql2'
require_relative 'mongodb'
require_relative 'mongodb/mongodb'
require_relative 'sqlite'
require_relative 'sqlite/sqlite'

CACHE_DIR = "/Users/bairdlackner-buckingham/projects/ruby_framework/lb_data/lib/lb_data/cache/"

class Core
  @@conn = ""
  @@hash = ""
  @@cache = ""
  @@belongs_to_hash = ""
  @@children_arr = ""
  
  include LB::Benchmark
  
  attr_reader :fields, :records, :parent, :children
  
  #Instance Methods
  def initialize
    @update = false
    @saving = false
    @records = []
    @cols = []
    @new_table = ""
    @parent = []
    @children = []
    select_adapter
    @table = self.class.name.downcase
    @primary = get_primary @table
    @primary_sym = @primary.to_sym
    @fields = get_fields @table
    self
  end
  
  def select_adapter
    adapter = @@hash[:adapter] || 'mysql'
    
    case adapter
    when nil
      raise "Adapter Not Specified"
    when "mysql"
      self.class.send :include, MYSQL2
    when 'mongodb'
      self.class.send :include, MongoDB
    when 'sqlite'
      self.class.send :include, SQLite
    else
      raise "Error"
    end
  end
  
  #Class Methods
  class << self
    def connection
      @@conn
    end
    
    def cache
      @@cache
    end
    
    def connect hash
      @@hash = hash
      ENV['DB'] = hash[:database]
      adapter = hash[:adapter] || 'mysql'
      hash[:host] = hash[:host] || 'localhost'
      hash[:username] = hash[:username] || 'root'
      hash[:password] = hash[:password] || ''
      hash[:table] = self.name
      
      case adapter
        when nil
          raise "Adapter Not Specified"
        when "mysql"
          @@conn = LB::Data::MYSQL2.new
          @@conn.connect hash
        when "mongodb"
          @@conn = LB::Data::MongoDB.new
          @@conn.connect hash[:table]
        when "sqlite"
          @@conn = LB::Data::SQLite.new
          @@conn.connect hash[:database]
        else
          raise "Unknown Error"
      end
      
      setup self.name
    end 
    
    def setup table
      @@cache = LB::Data::Cache.new 100
      #if not Core::persist_exists "cache_#{table}.tmp"
        
      #  Core::persist "cache_#{table}.tmp", @@cache
      #else
      #  @@cache = Core::persist_load "cache_#{table}.tmp"
      #end
      
      #puts @@cache.size
      
      unless @@hash[:adapter] == 'mongodb'
        connection.get_fields(table).each do |m|
          add_method m
        end
      end
    end
    
    def add_method name
      define_method(name) do
       instance_variable_get("@#{name}")
      end

      define_method("#{name}=") do |val|
       instance_variable_set("@#{name}",val)
      end
    end
    
    #DB methods
    
    def belongs_to table, col
      @@belongs_to_hash = {:table => table, :col => col}      
    end
    
    def has_one table, col
      
    end
    
    def has_many table, col
      
    end
    
    def create table, &block
      @new_table = table
      connection.create_table table, {}
      block.call
    end
    
    def create_row hash
      hash[:length] = hash[:length] ? hash[:length] : 0
      unless not hash[:table].nil?
        connection.add_column @new_table, hash[:name], hash[:type], hash[:length]
      else
        connection.add_column hash[:table], hash[:name], hash[:type], hash[:length]
      end
    end
    
    def persist file_name, obj
      File.open("#{CACHE_DIR}#{file_name}","wb") do |file|
         Marshal::dump(obj,file)
      end
    end

    def persist_load file_name
      File.open("#{CACHE_DIR}#{file_name}","rb") {|f| return Marshal::load(f)}
    end
    
    def persist_exists file_name
      File.exist?("#{CACHE_DIR}#{file_name}")
    end
    
  end
  
  #Utility Methods
  
  def cache
    @@cache
  end
  
  def get_connection
    @@conn
  end
  
  def belongs_to_hash
    @@belongs_to_hash
  end
  
  def save_cache table, cache
    Core::persist "cache_#{table}.tmp", cache
  end
  
  def method_missing name, *args, &block
    return "ghost method" if name.to_s =~ /^find_(.*)_by_(.*)/
    return add_column name, args, block if name.to_s =~ /^(.*)=/
    super
  end
  
end