module Days
  class App < Sinatra::Base
    get "/admin/categories", :admin_only => true do
      @categories = Category.all
      haml :'admin/categories', layout: :admin
    end

    post "/admin/categories", :admin_only => true do
      category = params[:category] || halt(400)
      @category = Category.new(category)

      if @category.save
        redirect "/admin/categories"
      else
        status 406
        @categories = Category.all
        haml :'admin/categories', layout: :admin
      end
    end

    put "/admin/categories/:id", :admin_only => true do
      category = params[:category] || halt(400)
      @category = Category.where(id: params[:id]).first || halt(404)

      @category.assign_attributes(category)

      if @category.save
        redirect "/admin/categories"
      else
        status 406
        @categories = Category.all
        haml :'admin/categories', layout: :admin
      end
    end

    delete "/admin/categories/:id", :admin_only => true do
      @category = Category.where(id: params[:id]).first || halt(404)
      @category.destroy

      redirect "/admin/categories"
    end
  end
end
