require 'shada'

class Test < Shada::Data::Core
  connect :database => "localhost", :adapter => 'mongodb'
  #connect :database => 'test'
end

#class Pages < Shada::Data::Core
#  connect :database => 'test'
#  belongs_to 'category', 'parent'
#end
#
#class Category < Shada::Data::Core
#  connect :database => 'test'
#end

test = Test.new
test.find(:test_col => 4).each do |row|
  puts row
end

#page = Pages.new
#page.find :id => 1
#page.find :id => 1