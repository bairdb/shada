module Shada
  class HTML
    
    attr_accessor :html, :data, :klass
    
    def initialize
      @doc = []
    end
    
    class << self
      def build data=[], cls=self, &block
        if block_given?
          @klass = klass = self.new
          klass.data = data
          klass.klass = cls
          yield @klass#klass.instance_eval &block
        end
        klass.render
        return klass
      end
    end
    
    def select attributes={}, &block
      tag = :select
      @doc << [:open, tag, attributes]
      yield @klass#instance_eval &block
      @doc<< [:close, tag]
    end
    
    def p value, attributes={}
      tag = :p
      @doc << [:open, tag, attributes] << [:value, value] << [:close, tag]
    end
    
    def input *args
      attributes = args.pop
      @doc << [:input, :input, attributes]
    end
    
    def textarea value, attributes={}
      tag = :textarea
      @doc << [:open, tag, attributes] << [:value, value] << [:close, tag]
    end
    
    def method_missing tag, *args, &block
      value = block ? nil : args.pop
      attributes = value.class == Hash ? value.dup : args.pop
      
      if value
        attributes.delete :inner_text
        @doc << [:open, tag, attributes] << [:value, value] << [:close, tag]
      else
        @doc << [:open, tag, attributes]
        yield @klass #instance_eval &block
        @doc << [:close, tag]
      end
    end
    
    def render
      @html ||= @doc.map {|i| create i}.join
    end
    
    def create part
      case part[0]
      when :input
        "<input #{attribs(part[2])} />"
      when :open
        "<#{part[1]} #{attribs(part[2])}>"
      when :close
        "</#{part[1]}>"
      when :value
        val = part[1]
        val.class == Hash ? val[:inner_text] : val
      end
    end
    
    def attribs attr
      str = ""
      unless attr.nil?
        attr.each do |k,v|
          str.insert(-1, "#{k.to_s}=\"#{v}\"")
        end
      end
      str
    end
  end
end