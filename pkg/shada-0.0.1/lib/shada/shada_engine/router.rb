module Shada
  module Router
    def route path
      begin
        path_arr = path.split '/'
        puts path
        reload Shada::Config['ControllerPath']
        
        controller = "#{(path_arr[1] || Shada::Config['DefaultController']).to_s.propercase}Controller"
        controller = is_class?(controller) ? controller : "#{Shada::Config['DefaultController'].to_s.propercase}Controller"
        
        @controller = Object.const_get(controller).new
        @controller.form = @form
        @controller.path.inject(1) do |i, p|
          @controller.instance_variable_set("@#{p}",path_arr[i])
          i + 1
        end

        @controller.route
      rescue => e
        puts e.message
        puts "#{e.backtrace[0]}"
        ""
      end
    end
  end
end