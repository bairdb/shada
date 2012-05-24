module Shada
  module Router
    def route path
      begin
        unless path.is_a?(Hash)
          begin
            path_arr = path.split '/'
            @rest_of_path = path_arr.dup || []
          rescue => e
            path_arr = []
            @rest_of_path = []
          end
          @i = 0
          
          puts path
          
          username = @form.get_cookie(:username)
          uname = nil
          
          activity = nil
          activity = Shada::Activity.new
          activity.user = username || 'guest'
          activity.page = path.to_s
          activity.date_accessed = "#{DateTime.now}"
          activity.save
          
          reload Shada::Config['ControllerPath']
          reload Shada::Config['ModelPath']
          reload Shada::Config['LibPath']

          default = Shada::Config['DefaultController']

          controller = "#{(path_arr[1] || default).to_s.propercase}Controller"
          controller = is_class?(controller) ? controller : "#{default.to_s.propercase}Controller"
          
          unless username.nil? || username == ''
            user = UsersModel.new
            uname = user.find :username => username
          end
          
          @controller = Object.const_get(controller).new
          #puts "Adding: #{@form.post}"
          @controller.form = @form
          @controller.user = uname
          @controller.path = path
          @controller.path.inject(1) do |i, p|
            @controller.instance_variable_set("@#{p}",path_arr[i])
            i + 1
          end

          rest = @rest_of_path.drop (@controller.path.count + 1)
          @controller.rest_of_path = rest
          @controller.route
        else
          route path
        end
      rescue => e
        msg = "#{e.message} - #{e.backtrace[0]}"
        
        if Shada::Config['Environment'] == 'Production'
          log_error msg

          Shada::Mail.send do
            to "baird@lackner-buckingham.com", "Baird Lackner-Buckingham"
            from "mail@reelfinatics.com", "Server Admin"
            subject "Server Error"
            message msg
          end
          
          @controller.error_page
        else
          log_error msg
          puts msg
          @controller.error_page msg unless @controller.nil?
        end
      end
    end
  end
end