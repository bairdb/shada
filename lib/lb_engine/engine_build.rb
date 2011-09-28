class EngineBuild
   def initialize klass
     @klass = klass
     return @klass
   end

   def on_connect &block
     @klass.class.send :define_method, :on_connect, &block
    end

    def on_disconnect &block
      @klass.class.send :define_method, :on_disconnect, &block
    end

    def on_read &block
      @klass.class.send :define_method, :on_read, &block

    end

    def on_write &block
      @klass.class.send :define_method, :on_write, &block      
    end
end