require 'shada'

Dir.chdir File.dirname(__FILE__)

Shada::Config.load_config 'config/main.yml'

#Dir["#{Shada::Config['ControllerPath']}*.rb"].each { |f| require_relative f }

Shada::App.start