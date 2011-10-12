require 'shada'

class Handler < Shada::Data::Core
  connect :database => Shada::Config['Mongrel2DB'], :adapter => 'sqlite'
end

class Pages < Shada::Data::Core
  connect :database => 'test'
  
  def check
    puts @name
  end
end

#handler = Handler.new
#handler.find.records.each do |r|
#  puts r.send_ident
#end


page = Pages.new
#page.search_id_for_1
#puts page.name
#Shada::Data::Benchmark.benchmark do
#  page.find(:parent => 1).records.each do |r|
#    puts r.name
#  end
#end

