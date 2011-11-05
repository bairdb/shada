module Shada
  class Multipart_Parser
    def initialize content_type
      @boundry = content_type.split('=')[1]
      return self
    end
    
    def parse file
      puts file
      return ""
    end
  end
end
