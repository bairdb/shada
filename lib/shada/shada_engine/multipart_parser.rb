module Shada
  class Multipart_Parser
    def initialize content_type
      @boundry = content_type.split('=')[1]
      return self
    end
    
    def parse file
      puts @boundry
      #file.scan(/Content-Type: message\/rfc822(.*?)--.*?\..*?/m).each{ |m|}
      puts file
      return ""
    end
  end
end
