module LB
  module Headers
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
      end
      
    end
    
    def set_response_header key, val
      key = key.to_sym
      $_RESPONSE_HEADERS[key] = val
    end
    
    def get_cookie key
      $_COOKIES[key]
    end
    
    def set_cookie key, val
      $_RESPONSE_HEADERS['Set-Cookie'] = "#{key}=#{val}"
    end
    
    private
    
    def parse_headers headers, body
      types = [{:headers => headers['QUERY'], :type => 'get', :delimiter => '&'}, {:headers => body, :type => 'post', :delimiter => '&'}, {:headers => headers['cookie'], :type => 'cookie', :delimiter => ';'}]
      
      types.each do |hash|
        parse hash[:headers], hash[:type], hash[:delimiter]
      end
    end
    
    def parse headers, type, delimiter='&'
      headers.split(delimiter).each do |var|
        key, val = var.split('=')
        set_header key, val, type
      end
      
    end
    
  end
end
