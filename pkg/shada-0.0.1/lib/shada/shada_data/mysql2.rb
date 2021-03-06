require 'mysql2'

module Shada
  module Data
    module MYSQL2
      
      include Shada::Utils
      
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods

      end

      def get_primary table
        if @primary.nil?
          get_connection.get_primary db, table
        end
      end
      
      def get_timestamp table
        if @timestamp.nil?
          get_connection.get_timestamp db, table
        end
      end

      def get_fields table
        get_connection.get_fields(table)
      end
      
      def last_id
        get_connection.last_id
      end
      
      def get_ids result
        ids = []
        begin
          result.each do |row|
            ids.push row[@primary_sym]
          end
        rescue => e
        end

        ids
      end
      
      def count_rows params=nil
        table = @table
        get_connection.get_row_count_for table, params
      end
      
      def find_parent
        val = instance_variable_get("@#{belongs_to_hash[:col]}")
        @parent = get_connection.find belongs_to_hash[:table], '*', {:id => val}, 'id ASC'
      end
      
      def find_children
        
      end
      
      def filter_geo coords, distance=10, limit=10
        table = @table
        
        result = get_connection.filter_geo table, coords, distance, limit
        
        case result.count
        when 0
          puts "No results"
        when 1
          r = result.first
          @fields.each do |m|
            val = (r[m.to_sym]).class == String ? unescape(r[m.to_sym]) : r[m.to_sym]
            instance_variable_set("@#{m}", val)
          end

          #find_parent
          @records.push self
        else

          result.each do |r|
            obj = self.dup
            r.each do |field, val|
              obj.instance_variable_set("@#{field}", val)
            end
            @records.push obj
          end
        end

        return self
      end
      
      def find_for fields='*', params=nil, sort='id ASC'
        table = @table
        @records = nil
        @records = []
        @update = true
        
        k = "#{params.to_s}-#{sort}-#{@limit}-#{@offset}"
        
        if not cache.pull params.to_s
          result = get_connection.find table, '*', params, sort, @limit, @offset, self
          kresult = get_connection.find table, 'id', params, sort
          result = result.to_a
          cache.store k.to_s, {:result => result.to_a, :ids => get_ids(kresult)}
        else
          result = cache.pull(k.to_s)[:result]
          result = result.to_a
          #puts @cache.pull(params)[:ids]
        end
        
        save_cache table, cache
        
        #result = get_connection.find table, fields, params, sort, @limit, @offset, self
        
        case result.count
        when 0
          puts "No results"
        when 1
          r = result.first
          @fields.each do |m|
            val = (r[m.to_sym]).class == String ? unescape(r[m.to_sym]) : r[m.to_sym]
            instance_variable_set("@#{m}", val)
          end

          #find_parent
          @records.push self
        else

          result.each do |r|
            obj = self.dup
            r.each do |field, val|
              obj.instance_variable_set("@#{field}", val)
            end
            @records.push obj
          end
        end

        return self
      end
      
      def find params=nil, sort='id ASC', table=nil
        table = table.nil? ? @table : table
        @records = nil
        @records = []
        @update = true
        
        k = "#{params.to_s}-#{sort}-#{@limit}-#{@offset}"
        
        if not cache.pull params.to_s
          result = get_connection.find table, '*', params, sort, @limit, @offset, self
          kresult = get_connection.find table, 'id', params, sort
          result = result.to_a
          cache.store k.to_s, {:result => result.to_a, :ids => get_ids(kresult)}
        else
          result = cache.pull(k.to_s)[:result]
          result = result.to_a
          #puts @cache.pull(params)[:ids]
        end
        
        save_cache table, cache
        #result = get_connection.find table, '*', params, sort, @limit, @offset, self
        
        
        begin
          case result.count
          when 0
            puts "No results"
          when 1
            r = result.first
            @fields.each do |m|
              #puts "#{m} = #{r[m.to_sym]}"
              val = (r[m.to_sym]).class == String ? unescape(r[m.to_sym]) : r[m.to_sym]
              instance_variable_set("@#{m}", val)
            end

            #find_parent
            @records.push self
          else

            result.each do |r|
              obj = self.class.new
              r.each do |field, val|
                obj.instance_variable_set("@#{field}", val)
              end
              @records.push obj
            end
          end
        rescue => e
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
        begin
        @added_fields.each do |field|
          type, length = get_column_type instance_variable_get("@#{field}")
          length = length.nil? ? 255 : length
          get_connection.add_column table, field, type, length
        end
        rescue => e
        end
        
        keys = []
        values = []
        get_fields(table).each do |m|
          if m.to_s != @primary.to_s
            keys.push m
            values.push instance_variable_get("@#{m}")
          end
        end
        #puts "#{table} - #{keys} - #{values}"
        ret = get_connection.insert table, keys, values
        flush_cache
        @saving = false
        self
      end

      def update table
        begin
        @added_fields.each do |field|
          type, length = get_column_type instance_variable_get("@#{field}")
          length = length.nil? ? 255 : length
          get_connection.add_column table, field, type, length
        end
        rescue => e
        end
        
        fields = {}
        primary_value = instance_variable_get("@#{@primary}")
        get_fields(table).each do |m|
          if m.to_s != @primary.to_s && m.to_s != @timestamp.to_s
            fields[m.to_sym] = instance_variable_get("@#{m}")
          end
        end
        get_connection.update table, fields, primary_value, @primary
        #update_cache primary_value
        flush_cache
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
        valid_name = name.to_s.gsub(/=/, "").to_s
        @added_fields.push valid_name
        @fields.push valid_name
        
        instance_variable_set("@#{valid_name}", val)

        puts "Creating Column with #{instance_variable_get("@#{valid_name}")}"
        
      end
      
      def get_column_type val
        if val.is_a?(String)
          if val.size < 256
            type = "VARCHAR"
            length = 255
          else
            type = "TEXT"
            length = ""
          end
        elsif val.is_a?(Bignum) or val.is_a?(Fixnum)
          type = "INT"
          length = 11
        elsif val.nil?
          type = "VARCHAR"
          length = 255
        end

        return type, length
      end

      def update_cache primary_val
        cache.each_page do |page|
          page.value[:ids].find do |i|
            #puts "Size: #{cache.size}"
            cache.remove_node page if i.to_i == primary_val.to_i
            #puts "Size: #{cache.size}"
          end
        end
      end
      
      def flush_cache
        cache.purge
      end

    end
  end
end