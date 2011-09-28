require 'ffi-rzmq'
require 'json'
require 'uuid'
require 'time'

require_relative 'request'

$_RESPONSE_HEADERS = {}

CTX = ZMQ::Context.new(1)

module LB
  class Response
    def initialize sender_id, sub_addr, pub_addr
       @sender_id = sender_id
       
      request = CTX.socket(ZMQ::PULL)
      request.connect(sub_addr)
      
      response = CTX.socket(ZMQ::PUB)
      response.setsockopt(ZMQ::IDENTITY, sender_id)
      response.connect(pub_addr)
      
      @sub_addr = sub_addr
      @pub_addr = pub_addr
      @request = request
      @response = response
      
    end
    
    def recv
      LB::Request.parse @request.recv_string(0)
    end
    
    def recv_json
      request = @request.recv_string(0)
      
      if not request.data
        request.data = JSON.parse request.body
      end
      
      return request
    end
    
    def send uuid, conn_id, msg
      header = "#{uuid} #{conn_id.size}:#{conn_id},"
      @response.send_string "#{header} #{msg}"
    end
    
    def reply req, msg
      send req[0], req[1], msg
    end
    
    def reply_json req, msg
      send req[0], req[1], JSON.generate(msg)
    end
    
    def reply_http req, body, code="200", status="OK", headers=nil
      reply req, http_response(body, code, status, $_RESPONSE_HEADERS)
    end
    
    def deliver uuid, idents, data
      send uuid, idents.join(' '), JSON.generate(data)
    end
    
    def deliver_http uuid, idents, body, code="200", status="OK", headers=nil
      deliver uuid, idents, http_response(body, code, status, headers || {})
    end
    
    def close req
      reply req, ""
    end
    
    def deliver_close uuid, idents
      deliver uuid, idents, ""
    end
    
    def is_disconnect headers 
      if headers['METHOD'] == 'JSON'
        #return @data['type'] == 'disconnect'
      end
    end
    
    def should_close
      if @headers['connection'] == 'close'
        true
      elsif @headers['VERSION'] == 'HTTP/1.0'
         true
      else
        false
      end
    end
    
    private
    def http_response body, code, status, headers
      if body.nil?
        headers['Content-Length'] = 0 
      else  
        headers['Content-Length'] = body.size 
      end
      @payload_headers = headers.map{|key,val| "#{key}: #{val}"}.join("\r\n")

      return "HTTP/1.1 #{code} #{StatusMessage[code]}\r\n#{@payload_headers}\r\n\r\n#{body}"
    end
    
    StatusMessage = {
      100 => 'Continue',
      101 => 'Switching Protocols',
      200 => 'OK',
      201 => 'Created',
      202 => 'Accepted',
      203 => 'Non-Authoritative Information',
      204 => 'No Content',
      205 => 'Reset Content',
      206 => 'Partial Content',
      300 => 'Multiple Choices',
      301 => 'Moved Permanently',
      302 => 'Found',
      303 => 'See Other',
      304 => 'Not Modified',
      305 => 'Use Proxy',
      307 => 'Temporary Redirect',
      400 => 'Bad Request',
      401 => 'Unauthorized',
      402 => 'Payment Required',
      403 => 'Forbidden',
      404 => 'Not Found',
      405 => 'Method Not Allowed',
      406 => 'Not Acceptable',
      407 => 'Proxy Authentication Required',
      408 => 'Request Timeout',
      409 => 'Conflict',
      410 => 'Gone',
      411 => 'Length Required',
      412 => 'Precondition Failed',
      413 => 'Request Entity Too Large',
      414 => 'Request-URI Too Large',
      415 => 'Unsupported Media Type',
      416 => 'Request Range Not Satisfiable',
      417 => 'Expectation Failed',
      500 => 'Internal Server Error',
      501 => 'Not Implemented',
      502 => 'Bad Gateway',
      503 => 'Service Unavailable',
      504 => 'Gateway Timeout',
      505 => 'HTTP Version Not Supported'
    }
    
  end
end
