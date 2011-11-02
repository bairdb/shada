require 'net/smtp'

module Shada
  class Mail
    @@klass = ""
    attr_accessor :attributes, :protocol, :to, :from, :subject, :message, :body, :headers
    
    def initialize protocol, attributes
      @attributes = attributes
      @protocol = protocol
    end
    
    class << self
      
      def setup protocol, attributes, &block
        @@klass = self.new protocol, attributes
      end
      
      def send &block
        if block_given?
          @@klass.instance_eval &block
        end
        @@klass.sending
      end
    end
    
    def to addr=""
      @to = addr
      puts addr
    end

    def from addr=""
      @from = addr
      puts addr
    end

    def subject sub=""
      @subject = sub
      puts sub
    end
    
    def message msg=""
      @message = msg
      puts msg
    end
    
    def headers hdrs={}
      @headers = hdrs
      puts hdrs
    end
    
    def sending
      begin
        puts @to
        Net::SMTP.start(@attributes[:host], @attributes[:port], @attributes[:host], @attributes[:username], @attributes[:password], :plain) do |smtp|
          smtp.read_timeout = 480
          smtp.send_message @message, @from, @to
        end
      rescue => e
        puts e
      end
    end
    
  end
end

Shada::Mail.setup "smtp", {:host => 'smtp.emailsrvr.com', :port => 587, :username => 'mail@reelfinatics.com', :password => 'T1meLo4d!'}

Shada::Mail.send do
  to "baird@lackner-buckingham.com"
  from "mail@reelfinatics.com"
  subject "I've been thinking"
  message "Well, what have we here"
end
