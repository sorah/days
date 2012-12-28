module Days
  class App < Sinatra::Base
    get "/admin/categories", :admin_only => true do
      @categories = Category.all
      haml 'admin/categories'
    end

    post "/admin/categories", :admin_only => true do
      category = params[:category] || halt(400)
      @category = Category.new(category)

      if @category.save
        redirect "/admin/categories"
      else
        status 406
        haml 'admin/categories'
      end
    end

    put "/admin/categories/:id", :admin_only => true do
      category = params[:category] || halt(400)
      @category = Category.where(id: params[:id]).first || halt(404)

      @category.update_attributes(category)

      if @category.save
        redirect "/admin/categories"
      else
        status 406
        haml 'admin/categories'
      end
    end

    delete "/admin/categories/:id", :admin_only => true do
      @category = Category.where(id: params[:id]).first || halt(404)
      @category.destroy

      redirect "/admin/categories"
    end
  end
end
