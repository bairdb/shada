require 'cgi'

module Shada
  class Headers
    include Enumerable
    
    attr_accessor :get, :post, :files, :cookies, :response_headers, :request_headers, :status, :status_code, :body
    
    def initialize
      @get = {}
      @post = {}
      @files = {}
      @cookies = {}
      @response_headers = {}
      @request_headers = {}
      @outgoing_cookies = []
      @status = 'OK'
      @status_code = 200
    end
    
    def [](key)
      key = key.to_sym
      
      if @get[key].is_a? String
        return CGI.unescape(@get[key]) unless @get[key] == nil
      else
        return @get[key] unless @get[key] == nil
      end
      
      if @post[key].is_a? String
        return CGI.unescape(@post[key]) unless @post[key] == nil
      else
        return @post[key] unless @post[key] == nil
      end
      
      if @files[key].is_a? String
        return CGI.unescape(@files[key]) unless @files[key] == nil
      else
        return @files[key] unless @files[key] == nil
      end
      return ''
    end
    
    def []= key, val
      set_response_header key, val
    end
    
    def redirect url, msg='See Other', code=303
      @status = msg
      @status_code = code
      set_response_header 'Content-Type', ''
      set_response_header 'Location', url
      #value = "#{time}; url=#{url}"
      #set_response_header 'Refresh', value
    end
    
    def get_header key, type='get'
      case type
      when 'response'
        @response_headers[key]
      when 'get'
        @get[key]
      when 'post'
        @post[key]
      when 'cookie'
        get_cookie key
      when 'file'
        @files[key]
      end
    end
    
    def set_header key, val, type='response'
      key = key.to_s.chomp.gsub(/\W/, '').to_sym
      case type
      when 'get'
        @get[key] = val
      when 'post'
        @post[key] = val
      when 'cookie'
        @cookies[key] = val
      when 'file'
        @files[key] = val
      end
      
    end
    
    def set_response_header key, val
      key = key.to_sym
      @response_headers[key] = val
    end
    
    def get_cookie key
      @cookies[key]
    end
    
    def set_cookie key, val, expires=nil, path='/', domain=nil, secure=nil, http=true
      cookie = "#{key}=#{val}"
      cookie = "#{cookie}; domain=#{Shada::Config['Host']}"
      cookie = "#{cookie}; expires=#{rfc2822(expires.clone.gmtime)}" unless expires.nil?
      cookie = "#{cookie}; path=#{path}"
      cookie = "#{cookie}; #{secure}" unless secure.nil?
      cookie = "#{cookie}; HTTPOnly" if http
      @outgoing_cookies.push cookie
      @response_headers['Set-Cookie'] = @outgoing_cookies.join(', ')
      @cookies.to_s
    end
    
    def clear_cookie key
      cookie = get_cookie key
      set_cookie key, cookie, Time.at(0)
    end
    
    def rfc2822 time
      wday = Time::RFC2822_DAY_NAME[time.day]
      mon = Time::RFC2822_MONTH_NAME[time.mon - 1]
      time.strftime("#{wday}, %d-#{mon}-%Y %H:%M:%S GMT")
    end
    
    def get_path
      @request_headers['headers']['PATH']
    end
    
    def parse_headers headers, body
      @body = body
      @request_headers['headers'] = headers
      types = [{:headers => headers['QUERY'], :type => 'get', :delimiter => '&'}, {:headers => body, :type => 'post', :delimiter => '&'}, {:headers => headers['cookie'], :type => 'cookie', :delimiter => "; "}]
      
      types.each do |hash|
        parse hash[:headers], hash[:type], hash[:delimiter]
      end
    end
    
    def request
      @request_headers
    end
    
    def to_s
      return "Request: #{@request_headers.to_s}\n Post: #{@post.to_s}\n Get: #{@get.to_s}\n Cookies: #{@cookies.to_s}"
    end
    
    private
    
    def parse headers, type, delimiter='&'
      unless headers.nil?
        begin
          headers.split(delimiter).each do |var|
            key, val = var.split('=')
            set_header key.chomp.to_sym, val, type
          end 
        rescue => e
        end
      end
      
    end
    
  end
end
