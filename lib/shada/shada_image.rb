require 'RMagick'

module Shada
  class Image
    attr_accessor :img
    
    def initialize img_name
      @img = Image.new "#{Shada::Config['ImagePath']}#{img_name}"
      img = img_name.split('.')
      @img_name = img[0]
      @img_ext = img[1]
    end
    
    def thumbnail width, height
      @img = @img.resize_to_fill width, height
      @img.write "#{Shada::Config['ThumbPath']}#{@img_name}_thumb.#{@img_ext}"
    end
  end
end