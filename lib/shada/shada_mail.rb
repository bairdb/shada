require 'net/smtp'
require 'net/pop'
require 'net/imap'

MESSAGE =  <<MESSAGE_END
From: %%from_name%% <%%from%%>
To: %%to_name%% <%%to%%>
MIME-Version: 1.0
Content-type: text/html
Subject: %%subject%%

%%message%%
MESSAGE_END

module Shada
  class Mail
    @@klass = ""
    attr_accessor :attributes, :protocol, :to, :from, :subject, :message, :body, :headers, :message_body, :from_name, :to_name, :content_type, :form
    
    def initialize protocol, attributes, form
      @attributes = attributes
      @protocol = protocol
      @form = form
    end
    
    class << self
      
      def setup protocol="smtp", attributes={}, form=nil
        @@klass = self.new protocol, attributes, form
      end
      
      def send &block
        @@klass.content_type
        if block_given?
          @@klass.instance_eval &block
        end
        @@klass.sending
      end
      
      def get &block
        if block_given?
          @@klass.instance_eval &block
        end
        
        @@klass.get_email
      end
    end
    
    def content_type type="text/html"
      @content_type = type
    end
    
    def to addr="", name=""
      @to = addr
      @to_name = name
    end

    def from addr="", name=""
      @from = addr
      @from_name = name
    end

    def subject sub=""
      @subject = sub
    end
    
    def message msg=""
      @message = msg
    end
    
    def headers hdrs={}
      @headers = hdrs
    end
    
    def build_message
       tags = {:to => "%%to%%", :to_name => "%%to_name%%", :from => "%%from%%", :from_name => "%%from_name%%", :subject => "%%subject%%", :message => "%%message%%"}
       @message_body = MESSAGE
       
      tags.each do |k,v|
        @message_body.gsub!(v, instance_variable_get("@#{k.to_s}"))
      end
    end
    
    def sending
      begin
        build_message
        Net::SMTP.start(@attributes[:host], @attributes[:port], @attributes[:host], @attributes[:username], @attributes[:password], :plain) do |smtp|
          smtp.read_timeout = 480
          smtp.send_message @message_body, @from, @to
        end
        
        @message_body = nil
        @from = nil
        @to = nil
        @subject = nil
        @to_name = nil
        @from_name = nil
      rescue => e
        puts e
      end
    end
    
    def get_email
      imap = Net::IMAP.new 'secure.emailsrvr.com', 993, true
      imap.login 'uploads@reelfinatics.com', 'T1meLo4d!'
      imap.select 'INBOX'
      imap.search(["NOT",  "DELETED"]).each do |message_id|
        puts message_id
      end
      imap.logout
      imap.disconnect
      
      #pop = Net::POP3.new 'smtp.emailsrvr.com'
      #pop.start 'mail@reelfinatics.com', 'T1meLo4d!'
      #pop.mails.each do |m|
      #  m.pop do |chunk|
      #    puts chunk
      #  end
      #end
      
    end
    
  end
end

Shada::Mail.setup "smtp", {:host => Shada::Config['MailHost'], :port => Shada::Config['MailPort'], :username => Shada::Config['MailUsername'], :password => Shada::Config['MailPassword']}

#Shada::Mail.setup "smtp", {:host => 'smtp.emailsrvr.com', :port => 587, :username => 'mail@reelfinatics.com', :password => 'T1meLo4d!'}
#
#Shada::Mail.send do
#  to "baird@lackner-buckingham.com", "Baird Buckingham"
#  from "test@test.com", "Somebody"
#  subject "I've been thinking"
#  message "Well, what have we here"
#end
#
#Shada::Mail.setup
#Shada::Mail.get
