require 'shada/shada_data/core'

module Shada
  class Activity < Shada::Data::Core
    connect :database => "reelfinatics", :adapter => 'mongodb'
  end
end