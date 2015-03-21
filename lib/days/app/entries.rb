require 'builder'
require 'active_support/core_ext/time/calculations'

module Days
  class App < Sinatra::Base
    not_found do
      entry = lookup_entry(request.path)

      if entry
        status 200

        case entry
        when Array
          @title = entry.map(&:title).join(', ')
          @entries = entry
          return haml(:entries)
        when Entry
          @title = entry.title
          return haml(:entry, locals: {entry: entry, full: true})
        end
      end

      entry = Entry.find_by(old_path: request.path)
      if entry
        return [301, {'Location' => entry_path(entry)}, ""]
      end
    end

    get '/' do
      @entries = Entry.published.page(params[:page] || 1)
      haml :entries
    end

    get '/category/:name' do
      category = Category.find_by(name: params[:name]) || halt(404)
      @entries = category.entries.published.page(params[:page] || 1)
      haml :entries
    end

    get '/:year/:month' do
      pass if /[^0-9]/ =~ params[:year] || /[^0-9]/ =~ params[:month]
      begin
        base = Time.local(params[:year].to_i, params[:month].to_i, 1, 0, 0, 0)
      rescue ArgumentError
        halt 404
      end

      range = (base.beginning_of_month .. base.end_of_month)
      @entries = Entry.where(published_at: range).published.page(params[:page] || 1)
      haml :entries
    end

    get '/feed' do
      content_type 'application/atom+xml'
      entries = Entry.published.page(params[:page])

      xml = Builder::XmlMarkup.new

      xml.instruct!

      xml.feed("xmlns" => 'http://www.w3.org/2005/Atom') do
        xml.id("tag:#{request.host},2005:#{request.fullpath.split(".")[0]}")

        xml.link(:rel => 'alternate', :type => 'text/html', :href => request.url.gsub(/feed$/,''))
        xml.link(:rel => 'self', :type => 'application/atom+xml', :href => request.url)
        xml.title config.title

        xml.updated(entries.map(&:updated_at).max)

        entries.each do |entry|
          xml.entry do
            xml.id "tag:#{request.host},2005:Entry/#{entry.id}"

            xml.published entry.published_at.xmlschema
            xml.updated entry.updated_at.xmlschema

            xml.link(rel: 'alternate', type: 'text/html', href: "#{request.url.gsub(/\/feed$/,'')}#{entry_path(entry)}")

            xml.title entry.title

            xml.content(entry.short_rendered { '... <a href="'+entry_path(entry)+'">Continue Reading</a>' }, type: 'html')
          end
        end
      end
    end
  end
end
