module Shada
  class CLI
    
    def self.cli &block
      task = ARGV[0]
      @@tasks = {}
      klass = self.new
      if block_given?
        klass.instance_eval &block
      end
      puts @@tasks
    end
    
    def task arg, &block
      @@tasks[arg] = block
    end
  end
end

