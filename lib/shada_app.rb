require_relative 'shada_engine'
require 'cgi'
require 'cgi/session'

SENDER_ID = "99282720-C8E1-46CB-8945-6E373E9C0629"
SEND_ADDR = "tcp://127.0.0.1:9996"
RECV_ADDR = "tcp://127.0.0.1:9997"

module Shada
  class App < Shada::Engine
    def handle data
      puts get_header :test
      set_response_header 'Content-Type', 'text/html'
      
      'Test'
    end
  end
end

Shada::App.new.start SENDER_ID, RECV_ADDR, SEND_ADDR 
#do
#  on_connect do
#    puts "Connecting to server: #{@sender_id}"
#  end
#  
#  on_read do |data|
#    puts 'Test Method'
#    test_meth
#    'Test'
#  end
#  
#  on_disconnect do
#    puts 'Disconnecting'
#  end
#end