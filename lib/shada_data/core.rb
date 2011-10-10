require_relative 'core/cache'
require_relative 'core/benchmark'

require_relative 'mysql2'
require_relative 'mysql2/mysql2'
require_relative 'mongodb'
require_relative 'mongodb/mongodb'
require_relative 'sqlite'
require_relative 'sqlite/sqlite'

MONGREL2DB = "/Users/bairdlackner-buckingham/development/CoffeaCMS/lib/server/config.sqlite"
CACHE_DIR = "/Users/bairdlackner-buckingham/projects/ruby_framework/shada_data/lib/shada_data/cache/"

module Shada
  module Data
    class Core
      @@internals = {}

      include Shada::Data::Benchmark

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
        @table = self.class.name.downcase.split('::').last
        select_adapter
        @primary = get_primary @table
        @primary_sym = @primary.to_sym
        @fields = get_fields @table
        self
      end

      def select_adapter
        adapter = @@internals[@table][:config][:adapter] || 'mysql'

        case adapter
        when nil
          raise "Adapter Not Specified"
        when "mysql"
          self.class.send :include, Shada::Data::MYSQL2
        when 'mongodb'
          self.class.send :include, Shada::Data::MongoDB
        when 'sqlite'
          self.class.send :include, Shada::Data::SQLite
        else
          raise "Error"
        end
      end

      #Class Methods
      class << self
        def connection
          @@internals[get_table][:connection]
        end

        def cache
          @@internals[get_table][:cache]
        end
        
        def get_table
          self.name.downcase.split('::').last
        end
        
        def get_config
          @@internals[get_table][:config]
        end
        
        def connect hash
          @@internals[get_table] = {}
          @@internals[get_table][:config] = hash
          @@internals[get_table][:db] = hash[:database]
          adapter = hash[:adapter] || 'mysql'
          hash[:host] = hash[:host] || 'localhost'
          hash[:username] = hash[:username] || 'root'
          hash[:password] = hash[:password] || ''
          hash[:table] = get_table

          case adapter
            when nil
              raise "Adapter Not Specified"
            when "mysql"
              conn = Shada::Adapter::MYSQL2.new
              conn.connect hash
            when "mongodb"
              conn = Shada::Adapter::MongoDB.new
              conn.connect hash[:table]
            when "sqlite"
              conn = Shada::Adapter::SQLite.new
              conn.connect hash[:database]
            else
              raise "Unknown Error"
          end
          
          @@internals[get_table][:connection] = conn
          
          setup get_table
        end 

        def setup table
          @@internals[get_table][:cache] = Shada::Data::Cache.new 100
          #if not Core::persist_exists "cache_#{table}.tmp"

          #  Core::persist "cache_#{table}.tmp", @@cache
          #else
          #  @@cache = Core::persist_load "cache_#{table}.tmp"
          #end

          #puts @@cache.size

          unless get_config[:adapter] == 'mongodb'
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
          @@internals[get_table][:belongs_to_hash] = {:table => table, :col => col}
        end

        def has_one table, col
          @@internals[get_table][:has_one] = {:table => table, :col => col}
        end

        def has_many table, col
          @@internals[get_table][:has_many] = {:table => table, :col => col}
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
        @@internals[@table][:cache]
      end

      def get_connection
        @@internals[@table][:connection]
      end

      def belongs_to_hash
        @@internals[@table][:belongs_to_hash]
      end
      
      def db
        @@internals[@table][:db]
      end

      def save_cache table, cache
        Core::persist "cache_#{table}.tmp", cache
      end
      
      def ghost_query key, val
        vals = {}
        vals[key] = val.to_i
        find vals
      end
      
      def method_missing name, *args, &block
        return ghost_query $1, $2 if name.to_s =~ /^search_(.*)_for_(.*)/
        return add_column name, args, block if name.to_s =~ /^(.*)=/
        super
      end

    end
  end
end