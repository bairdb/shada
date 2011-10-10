require 'shada_data/core'

module Shada
  module Mongrel2
    class Server < Shada::Data::Core
      connect :database => MONGREL2DB, :adapter => 'sqlite'
    end
  end
end