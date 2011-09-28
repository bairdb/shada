module Shada
  class Multipart_Parser
    def initialize content_type, file
      @boundry = content_type.split('=')[1]
      puts "#{content_type} - #{file} - #{@boundry}"
      puts @body
      return ""
    end
  end
end
