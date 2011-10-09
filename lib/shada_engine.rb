require_relative 'shada_server'
require 'fiber'
require 'time'
require 'cgi'
require 'uuid'

require_relative 'shada_engine/engine_build'
require_relative 'shada_engine/headers'
require_relative 'shada_engine/router'
require_relative 'shada_engine/multipart_parser'

module Shada
  class Engine
    include Shada::Router
    
    def initialize sender_id, pull_addr, sub_addr, connection
      @sender_id = sender_id
      @pull_addr = pull_addr
      @sub_addr = sub_addr
      @connection = connection
      @form = Shada::Headers.new
      self
    end
    
    def self.start sender_id, pull_addr, sub_addr, &block
      sender_id = sender_id
      pull_addr = pull_addr
      sub_addr = sub_addr
      connection ||= Shada::Response.new sender_id, pull_addr, sub_addr 
      
      klass = self.new sender_id, pull_addr, sub_addr, connection
      
      if block_given?
        engine = Shada::EngineBuild.new klass
        engine.instance_eval(&block)
      end
      
      klass.run
    end
    
    def on_connect
    end
    
    def on_disconnect
    end
    
    def handle data
    end
    
    def run
      on_connect
      
      @status_code = '200'
      @status = 'OK'
      
      loop do
        response = ''
        @request = @connection.recv
        @uuid, @id, @path, @headers, @body = @request
        
        @path_arr = @path.split '/'
        @form.parse_headers @headers, @body
        
        if @connection.is_disconnect(@headers)
          on_disconnect
        end
        
        response = handle @request
        
        unless response == :next
          @connection.reply_http @request, response, @status_code, @status 
        else
          next
        end
          
      end
    end
    
    def run_meth
      begin
        yield
      rescue => e
        puts e
      end
    end
  end
end

