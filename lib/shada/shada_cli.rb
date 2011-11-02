module Shada
  module CLI
    def self.included(base)
      puts ARGV
    end
  end
end

include Shada::CLI