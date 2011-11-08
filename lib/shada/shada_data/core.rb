require 'yaml'

require 'shada/shada_utils'
require 'shada/shada_config'
require 'shada/shada_logger'

require_relative 'core/cache'
require_relative 'core/benchmark'

require_relative 'mysql2'
require_relative 'mysql2/mysql2'
require_relative 'mongodb'
require_relative 'mongodb/mongodb'
require_relative 'sqlite'
require_relative 'sqlite/sqlite'

Shada::Config.load_config "#{ENV['ROOT']}config/#{ENV['CONFIG']}.yml"

module Shada
  module Data
    class Core
      @@internals = {}

      include Shada::Utils 
      include Shada::Data::Benchmark
      include Shada::Logger
      
      attr_reader :fields, :records, :parent, :children
      
      def initialize
        @update = false
        @saving = false
        @records = []
        @cols = []
        @new_table = ""
        @parent = []
        @children = []
        @table = self.class.name.downcase.split('::').last
        @table.gsub!("model", "") unless /.*model/i.match(@table).nil?
        select_adapter
        @primary = get_primary @table
        @primary_sym = @primary.to_sym
        @fields = get_fields @table
        self
      end
      
      #Selects database adapter for model
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

      class << self
        def connection
          @@internals[get_table][:connection]
        end

        def cache
          @@internals[get_table][:cache]
        end
        
        def get_table
          table = self.name.downcase.split('::').last
          table.to_s.gsub!("model", "") unless /.*model/i.match(table).nil?
          table
        end
        
        def get_config
          @@internals[get_table][:config]
        end
        
        def connect hash
          @dont_setup = hash[:dont_setup] || false
          @@internals[get_table] = {}
          @@internals[get_table][:config] = hash
          @@internals[get_table][:db] = hash[:database]
          adapter = hash[:adapter] || 'mysql'
          
          if Shada::Config['MySQLDB'] && adapter == 'mysql'
            hash[:host] = Shada::Config['MySQLDB']
          else
            hash[:host] = hash[:host] || 'localhost'
          end
          
          if Shada::Config['MySQLDB_User'] && adapter == 'mysql'
            hash[:username] = Shada::Config['MySQLDB_User']
          else
            hash[:username] = hash[:username] || 'root'
          end
          
          if Shada::Config['MySQLDB_Password'] && adapter == 'mysql'
            hash[:password] = Shada::Config['MySQLDB_Password']
          else
            hash[:password] = hash[:password] || ''
          end
          
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
          if @@internals[get_table][:config][:adapter] == 'mysql'
            if not Core::persist_exists "cache_#{table}.tmp"
              @@internals[get_table][:cache] = Shada::Data::Cache.new 100
              Core::persist "cache_#{table}.tmp", @@internals[get_table][:cache]
            else
              @@internals[get_table][:cache] = Core::persist_load "cache_#{table}.tmp"
            end
          else
            @@internals[get_table][:cache] = Shada::Data::Cache.new 100
          end

          #puts @@internals[get_table][:cache].size

          unless get_config[:adapter] == 'mongodb' or @dont_setup
            connection.get_fields(table).each do |m|
              add_method m
            end
          end
        end


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
          connection.create_table table
          if block_given?
            self.instance_eval &block
          end
        end

        def create_row hash
          hash[:length] = hash[:length] ? hash[:length] : 0
          unless not hash[:table].nil?
            connection.add_column @new_table, hash[:name], hash[:type], hash[:length]
          else
            connection.add_column hash[:table], hash[:name], hash[:type], hash[:length]
          end
        end
        
        def alter_row hash
          hash[:length] = hash[:length] ? hash[:length] : 0
          unless not hash[:table].nil?
            connection.alter_column @new_table, hash[:name], hash[:type], hash[:length]
          else
            connection.alter_column hash[:table], hash[:name], hash[:type], hash[:length]
          end
        end
        
        def drop_row hash
          unless not hash[:table].nil?
            connection.drop_column @new_table, hash[:name]
          else
            connection.drop_column hash[:table], hash[:name]
          end
        end
        
        def destroy_table table
          connection.destroy_table table
        end
        
        def persist file_name, obj, cacheDir=""
          File.open("#{cacheDir}#{file_name}","w") do |file|
             Marshal::dump(obj,file)
          end
        end

        def persist_load file_name
          File.open("#{Shada::Config['CacheDir']}#{file_name}","r") {|f| return Marshal::load(f)}
        end

        def persist_exists file_name
          File.exist?("#{Shada::Config['CacheDir']}#{file_name}")
        end

      end

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
        @@internals[@table][:cache] = cache
        Core::persist "cache_#{table}.tmp", cache, Shada::Config['CacheDir']
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