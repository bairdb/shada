require 'mongo'

module Shada
  module Data
    module MongoDB
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
      end

      def get_primary table
        get_connection.get_primary
      end

      def get_fields table
        get_connection.get_fields(table)
      end

      def get_ids result
        ids = []
        result.each do |row|
          ids.push row[@primary_sym]
        end

        ids
      end

      def find params
        @update = true
        cols = []
        vals = []

        params.map do |k,v|
          cols.push k.to_s
          vals.push v
        end

        result = get_connection.find @table, cols, vals

        if result.count > 1
          result.each do |r|
            obj = self.class.new
            r.each do |field, val|
              obj.instance_variable_set("@#{field}", val)
            end
            @records.push obj
          end

          return @records
        elsif result.count > 0
          result.each do |row|
            row.map do|valid_name, val|
              define_meth valid_name, val
              instance_variable_set("@#{valid_name}", val)
            end
          end
        else
          puts "No results"
        end
        self
      end

      def save

        if not @update
          insert @table
        else
          update @table
        end
      end

      def count
        get_connection.count @table
      end

      def update table
        data = update_fields
        get_connection.update @table, @_id, data
      end

      def insert table
        data = update_fields
        get_connection.insert @table, data
      end

      def destroy
        get_connection.destroy @table, @_id
        self
      end

      def add_column name, args, block
        val = args[0]

        valid_name = name.to_s.gsub(/=/, "").to_s

        define_meth valid_name, val

        instance_variable_set("@#{valid_name}", val)
        puts "Creating Column with #{valid_name} = #{val}"
      end

      def view_all
        col = get_connection.view_all @table
        col.each do |page|
          puts page
        end
      end

      private

      def update_fields
        data = {}

        @cols.each do |val|
          data[val] = instance_variable_get("@#{val}")
        end

        data
      end

      def define_meth valid_name, val, klass=self.class
        @cols.push valid_name

        klass.send :define_method, valid_name do
          instance_variable_get("@#{valid_name}")
        end

        klass.send :define_method, "#{valid_name}=" do |val|
          instance_variable_set("@#{valid_name}",val)
        end
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