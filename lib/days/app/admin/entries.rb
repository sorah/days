module Days
  class App < Sinatra::Base
    get "/admin/entries", :admin_only => true do
      @entries = Entry.all
      haml :'admin/entries/index', layout: :admin
    end

    get "/admin/entries/new", :admin_only => true do
      @entry = Entry.new
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
        unless @entry.published_at
          @entry.published_at = Time.now
        end
        if @entry.save
          redirect "/admin/entries/#{@entry.id}" # FIXME: Permalink
        else
          status 406
          haml :'admin/entries/form', layout: :admin
        end
      else
        halt 400
      end
    end

    get "/admin/entries/:id", :admin_only => true do
      @entry = Entry.where(id: params[:id]).first || halt(404)
      haml :'admin/entries/form', layout: :admin
    end

    put "/admin/entries/:id", :admin_only => true do
      entry = params[:entry] || halt(400)
      @entry = Entry.where(id: params[:id]).first || halt(404)

      entry[:categories] = Category.where(
        id: (entry[:categories] || {}).keys.map(&:to_i)
      )
      @entry.update_attributes(entry)

      if @entry.save
        redirect "/admin/entries/#{@entry.id}"
      else
        status 406
        haml :'admin/entries/form', layout: :admin
      end
    end

    delete "/admin/entries/:id", :admin_only => true do
      @entry = Entry.where(id: params[:id]).first || halt(404)
      @entry.destroy

      redirect "/admin/entries"
    end

    post "/admin/entries/preview", :admin_only => true do
    end
  end
end
