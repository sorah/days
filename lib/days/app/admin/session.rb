module Days
  class App < Sinatra::Base
    get "/admin/login" do
      haml :'admin/login'
    end

    post "/admin/login" do
      unless params[:login_name] && params[:password]
        halt 400
      end

      user = User.where(login_name: params[:login_name]).first

      if user && user.authenticate(params[:password])
        session[:user_id] = user.id
        redirect '/admin'
      else
        status 401
        haml :'admin/login'
      end
    end

    post "/admin/logout" do
      session[:user_id] = nil
      redirect '/admin/login'
    end
  end
end
