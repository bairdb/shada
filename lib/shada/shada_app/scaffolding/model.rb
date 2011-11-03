%Q{
  require 'shada'
  
  class %%name%%Model < Shada::Data::Core
    connect :host => %%host%%, :database => %%database%%, :adapter => %%adapter%%
  end
}
