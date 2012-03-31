require 'RMagick'

module Shada
  class Image
    attr_accessor :img
    
    def initialize img_name, path=""
      path = path.nil? ? Shada::Config['ImagePath'] : path
      @img = Magick::Image.read("#{path}#{img_name}").first
      image = img_name.split('.')
      @img_name = image[0]
      @img_ext = image[1]
    end
    
    def thumbnail width, height, save=true, path=""
      path = path.nil? ? Shada::Config['ThumbPath'] : path
      tmp_img = @img.resize_to_fill width, height
      if save
        tmp_img.write "#{path}#{@img_name}.#{@img_ext}"
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
    
    def resize2 width, height, save=true, path=""
      path = path.nil? ? Shada::Config['ImagePath'] : path
      
      @img.change_geometry!("#{width}x#{height}") do |cols, rows, img|
       if cols < width || rows < height
        img.resize!(cols, rows)
        bg = Magick::Image.new(width,height){self.background_color = "white"}
        bg.composite(img, Magick::CenterGravity, Magick::OverCompositeOp)
       else
        img.resize!(cols, rows)
       end
      end
      
      @img.to_blob
      #if save
      #  main_image.write "#{path}#{@img_name}.#{@img_ext}" unless File.exists? "#{Shada::Config['ImagePath']}#{@img_name}.#{@img_ext}"
      #else
        
      #end
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