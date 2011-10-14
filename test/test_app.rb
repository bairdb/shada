ENV['ROOT'] = '/home/admin/base/site/'
require 'shada'

Dir.chdir File.dirname(__FILE__)

Shada::Config.load_config "#{ENV['ROOT']}config/main.yml"

Shada::App.start