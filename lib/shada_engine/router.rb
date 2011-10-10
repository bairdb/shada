DEFAULTCONTROLLER = 'app'

module Shada
  module Router
    def route path
      path_arr = path.split '/'
      controller = path_arr.last || DEFAULTCONTROLLER
      puts controller
    end
  end
end