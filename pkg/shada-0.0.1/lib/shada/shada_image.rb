require 'RMagick'

module Shada
  class Image
    attr_accessor :img
    
    def initialize img_name
      @img = Magick::Image.read("#{Shada::Config['ImagePath']}#{img_name}").first
      image = img_name.split('.')
      @img_name = image[0]
      @img_ext = image[1]
    end
    
    def thumbnail width, height
      puts @img
      tmp_img = @img.resize_to_fill width, height
      tmp_img.write "#{Shada::Config['ThumbPath']}#{@img_name}_thumb.#{@img_ext}"
    end
  end
end