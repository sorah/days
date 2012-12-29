module Days
  class App < Sinatra::Base
    get "/admin" do
      haml :'admin/index', layout: :admin
    end
  end
end
