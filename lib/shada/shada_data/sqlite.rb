require 'sqlite3'

module Shada
  module Data
    module SQLite
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def create
           puts "Creating"
        end
      end

      def get_primary table
        get_connection.get_primary db, table
      end

      def get_lastupdate table
        ""
      end
      
      def get_fields table
        get_connection.get_fields table
      end

      def get_ids result
        ids = []
        result.each do |row|
          ids.push row[0]
        end

        ids
      end

      def find params={}, table=nil
        table = table.nil? ? @table : table
        @records = nil
        @records = []
        @update = true
        
        if not cache.pull params
          result = get_connection.find table, '*', params, "id ASC"
          kresult = get_connection.find table, 'id', params, "id ASC"
          cache.store params, {:result => result, :ids => get_ids(kresult)}
        else
          result = cache.pull(params)[:result]
          result.reset
          #puts @cache.pull(params)[:ids]
          puts "cache"
        end
        
        
        case result.count
        when 0
          puts "No results"
        when 1
          result.reset
          r = result.next
          @fields.each do |m|
            #puts "#{m} = #{r[m]}"
            instance_variable_set("@#{m}", r[m])
          end

          @records.push self
        else
          result.reset
          result.each do |r|
            obj = self.class.new
            @records.push obj.find(@primary_sym => r[@primary])
          end
          return self
        end
        
        return self
      end

      def save
        @saving = true
        table = self.class.name.downcase.split('::').last
        table.to_s.gsub!("model", "") unless /.*model/i.match(table).nil?

        if not @update
          insert table
        else
          update table
        end
      end

      def insert table
        keys = []
        values = []
        get_fields(table).each do |m|
          if m.to_s != @primary.to_s
            keys.push m
            values.push instance_variable_get("@#{m}")
          end
        end
        ret = get_connection.insert table, keys, values

        puts ret
        @saving = false
        self
      end

      def update table
        fields = {}
        primary_value = instance_variable_get("@#{@primary}")
        get_fields(table).each do |m|
          if m.to_s != @primary.to_s
            fields[m.to_sym] = instance_variable_get("@#{m}")
          end
        end
        ret = get_connection.update table, fields, primary_value, @primary
        puts ret
        update_cache primary_value
        @saving = false
        self
      end

      def destroy
        table = self.class.name.downcase.split('::').last
        table.to_s.gsub!("model", "") unless /.*model/i.match(table).nil?
        
        primary_value = instance_variable_get("@#{@primary}")
        get_connection.destroy table, primary_value, @primary
        update_cache primary_value
        self
      end

      def add_column name, args, block
        table = self.class.name.downcase.split('::').last
        table.to_s.gsub!("model", "") unless /.*model/i.match(table).nil?
        
        val = args[0]

        type, length = get_column_type val

        valid_name = name.to_s.gsub(/=/, "").to_s
        get_connection.add_column table, valid_name, type, length

        instance_variable_set("@#{valid_name}", val)

        puts "Creating Column with #{valid_name}, #{val}, #{type}"
      end

      def get_column_type val
        if val.is_a?(String)
          if val.size < 256
            type = "TEXT"
            length = 0
          else
            type = "TEXT"
            length = 0
          end
        elsif val.is_a?(Bignum) or val.is_a?(Fixnum)
          type = "INTEGER"
          length = 0
        elsif val.is_a?(FLOAT)
          type = "INTEGER"
          length = 0
        elsif val.nil?
          type = "VARCHAR"
          length = 255
        end

        return type, length
      end

      def update_cache primary_val
        cache.each_page do |page|
          page.value[:ids].find do |i|
            #puts "Size: #{@cache.size}"
            cache.remove_node page if i.to_i == primary_val.to_i
            #puts "Size: #{@cache.size}"
          end
        end
      end
    end
  end
end