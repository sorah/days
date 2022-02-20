module Days
  class App < Sinatra::Base
    get "/admin/users", :admin_only => true do
      @users = User.all
      haml :'admin/users/index', layout: :admin
    end

    get "/admin/users/new", :admin_only => true do
      @user = User.new
      haml :'admin/users/form', layout: :admin
    end

    post "/admin/users", :admin_only => true do
      user = params[:user] || halt(400)
      @user = User.new(user)

      if @user.save
        redirect "/admin/users/#{@user.id}" # FIXME: Permalink
      else
        status 406
        haml :'admin/users/form', layout: :admin
      end
    end

    get "/admin/users/:id", :admin_only => true do
      @user = User.where(id: params[:id]).first || halt(404)
      haml :'admin/users/form', layout: :admin
    end

    put "/admin/users/:id", :admin_only => true do
      user = params[:user] || halt(400)
      @user = User.where(id: params[:id]).first || halt(404)

      if user[:password] == ""
        user.delete :password
      end

      @user.assign_attributes(user)

      if @user.save
        redirect "/admin/users/#{@user.id}"
      else
        status 406
        haml :'admin/users/form', layout: :admin
      end
    end

    delete "/admin/users/:id", :admin_only => true do
      @user = User.where(id: params[:id]).first || halt(404)

      if @user == current_user
        halt 400
      else
        @user.destroy
        redirect "/admin/users"
      end
    end
  end
end
