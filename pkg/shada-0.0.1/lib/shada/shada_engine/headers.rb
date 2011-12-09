module Shada
  class Headers
    include Enumerable
    
    def [](key)
      key = key.to_sym
      return $_GET[key] unless $_GET[key] == nil
      return $_POST[key] unless $_POST[key] == nil
      return $_FILES[key] unless $_FILES[key] == nil
      return ''
    end
    
    def []= key, val
      set_response_header key, val
    end
    
    def redirect url, time=0
      value = "#{time}; url=#{url}"
      set_response_header 'Refresh', value
    end
    
    def get_header key, type='get'
      case type
      when 'response'
        $_RESPONSE_HEADERS[key]
      when 'get'
        $_GET[key]
      when 'post'
        $_POST[key]
      when 'cookie'
        get_cookie key
      when 'file'
        $_FILES[key]
      end
    end
    
    def set_header key, val, type='response'
      key = key.to_sym
      case type
      when 'get'
        $_GET[key] = val
      when 'post'
        $_POST[key] = val
      when 'cookie'
        $_COOKIES[key] = val
      when 'file'
        $_FILES[key] = val
      end
      
    end
    
    def set_response_header key, val
      key = key.to_sym
      $_RESPONSE_HEADERS[key] = val
    end
    
    def get_cookie key
      $_COOKIES[key]
    end
    
    def set_cookie key, val, expires='', path='', domain='', secure='FALSE'
      $_RESPONSE_HEADERS['Set-Cookie'] = "#{key}=#{val}; Domain=#{$_REQUEST['host']}; #{secure}"
    end
    
    def clear_cookie key
      $_RESPONSE_HEADERS['Set-Cookie'] = "#{key}="
    end
    
    def get_path
      $_REQUEST['headers']['PATH']
    end
    
    def parse_headers headers, body
      $_REQUEST['headers'] = headers
      types = [{:headers => headers['QUERY'], :type => 'get', :delimiter => '&'}, {:headers => body, :type => 'post', :delimiter => '&'}, {:headers => headers['cookie'], :type => 'cookie', :delimiter => ';'}]
      
      types.each do |hash|
        parse hash[:headers], hash[:type], hash[:delimiter]
      end
    end
    
    def post
      $_POST
    end
    
    def get
      $_GET
    end
    
    def request
      $_REQUEST
    end
    
    def cookies
      $_COOKIES
    end
    
    def files
      $_FILES
    end
    
    def to_s
      return "Request: #{$_REQUEST.to_s}\n Post: #{$_POST.to_s}\n Get: #{$_GET.to_s}\n Cookies: #{$_COOKIES.to_s}"
    end
    
    private
    
    def parse headers, type, delimiter='&'
      unless headers.nil?
        begin
          headers.split(delimiter).each do |var|
            key, val = var.split('=')
            set_header key, val, type
          end 
        rescue => e
        end
      end
      
    end
    
  end
end
