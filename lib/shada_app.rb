require_relative 'shada_utils'
require_relative 'shada_app/controller'

module Shada
  class App < Shada::Engine
    include Shada::Utils
    
    def on_connect
    end

    def handle data
      @form['Content-Type'] = 'text/html' 
      route @form.get_path
    end
  end
end
