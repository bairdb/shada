%Q{
  require 'shada'

  class %%name%%Controller < Shada::Controller
    path_map :controller, :page
    
    def index
      html="Add Content."
      render html
    end

  end
}