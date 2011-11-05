module Shada
  class CLI
    
    def self.cli &block
      last = ARGV.last
      task = ARGV[0]
      puts "Shada: Running #{task}"
      unless last == "-h"
        @@tasks = {}
        klass = self.new
        if block_given?
          klass.instance_eval &block
        end
        @@tasks[task.to_sym].call klass.parse
      else
        if block_given?
          klass.instance_eval &block
        end
        puts klass.instance_variables
      end
    end
    
    def parse
      args = {}
      args_arr = []
      args_dict = {}
      
      i=0
      ARGV.each do |arg|
        if i > 0
          arg_p = arg.split(':')
          if arg_p.count > 1
            args_dict[arg_p[0]] = arg_p[1]
          else
            args_arr.push(arg)
          end
        end
        i = i+1
      end
      
      args[:dict] = args_dict
      args[:arr] = args_arr
      
      return args
    end
        
    def task arg, &block
      @@tasks[arg] = block
    end
  end
end

