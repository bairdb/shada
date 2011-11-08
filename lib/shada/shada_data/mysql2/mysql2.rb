require 'mysql2'

require 'shada/shada_logger'

module Shada
  module Adapter
    class MYSQL2
      
      include Shada::Logger
      
      def connect hash
        begin
          @db = Mysql2::Client.new hash
          Mysql2::Client.default_query_options
        rescue => e
          puts e
          @db = nil
        end
        self
      end
      
      def quote str
        val = str
        val = @db.escape str unless not str.is_a?(String)
        
        if val.is_a?(String)
          val = "'#{val}'"
        elsif val.nil?
          val = "NULL"
        end
        val
      end
      
      def execute sql, symbolize=true
        result = @db.query sql, :symbolize_keys => symbolize
        result
      end
      
      def prepare sql, binds
        ret = sql.gsub("?"){quote binds.shift}
        #puts ret
        ret
      end
      
      def query sql, binds
        result = execute prepare sql, binds
        result
      end
      
      def get_fields table
        result = query("SELECT * FROM #{table}", [])
        result.fields
      end
      
      def get_tables db
        result = query("SELECT * FROM `information_schema`.TABLES WHERE TABLE_SCHEMA=?", [db])
        result
      end
      
      def get_primary db, table
        result = query("SELECT * FROM `information_schema`.KEY_COLUMN_USAGE WHERE TABLE_SCHEMA=? AND TABLE_NAME=? AND CONSTRAINT_NAME='PRIMARY'", [db, table])
        result.first[:COLUMN_NAME]
      end
      
      def find table, fields, where={}, sort=""
        begin
          where_arr = []
          where_str = ""
          where_str = where.map{|k,v| "#{k}=?"}.join(" AND ") unless where.nil?
          where.each{|k,v| where_arr.push v}
          
          sort = "ORDER BY #{sort}" unless sort.empty?

          where_str = "WHERE #{where_str}" unless where_str.empty?
          sql = "SELECT #{fields} FROM #{table} #{where_str} #{sort}"
          #puts sql
          result = query sql, where_arr
          result
        rescue => e
          puts e
          return []
        end
      end
      
      def insert table, fields, data
        begin
          val_str = data.map{|v| "?"}.join(", ")
          data = data.map do |v| 
            if v.is_a?(Array) or v.is_a?(Hash)
              v.join ','
            else
              v
            end
          end
          sql = "INSERT INTO #{table} (#{fields.join(',')}) VALUES (#{val_str})"
          query sql, data
          result = "Success"
        rescue => e
          result = "Error Inserting: #{e}"
        end
        result
      end
      
      def update table, fields, id, where_column='id'
        begin
          where_arr = []
          keys = fields.map{|k,v| "#{k}=?"}.join(", ")
          fields.each{|k,v| where_arr.push v}
          where_arr.push id
          sql = "UPDATE #{table} SET #{keys} WHERE #{where_column}=?"
          query sql, where_arr
          result = "Success"
        rescue => e
          result = e
        end
        result
      end
      
      def destroy table, id, where_column='id'
        where_arr = []
        sql = "DELETE FROM #{table} WHERE #{where_column}=?"
        where_arr.push id
        query sql, where_arr
      end
      
      def create_table table, columns="", engine="innodb", charset="utf8", autoinc=1
        puts "Creating table #{table}"
        sql = "CREATE TABLE IF NOT EXISTS #{table} (id INT NOT NULL AUTO_INCREMENT PRIMARY KEY) ENGINE=#{engine}  DEFAULT CHARSET=#{charset} AUTO_INCREMENT=#{autoinc};"
        execute sql
      end
      
      def add_column table, column_name, type, len, default='', after=''
        after = "AFTER #{after}" unless after.nil?
        sql = "ALTER TABLE `#{table}` ADD `#{column_name}` #{type}(#{len}) #{default}"
        execute sql
      end
      
      def destroy_table table
        sql = "DROP TABLE `#{table}` IF EXISTS"
        execute sql
      end
      
    end
  end
end