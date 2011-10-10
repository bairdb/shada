require 'shada'

class Handler < Shada::Data::Core
  connect :database => '/Users/bairdlackner-buckingham/development/CoffeaCMS/lib/server/config.sqlite', :adapter => 'sqlite'
end

class Pages < Shada::Data::Core
  connect :database => 'test'
  
  def check
    puts @name
  end
end

handler = Handler.new
handler.find.records.each do |r|
  puts r.send_ident
end


#page = Pages.new
#page.search_id_for_1
#puts page.name
#page.find(:parent => 0).records.each do |r|
#  r.name = "Change The Name Of This Page"
#  r.save
#end

