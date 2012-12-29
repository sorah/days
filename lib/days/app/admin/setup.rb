module Days
  class App < Sinatra::Base
    get "/admin/setup", :setup_only => true do
      @user = User.new
      haml :'admin/setup'
    end

    post "/admin/setup", :setup_only => true do
      user = params[:user] || halt(400)
      @user = User.new(user)
      if @user.save
        session[:user_id] = @user.id
        redirect '/admin'
      else
        status 406
        haml :'admin/setup'
      end
    end
  end
end
