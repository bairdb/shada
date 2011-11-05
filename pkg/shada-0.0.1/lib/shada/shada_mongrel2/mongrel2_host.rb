require 'shada/shada_data/core'

module Shada
  module Mongrel2
    class Host < Shada::Data::Core
      connect :database => Shada::Config['Mongrel2DB'], :adapter => 'sqlite'
    end
  end
end