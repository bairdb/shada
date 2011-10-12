require 'shada'

class TestController < Shada::Controller
  path_map :controller, :page
  
  def index
    render 'Test Now.'
  end
  
  def something
    render 'Test Something'
  end
end