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

config = ENV['CONFIG'] ? ENV['CONFIG'] : 'main'
path = ENV['ROOT'] ? ENV['ROOT'] : '/home/admin/base/site/'
Shada::Config.load_config "#{path}config/#{config}.yml"

module Shada
  module Data
    class Core
      @@internals = {}

      include Shada::Utils 
      include Shada::Data::Benchmark
      include Shada::Logger
      
      attr_reader :fields, :added_fields, :records, :parent, :children, :db
      attr_accessor :limit, :offset, :row_total, :total_pages, :current_page, :record_count, :timestamp, :records
      
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
        @added_fields = []
        @limit = 0
        @offset = 0
        @row_total = 0
        @total_pages = 0
        @current_page = 0
        @record_count = 0
        @timestamp = get_timestamp @table
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
          unless @@internals.include?(get_table)
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
            
            @@internals[get_table][:connection] ||= conn
            
            setup get_table
          end
        end 

        def setup table
          if @@internals[get_table][:config][:adapter] == 'mysql'
            if not Core::persist_exists "cache_#{table}.tmp"
              @@internals[get_table][:cache] = Shada::Data::Cache.new 10000
              Core::persist "cache_#{table}.tmp", @@internals[get_table][:cache]
            else
              @@internals[get_table][:cache] = Core::persist_load "cache_#{table}.tmp"
            end
          else
            @@internals[get_table][:cache] = Shada::Data::Cache.new 10000
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
        
        def rename_row hash
          unless not hash[:table].nil?
            connection.change_column @new_table, hash[:name], hash[:new_name], hash[:type], hash[:length]
          else
            connection.change_column hash[:table], hash[:name], hash[:new_name], hash[:type], hash[:length]
          end
        end
        
        def drop_row hash
          unless not hash[:table].nil?
            connection.drop_column @new_table, hash[:name]
          else
            connection.drop_column hash[:table], hash[:name]
          end
        end
        
        def rename_table table, new_name
          connection.rename_table table, new_name
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
        
        def flush file_name, cacheDir=""
          File.open("#{cacheDir}#{file_name}","w")
        end
        
      end
      
      def get_row_count
        get_connection.get_row_count @table
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
      
      def flush_cache table
        @@internals[@table][:cache] = nil
        @@internals[@table][:cache] = Shada::Data::Cache.new 10000
        Core::flush "cache_#{table}.tmp", Shada::Config['CacheDir']
      end
      
      def ghost_query key, val
        vals = {}
        vals[key] = val.to_i
        find vals
      end
      
      def to_json
        arr = []
        @records.each do |record|
          hash = {}
          @fields | @added_fields
          puts @fields
          @fields.map do |f| 
            #unless record.instance_variable_get("@#{f}").to_s.nil?
            hash[f.to_s] = escape(record.instance_variable_get("@#{f}").to_s)
            #end
          end
          arr.push hash
        end
        
        arr.to_json()
      end
      
      def method_missing name, *args, &block
        return ghost_query $1, $2 if name.to_s =~ /^search_(.*)_for_(.*)/
        return add_column name, args, block if name.to_s =~ /^(.*)=/
      end

    end
  end
end