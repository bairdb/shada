module Shada
  module Data
    module Benchmark
      def self.benchmark
        beginning_time = Time.now
        yield
        end_time = Time.now
        puts "Process took #{(end_time - beginning_time)*1000}"
      end
    end
  end
end
