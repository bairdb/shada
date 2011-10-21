require 'mysql2'

module Shada
  module Data
    class MYSQL
      
      def tables
        @db.select_db(@db_name)
        @db.list_tables
      end

      def fields table
        results = self.query(table, "*")
        results.fields
      end

      def get_fields host, db_name, table, user, password
        connect host, user, password, db_name
        fields table
      end

      def prepare sql
        @db.prepare sql
      end

      def execute stmt, *args
        stmt.execute *args
      end

      def last_insert
        @db.insert_id()
      end

      def query table, fields, where={}, sort=''
        begin
          where_arr = []
          where_str = ""
          where_str = where.map{|k,v| "#{k}=? #{v[1].to_s.upcase}"}.join(" ") unless where.nil?
          where.each{|k,v| where_arr.push v[0]}
          sort = "ORDER BY #{sort}" unless sort.empty?

          where_str = "WHERE #{where_str}" unless where_str.empty?

          #puts "SELECT #{fields} FROM #{table} #{where_str} #{sort}"

          stmt = self.prepare "SELECT #{fields} FROM #{table} #{where_str} #{sort}"
          self.execute stmt, *where_arr
          stmt
        rescue => e
          puts e
        end
      end

      def insert table, fields, data
        begin
          val_str = data.map{|v| "?"}.join(", ")
          stmt = self.prepare "INSERT INTO #{table} (#{fields.join(',')}) VALUES (#{val_str})"
          self.execute stmt, *data
        rescue => e
          p e
        end
      end

      def update table, fields, id, where_column='id'
        begin
          where_arr = []
          keys = fields.map{|k,v| "#{k}=?"}.join(", ")
          fields.each{|k,v| where_arr.push v}
          where_arr.push id
          stmt = self.prepare "UPDATE #{table} SET #{keys} WHERE #{where_column}=?"
          self.execute stmt, *where_arr
        rescue => e
          p e
        end
      end

      def destroy table, id, where_column='id'
        stmt = self.prepare "DELETE FROM #{table} WHERE #{where_column}=?"
        self.execute stmt, id
      end

      def close stmt
        stmt.close
      end
      
      def method_missing name, *args
        
      end
      
      def connect hash
        @db_name = db
        begin
          @db = Mysql2::Client.new hash
        rescue => e
          puts e
          @db = nil
        end
        self
      end
      
    end
  end
end