module Days
  class App < Sinatra::Base
    get "/admin/entries", :admin_only => true do
    end
  end
end
