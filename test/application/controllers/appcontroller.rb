require 'shada'

class AppController < Shada::Controller
  path_map :controller, :page
  
  def index
    render 'Index'
  end
  
  def something
    render 'Something'
  end
end