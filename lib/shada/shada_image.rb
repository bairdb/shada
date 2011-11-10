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
    
    def thumbnail width, height, save=true, path=""
      path = path.nil? ? Shada::Config['ThumbPath'] : path
      tmp_img = @img.resize_to_fill width, height
      if save
        tmp_img.write "#{path}#{@img_name}_thumb.#{@img_ext}" unless File.exists? "#{Shada::Config['ThumbPath']}#{@img_name}_thumb.#{@img_ext}"
      else
        tmp_img.to_blob
      end
    end
    
    def resize width, height, save=true, path=""
      path = path.nil? ? Shada::Config['ImagePath'] : path
      tmp_img = @img.resize_to_fit width, height
      if save
        tmp_img.write "#{path}#{@img_name}.#{@img_ext}" unless File.exists? "#{Shada::Config['ImagePath']}#{@img_name}.#{@img_ext}"
      else
        tmp_img.to_blob
      end
    end
    
    def scale percent, save=true, path=""
      path = path.nil? ? Shada::Config['ImagePath'] : path
      tmp_img = @img.scale percent
      
      if save
        tmp_img.write "#{path}#{@img_name}_scale_#{percent}.#{@img_ext}" unless File.exists? "#{Shada::Config['ImagePath']}#{@img_name}_scale_#{percent}.#{@img_ext}"
      else
        tmp_img.to_blob
      end
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