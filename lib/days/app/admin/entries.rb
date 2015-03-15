module Days
  class App < Sinatra::Base
    get "/admin/entries", :admin_only => true do
      @entries = Entry.order(id: :desc).page(params[:page] || 1)
      haml :'admin/entries/index', layout: :admin
    end

    get "/admin/entries/new", :admin_only => true do
      @entry = Entry.new
      @categories = Category.all
      haml :'admin/entries/form', layout: :admin
    end

    post "/admin/entries", :admin_only => true do
      entry = params[:entry]
      if entry
        if entry[:categories].is_a?(Hash)
          entry[:categories] = Category.where(
            id: entry[:categories].keys.map(&:to_i)
          )
        end

        @entry = Entry.new(entry)
        @entry.user = current_user

        if @entry.save
          redirect "/admin/entries/#{@entry.id}" # FIXME: Permalink
        else
          status 406
          @categories = Category.all
          haml :'admin/entries/form', layout: :admin
        end
      else
        halt 400
      end
    end

    get "/admin/entries/:id", :admin_only => true do
      @entry = Entry.find_by(id: params[:id]) || halt(404)
      @categories = Category.all
      haml :'admin/entries/form', layout: :admin
    end

    put "/admin/entries/:id", :admin_only => true do
      entry = params[:entry] || halt(400)
      @entry = Entry.find_by(id: params[:id]) || halt(404)

      entry[:categories] = Category.where(
        id: (entry[:categories] || {}).keys.map(&:to_i)
      )
      @entry.update_attributes(entry)

      if @entry.save
        redirect "/admin/entries/#{@entry.id}"
      else
        status 406
        @categories = Category.all
        haml :'admin/entries/form', layout: :admin
      end
    end

    delete "/admin/entries/:id", :admin_only => true do
      @entry = Entry.find_by(id: params[:id]) || halt(404)
      @entry.destroy

      redirect "/admin/entries"
    end

    post "/admin/entries/preview", :admin_only => true do
    end
  end
end
