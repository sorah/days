module Days
  class App < Sinatra::Base
    get "/admin" do
      redirect "/admin/"
    end

    get "/admin/", admin_only: true do
      haml :'admin/index', layout: :admin
    end
  end
end
