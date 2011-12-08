module Shada
  module Router
    def route path
      #begin
        path_arr = path.split '/'
        @rest_of_path = path_arr.dup
        @i = 0
        puts path
        reload Shada::Config['ControllerPath']
        reload Shada::Config['ModelPath']
        reload Shada::Config['LibPath']
        
        default = Shada::Config['DefaultController']
        
        controller = "#{(path_arr[1] || default).to_s.propercase}Controller"
        controller = is_class?(controller) ? controller : "#{default.to_s.propercase}Controller"
        
        @controller = Object.const_get(controller).new
        @controller.form = @form
        @controller.path.inject(1) do |i, p|
          @controller.instance_variable_set("@#{p}",path_arr[i])
          i + 1
        end
        
        rest = @rest_of_path.drop (@controller.path.count + 1)
        @controller.rest_of_path = rest
        @controller.route
#      rescue => e
#        msg = "#{e.message} - #{e.backtrace[0]}"
#        
#        if Shada::Config['Environment'] == 'Production'
#          log_error msg
#
#          Shada::Mail.send do
#            to "baird@lackner-buckingham.com", "Baird Lackner-Buckingham"
#            from "mail@reelfinatics.com", "Server Admin"
#            subject "Server Error"
#            message msg
#          end
#          
#          @controller.error_page
#        else
#          puts msg
#          @controller.error_page msg unless @controller.nil?
#        end
#      end
    end
  end
end