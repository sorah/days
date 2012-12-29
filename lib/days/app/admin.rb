module Days
  class App < Sinatra::Base
    get "/admin" do
      haml :'admin/index'
    end
  end
end
