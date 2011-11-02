@tasks = {}

module Shada
  module CLI
    def self.included(base)
      self.instance_eval(base)
      @task = ARGV[0]
      puts @tasks
    end
    
    def task arg, &block
      @tasks[arg] = block
    end
  end
end

include Shada::CLI