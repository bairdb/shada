require 'shada'

SENDER_ID = "App"
SEND_ADDR = "tcp://127.0.0.1:9996"
RECV_ADDR = "tcp://127.0.0.1:9997"

class App < Shada::Engine
  def on_connect
  end
  
  def handle data
    puts @form[:test]
    @form['Content-Type'] = 'text/html'
    route @form.get_path
    'Test'
  end
end

class AppController < Shada::Controller
  path_map :controller, :view
  
  def index
    render 'Index'
  end
end


App.start SENDER_ID, RECV_ADDR, SEND_ADDR