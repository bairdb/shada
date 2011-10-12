module Shada
  module Router
    def route path
      begin
        path_arr = path.split '/'
        
        reload Shada::Config['ControllerPath']
        
        controller = "#{(path_arr[1] || Shada::Config['DefaultController']).to_s.propercase}Controller"
        controller = is_class?(controller) ? controller : "#{Shada::Config['DefaultController'].to_s.propercase}Controller"
        
        @controller = Object.const_get(controller).new

        @controller.path.inject(1) do |i, p|
          @controller.instance_variable_set("@#{p}",path_arr[i])
          i + 1
        end

        @controller.route
      rescue => e
        puts e
      end
    end
  end
end