require 'digest/md5'
require 'time'
require 'yaml'

module Shada
  module Data
    class Cache
      include Enumerable
      
      attr_reader :max, :head
      
      def initialize max
        @max = max
        @hash = {}
        
        @head = Node.new
        @tail = move_first Node.new
        
      end
      
      def timestamp
        Time.now.utc.iso8601.gsub(/\W/, '')
      end
      
      def store key, value
        key = key.dup.freeze if String === key && !key.frozen?

        n = @hash[key]

        unless n
          if size == @max
            n = delete_oldest
            n.key = key
            n.value = value
            n.timestamp = timestamp
          else
            n = Node.new key, value, timestamp
          end

          @hash[key] = n
        end
        #puts @hash
        move_first(n).value = value
      end
      
      def pull key, &b
        n = @hash[key]
        
        if n
          move_first(n).value
        else
          false
        end
      end
      
      def empty?
        @hash.empty?
      end
      
      def size
        @hash.size
      end
      
      def each_page
        n = @head.n
        
        until n.equal? @tail
          nxt = n.n
          yield n
          n = nxt
        end

        self
      end
      
      def purge
        until empty?
          delete_oldest
        end
      end
      
      def move_first node
        node.insert_after @head
      end
      
      def remove_node node
        n = @hash.delete node.key
        n.remove
        n
      end

      def delete_oldest
        n = @tail.p
        raise "Cannot delete from empty hash" if @head.equal? n
        remove_node n
      end
      
      
      Node = Struct.new :key, :value, :timestamp, :n, :p do
        def insert_after node
          return self if node.n.equal? self

          remove

          self.n = node.n
          self.p = node

          node.n.p = self if node.n
          node.n = self
        end
        
        def remove
          self.p.n = self.n if self.p
          self.n.p = self.p if self.n
          self.n = self.p = nil
          self
        end
      end
    
    end
  end
end

#test = Shada::Data::Cache.new 100
#hex = Digest::MD5.hexdigest("Test")
#
#test.store hex, "something"
#test.store "another", "thing"
#test.store "working?", "maybe"
#
#test.purge
#
#puts test.pull hex
#
#test.each_page do |page|
#  puts page
#end