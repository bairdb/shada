require 'sqlite3'

module LB
  module Data
    class SQLite
       
      def connect db
        begin
          @db = SQLite3::Database.new db
          @db.results_as_hash = true
        rescue => e
          puts e
          @db = nil
        end
        self
      end
      
      def prepare sql
        @db.prepare sql
      end

      def execute stmt, *args
        stmt.execute *args
      end
      
      def query sql, binds
        stmt = prepare sql
        execute stmt, *binds
      end
      
      def get_fields table
        stmt = @db.prepare "select * from test"
        stmt.columns
      end
      
      def get_tables db
        result = query "SELECT * FROM `information_schema`.TABLES WHERE TABLE_SCHEMA=?", [db]
        result
      end
      
      def get_primary db, table
        stmt = @db.prepare "PRAGMA table_info(#{table.downcase})"
        r = stmt.execute
        
        name_col = r.columns.find_index("name")
        pk_col = r.columns.find_index("pk")
        
        pk = ""
        
        r.each do |row|
          return row[name_col] unless row[pk_col] == 0
        end
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
      
      def create_table table, columns, engine="innodb", charset="utf8", autoinc=1
        sql = "CREATE TABLE IF NOT EXISTS #{table} (id INT NOT NULL AUTO_INCREMENT PRIMARY KEY) TYPE=#{engine} DEFAULT CHARSET=#{charset} AUTO_INCREMENT=#{autoinc}"
        execute sql
      end
      
      def add_column table, column_name, type, len, default='', after=''
        after = "AFTER #{after}" unless after.nil?
        sql = "ALTER TABLE `#{table}` ADD `#{column_name}` #{type}(#{len}) #{default}"
        puts sql
        @db.execute sql
      end
    end
  end
end