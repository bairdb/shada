require_relative 'lb_data'

class Test < Core
  #connect :database => "localhost", :adapter => 'mongodb'
  connect :database => 'test'
end

class Pages < Core
  connect :database => 'test'
  belongs_to 'category', 'parent'
end

class Category < Core
  connect :database => 'test'
end

page = Pages.new
page.find :id => 1
page.find :id => 1