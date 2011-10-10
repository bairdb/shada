require_relative 'shada_app/controller'

module Shada
  class App < Shada::Engine
    def on_connect
    end

    def handle data
      @form['Content-Type'] = 'text/html'
      #controller = 
      route @form.get_path
      'Test'
    end
  end
end
