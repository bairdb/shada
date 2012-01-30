require_relative 'shada_utils'
require_relative 'shada_app/controller'
require_relative 'shada_app/templator'
require_relative 'shada_app/generator'
require_relative 'shada_app/html'

module Shada
  class App < Shada::Engine
    include Shada::Utils
    
    def on_connect
    end

    def handle data, type='text/html'
      #@form['Content-Type'] = type
      route @form.get_path
    end
  end
end
