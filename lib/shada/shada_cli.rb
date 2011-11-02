module Shada
  module CLI
    @tasks = {}
    def self.included(base)
      @task = ARGV[0]
      puts @tasks
    end
    
    def task arg, &block
      @tasks[arg] = block
    end
  end
end

include Shada::CLI