require_relative 'netstrings'

$_POST = {}
$_GET = {}
$_REQUEST = {}
$_COOKIES = {}
$_SESSIONS = {}
$_FILES = {}

module Shada
  class Request
    attr_accessor :sender, :path, :conn_id, :headers, :body, :data
    
    def initialize uuid, id, path, headers, body
      @sender = uuid
      @path = path
      @conn_id = id
      @headers = headers
      @body = body
      
      if @headers['METHOD'] == 'JSON'
        @data = JSON.parse @body
      else
        @data = {}
      end
    end
    
    def self.parse msg
      netstring = Shada::NetString.new
      uuid, id, p, rest = msg.split(" ",4)
      lheaders, rest = netstring.parse rest
      b, _ = netstring.parse rest

      lheaders = JSON.parse lheaders

      b = JSON.parse b if lheaders["METHOD"] == 'JSON'

      return uuid, id, p, lheaders, b
    end
    
  end
end
