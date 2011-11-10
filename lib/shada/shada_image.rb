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
    
    def thumbnail width, height, path=""
      tmp_img = @img.resize_to_fill width, height
      tmp_img.write "#{Shada::Config['ThumbPath']}#{@img_name}_thumb.#{@img_ext}"
    end
    
    def resize width, height, path=""
      tmp_img = @img.resize_to_fit width, height
      tmp_img.write "#{Shada::Config['ImagePath']}#{@img_name}.#{@img_ext}"
    end
    
    def scale percent, path=""
      tmp_img = @img.scale percent
      tmp_img.write "#{Shada::Config['ImagePath']}#{@img_name}_scale_#{percent}.#{@img_ext}"
    end
    
    def format
      @img.format
    end
    
    def filesize
      @img.filesize
    end
    
    def width
      @img.columns
    end
    
    def height
      @img.rows
    end
  end
end