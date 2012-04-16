require 'mongo'
require 'json'

module Shada
  module Adapter
    class MongoDB
      
      def connect db
        @db = Mongo::Connection.new.db(db)
        self
      end

      def authenticate username, password
        auth = @db.authenticate(username, password)
        auth
      end
      
      def count table
        col = load table
        col.count
      end
      
      def get_primary
        "_id"
      end
      
      def get_fields table
        
      end
      
      def get_timestamp db, table
        
      end
      
      def load_all
        @db.collection_names
      end

      def load collection
        @db.collection(collection)
      end

      def find collection, cols, values={}, sort="", limit=0, offset=0, klass=nil
        col = load collection
        i = 0
        if cols.count > 0
          query = {}
          cols.each{|c|
            query[c] = values[i]
            i = i + 1
          }
          col.find(query)
        else
          col.find()
        end        
      end
      
      def view_all collection
        col = load collection
        col.find()
      end
      
      def insert collection, data, format='JSON'
        col = load collection
        puts col
        col.insert(data)    
      end

      def update collection, id, data, format='JSON'
        col = load collection
        col.update({'_id' => id}, data)
      end
      
      def destroy collection, id
        col = load collection
        col.remove({'_id' => id})
      end
      
      def delete_collection collection
        @db.delete(collection)
      end

      def destroy_db db
        @db.drop_database(db)
      end
      
    end
  end
end