require_relative 'shada_mongrel2'
require_relative 'shada_server'
require 'fiber'
require 'time'
require 'cgi'
require 'uuid'

require_relative 'shada_logger'
require_relative 'shada_mail'
require_relative 'shada_lang'

require_relative 'shada_engine/engine_build'
require_relative 'shada_engine/headers'
require_relative 'shada_engine/router'
require_relative 'shada_engine/multipart_parser'

Shada::Lang.load_lang "#{File.dirname(__FILE__)}/shada_lang/default.yml"

module Shada
  class Engine
    include Shada::Router, Shada::Logger
    
    def initialize sender_id, pull_addr, sub_addr, connection
      @sender_id = sender_id
      @pull_addr = pull_addr
      @sub_addr = sub_addr
      @connection = connection
      self
    end
    
    def self.start sender_id=nil, pull_addr=nil, sub_addr=nil, &block
      sender_id = sender_id || self.name.split('::').last
      handler = Shada::Mongrel2::Handler.new
      handler.find :send_ident => sender_id
      pull_addr = pull_addr || handler.send_spec
      sub_addr = sub_addr || handler.recv_spec
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
        @form = Shada::Headers.new
        @form.parse_headers @headers, @body
        
        if @connection.is_disconnect(@headers)
          on_disconnect
        end
        
        response = handle @request
        
        unless response == :next
          @connection.reply_http @request, response, @form.status_code, @form.status, @form.response_headers 
        else
          next
        end
          
      end
    end
  end
end

