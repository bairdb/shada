@tasks = {}

module Shada
  module CLI
    def self.included(base)
      @task = ARGV[0]
      puts @tasks
    end
    
    def task arg, &block
      puts arg
      @tasks[arg] = block
    end
  end
end

include Shada::CLI