#!/usr/bin/env ruby -wKU

require "iconv"
require 'shada/shada_logger'
require 'shada/shada_utils'

module Shada
  class Templator
    
    include Shada::Logger
    
    attr_accessor :registry, :html
    
    def initialize
      @ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')

      
      @pattern = /\{\$([^\r\n]*?)\}/m
      @alt_pattern = /\[\$(.*?)\]/m
      @include_pattern = /\{\include file\=\"(.*?)\"\}/
      @result_pattern = /\{results for \$(.*?)}(?:(.*?))\{\/results\}/m
      @result_var_pattern = /\[\$(.*)\]/
      @function_pattern = /\{\$(.*?)\->(.*?)\}/
      @array_pattern = /\{\$(.*?)\>(.*?)\}/
      @file_pattern = /\{file\=\"(.*)\"\}/
      @block_pattern = /\{block\=\"(.*)\"\}/
      
      @tag_arr = []
      @rep_arr = []
      
      @html = ''
      @tags = []
      
      @flow = {:include => 'includes', :file => 'files', :value => 'values', :image => 'images', :array => 'arrays'}
      @flow2 = {:result => 'results', :function => 'functions'}
      @parse_arr = {:result => '->', :function => '->', :array => '>'}
      
      @content_arr = []
      @result_arr = []
      
      @registry = {}
    end
    
    #register
    def register key, val, type="value" 
      @registry[key] = {:value => val, :type => type}
    end
    
    def unregister key
      @registry.delete key
    end
    
    def open_template file
      File.read file
    end
    
    def init template
      @html = open_template template
      @html = @ic.iconv(@html)
      includes
      preprocess_results
      parse 1
      parse 2
      render
      results
      #files
      #block
    end
    
    def gettags
      @html = @ic.iconv(@html)
      @tags = @html.scan @pattern
    end
    
    def parse pass
      gettags
      @registry.each do |key, val|
        type = val[:type]
        parse_val = @parse_arr[type]
        @tags.each do |tag|
          tag_parse = parse_val ? tag[0].split(parse_val) : ''
          tag_clean = parse_val ? tag_parse[0] : tag[0]
          if tag_clean == key.to_s
            arr = pass == 1 ? @flow : @flow2
            if arr.has_key? type.to_sym
              value = val[:value]
              self.send arr[type.to_sym], {:value => value, :key => key, :tag => tag[0], :parse_val => parse_val}
            end
          end
        end
      end      
    end
    
    def values hash
      @tag_arr.push /\{\$#{hash[:key]}\}/s
      @rep_arr.push hash[:value]
      
      @tag_arr.zip(@rep_arr).each do |key, val|
        @html.gsub! key, val
      end
    end
    
   def includes
     @html = @ic.iconv(@html)
     inc = @html.scan @include_pattern
     tag_arr = []
     rep_arr = []
     inc.each do |val|
       pattern = /{include file="#{Regexp.quote(val[0])}"}/
       begin
        html = open_template val[0]
        @html.gsub! pattern, html
       rescue => e
         #puts e.message
         @html.gsub! pattern, ''
       end
     end
   end
   
   def arrays hash
     tag = hash[:tag].split hash[:parse_val]
     hash[:value].each do |key, val|
       arr_val = key == tag[1].to_sym ? val : ''
       unless arr_val.nil?
         @tag_arr.push /\{\$#{Regexp.quote(hash[:tag])}\}/
         @rep_arr.push arr_val
       end
     end
   end
   
   def functions hash, result=false
     value = hash[:tag].split hash[:parse_val]
     val = @registry[value[0]] 
     klass = val[:value].class == String ? Object.const_get(val[:value]).new : val[:value]
     klass_name = val[:value].class == String ? val[:value].to_s : val[:value].class.to_s
     function = value[1]
     function_pieces = function.scan /(.*)\((.*)\)/ || function
     function_name = function.gsub /\((.*)\)/, ''
     oparam_arr = function_pieces[0][1].split(',').map{|val| val.strip}
     res = klass.send function_name.to_sym, *oparam_arr
     
     unless result
       reg_str = Regexp.quote "{$#{value[0]}->#{function}}"
       @html.gsub! /#{reg_str}/, res
     else
       res
     end
   end
   
   def preprocess_results
     @html = @ic.iconv(@html)
     @html.scan(@result_pattern).inject(1) do |i, result|
        @content_arr.push result[1]
        @html = @html.gsub /\{results for \$#{Regexp.quote(result[0])}\}(.*?)\{\/results\}/m, "{results for $#{result[0]}}%%replacement_#{i}%%{/results}"
        i + 1
     end
   end
   
   def results
     tags = []
     rep = []
     
     @html = @html.force_encoding("UTF-8")#@ic.iconv(@html)
     @html.scan(@result_pattern).inject(1) do |i, result|
       @rep_pattern = @content_arr[i - 1].to_s.strip
       @tmp = ""
       
       begin
        puts "HTML: #{@html.nil?}"
        puts "Array: #{@content_arr[i - 1].nil?}"
        @html = @html.gsub "%%replacement_#{(i - 1)}%%", @content_arr[i - 1]
        @content_arr.delete_at(i - 1)
       rescue => e
         puts "#{e.message} - #{e.backtrace}"
       end
       
       #preprocess_results
       
       hash = {:tag => result[0], :parse_val => @parse_arr[:function]}
       arr = functions hash, true
       if arr.class == Array
         arr.each do |row|
           lrep = @rep_pattern
           if row.class == Hash
             row.each do |k,v|
               puts "#{k} - #{v}"
               lrep = lrep.gsub /\{\$#{k.to_s}\}/, v           
             end
             @tmp.insert -1, lrep
             lrep = ""
           else
             row.fields.each do |f|
               lrep = lrep.gsub /\{\$#{f.to_s}\}/, "#{row.instance_variable_get("@#{f.to_s}")}"
             end
             @tmp.insert -1, lrep
             lrep = ""
           end
         end
       end
       
       @html.gsub! /\{results for \$#{Regexp.quote(result[0])}\}(.*?)\{\/results\}/m, @tmp
       i + 1
     end
   end
   
   def render
   end    
  end
end