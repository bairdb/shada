require 'mysql2'

require 'shada/shada_logger'

module Shada
  module Adapter
    class MYSQL2
      
      attr_accessor :db, :config
      
      include Shada::Logger
      
      def connect hash
        @config = hash
        begin
          hash[:reconnect] = 1
          @db = Mysql2::Client.new hash
          Mysql2::Client.default_query_options
        rescue => e
          puts e
          @db = Mysql2::Client.new hash
          Mysql2::Client.default_query_options
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
      
      def escape str
        @db.escape str unless not str.is_a?(String)
      end
      
      def execute sql, symbolize=true
        begin
          #puts sql
          result = @db.query sql, :symbolize_keys => symbolize
          result
        rescue => e
          puts "#{e.message}"
        ensure
          []
        end
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
      
      def last_id
        @db.last_id
      end
      
      def get_fields table
        result = query("SELECT * FROM #{table}", [])
        result.fields
      end
      
      def get_tables db
        result = query("SELECT * FROM `information_schema`.TABLES WHERE TABLE_SCHEMA=?", [db])
        result
      end
      
      def get_row_count table
        result = query("SELECT COUNT(*) AS cnt FROM #{table}", [])
        result.first[:cnt]
      end
      
      def get_row_count_for table, where={}
        where_arr = []
        where_str = ""
        where_str = where.map{|k,v| "#{k}=?"}.join(" AND ") unless where.nil?
        where.each{|k,v| where_arr.push v} unless where.nil?
        where_str = "WHERE #{where_str}" unless where_str.empty?
        cnt = query("SELECT COUNT(*) AS cnt FROM #{table} #{where_str}", where_arr)
        puts cnt.first[:cnt]
        cnt.first[:cnt]
      end
      
      def get_primary db, table
        result = query("SELECT * FROM `information_schema`.KEY_COLUMN_USAGE WHERE TABLE_SCHEMA=? AND TABLE_NAME=? AND CONSTRAINT_NAME='PRIMARY'", [db, table])
        begin
          result.first[:COLUMN_NAME]
        rescue => e
          ''
        end
      end
      
      def get_timestamp db, table
        result = query("SELECT * FROM `information_schema`.COLUMNS WHERE TABLE_SCHEMA=? AND TABLE_NAME=? AND DATA_TYPE='timestamp'", [db, table])
        begin
          result.first[:COLUMN_NAME]
        rescue => e
          ''
        end
      end
      
      def search table, fields, keyword, filter="", limit=0, offset=0
        begin
          slimit = ""
          
          offset = offset || 0          
          slimit = limit > 0 ? "LIMIT #{offset},#{limit}" : '' unless limit.nil?
          
          unless keyword.to_s.length <= 3
            tfields = fields.split(',')
            where_arr = []
            where_str = ""
            slimit = ""
            where_str = tfields.map{|k| "#{k.strip}=?"}.join(" OR ") unless tfields.nil?
            tfields.each{|k| where_arr.push "#{keyword}"} unless tfields.nil?
            
            filter = "WHERE #{filter}" unless filter == ''
            sql1 = "DROP TABLE IF EXISTS `#{table}_temp`;"
            execute sql1
            sql1 = " CREATE TEMPORARY TABLE `#{table}_temp` SELECT * FROM `#{table}` #{filter};"
            execute sql1
            sql1 = " ALTER TABLE `#{table}_temp`  ENGINE = MYISAM;"
            execute sql1
            sql1 = " ALTER TABLE `#{table}_temp` ADD FULLTEXT (#{fields});"
            execute sql1
          
            where_str = "OR #{where_str}" unless where_str.empty?
            sql = "SELECT *, MATCH(#{fields}) AGAINST ('#{keyword}' IN NATURAL LANGUAGE MODE) as score FROM #{table}_temp WHERE MATCH(#{fields}) AGAINST ('#{keyword}' IN NATURAL LANGUAGE MODE) #{where_str} ORDER BY score DESC #{slimit}"
            result = query sql, where_arr
          
            sql2 = "DROP TABLE `#{table}_temp`;"
            execute sql2
          else
            tfields = fields.split(',')
            where_arr = []
            where_str = ""
            slimit = ""
            where_str = tfields.map{|k| "#{k.strip} LIKE ?"}.join(" OR ") unless tfields.nil?
            tfields.each{|k| where_arr.push "%#{keyword}%"} unless tfields.nil?
          
            offset = offset || 0
            
            filter = "AND #{filter}" unless filter == ''
            slimit = limit > 0 ? "LIMIT #{offset},#{limit}" : '' unless limit.nil?
            where_str = "WHERE #{where_str}" unless where_str.empty?
            sql = "SELECT * FROM #{table} #{where_str} #{filter} #{slimit}"
            puts sql
            result = query sql, where_arr
          end
          result
        rescue => e
          puts "#{e.message} - #{e.backtrace}"
          return []
        end
      end
      
      def find table, fields, where={}, sort="", limit=0, offset=0, klass=nil
        begin
          where_arr = []
          where_str = ""
          slimit = ""
          where_str = where.map{|k,v| "#{k}=?"}.join(" AND ") unless where.nil?
          where.each{|k,v| where_arr.push v} unless where.nil?
          
          sort = "ORDER BY #{sort}" unless sort.empty?
          
          offset = offset || 0
          
          slimit = limit > 0 ? "LIMIT #{offset},#{limit}" : '' unless limit.nil?
          where_str = "WHERE #{where_str}" unless where_str.empty?
          sql = "SELECT #{fields} FROM #{table} #{where_str} #{sort} #{slimit}"
          #puts sql
          result = query sql, where_arr
          
          result
        rescue => e
          puts "#{e.message} - #{e.backtrace}"
          return []
        end
      end
      
      def filter_geo table, coords, distance=10, limit=10
        sql = "SELECT *, 3956 * 2 * ASIN(SQRT(POWER(SIN((? - abs(lat)) * pi()/180 / 2), 2) +  COS(? * pi()/180 ) * COS(abs(lat) * pi()/180) *  POWER(SIN((? - lng) * pi()/180 / 2), 2) )) as distance FROM #{table} having distance < ? ORDER BY distance limit ?"
        result = query sql, [coords[:lat].to_f, coords[:lat].to_f, coords[:lng].to_f, distance, limit]
        result
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
        table = escape table
        puts "Creating table #{table}"
        query("CREATE TABLE IF NOT EXISTS `#{table}` (id INT NOT NULL AUTO_INCREMENT PRIMARY KEY) ENGINE=?  DEFAULT CHARSET=? AUTO_INCREMENT=?;", [engine, charset, autoinc])
      end
      
      def add_column table, column_name, type, len=255, default='', after=''
        after = "AFTER #{after}" unless after.nil?
        sql = "ALTER TABLE `#{escape(table)}` ADD `#{escape(column_name)}` #{escape(type)}(#{escape(len)}) #{default}"
        execute sql
      end
      
      def alter_column table, column, type, len
        sql = "ALTER TABLE `#{escape(table)}` MODIFY `#{escape(column)}` #{escape(type)}(#{escape(len)})"
        execute sql
      end
      
      def drop_column table, column
        sql = "ALTER TABLE `#{escape(table)}` DROP `#{escape(column)}`"
        execute sql
      end
      
      def change_column table, column, new_column, type, len
        sql = "ALTER TABLE `#{escape(table)}` CHANGE `#{escape(column)}` `#{escape(new_column)}` #{escape(type)}(#{escape(len)})"
        puts sql
        execute sql
      end
      
      def rename_table table, new_table
        sql = "RENAME TABLE `#{escape(table)}` TO `#{escape(new_table)}`"
        execute sql
      end
      
      def destroy_table table
        sql = "DROP TABLE `#{escape(table)}`"
        execute sql
      end
      
    end
  end
end