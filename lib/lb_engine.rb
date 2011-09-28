require 'lb_server'
require 'fiber'
require 'time'
require 'cgi'
require 'uuid'

require_relative 'lb_engine/engine_build'
require_relative 'lb_engine/headers'
require_relative 'lb_engine/multipart_parser'

module LB
  class Engine
    include LB::Headers
    
    def initialize
      self
    end
    
    def start sender_id, pull_addr, sub_addr, &block
      @sender_id = sender_id
      @pull_addr = pull_addr
      @sub_addr = sub_addr
      @connection ||= LB::Response.new sender_id, pull_addr, sub_addr 
      
      if block_given?
        engine = EngineBuild.new self
        engine.instance_eval(&block)
      end
      
      run
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
        parse_headers @headers, @body
        
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

