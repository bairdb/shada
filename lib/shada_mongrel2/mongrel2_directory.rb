require 'shada'

module Shada
  module Mongrel2
    class Directory < Shada::Data::Core
      connect :database => "mongrel2", :adapter => 'sqlite3'
    end
  end
end