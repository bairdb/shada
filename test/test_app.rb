require 'shada'

class AppController < Shada::Controller
  path_map :controller, :view
  
  def index
    render 'Index'
  end
end

Shada::App.start #SENDER_ID, RECV_ADDR, SEND_ADDR