module LB
  module Setup
    def self.included(base)
      base.extend ClassMethods
    end
    
    module ClassMethods
      def connection
        @@conn
      end

      def cache
        @@cache
      end

      def connect hash
        @@hash = hash
        ENV['DB'] = hash[:database]
        adapter = hash[:adapter] || 'mysql'
        hash[:host] = hash[:host] || 'localhost'
        hash[:username] = hash[:username] || 'root'
        hash[:password] = hash[:password] || ''
        hash[:table] = self.name

        case adapter
          when nil
            raise "Adapter Not Specified"
          when "mysql"
            @@conn = LB::Data::MYSQL2.new
            @@conn.connect hash
          when "mongodb"
            @@conn = LB::Data::MongoDB.new
            @@conn.connect hash[:table]
          when "sqlite"
            @@conn = LB::Data::SQLite.new
            @@conn.connect hash[:database]
          else
            raise "Unknown Error"
        end

        setup self.name
      end 

      def setup table
        @@cache = LB::Data::Cache.new 100

        connection.get_fields(table).each do |m|
          add_method m
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
    end
  end
end
