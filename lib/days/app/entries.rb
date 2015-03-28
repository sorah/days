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

    private def generate_atom_feed(entries, title: config.title, html_path: '/feed')
      xml = Builder::XmlMarkup.new
      xml.instruct!
      xml.feed("xmlns" => 'http://www.w3.org/2005/Atom') do
        xml.id("tag:#{request.host},2005:#{request.fullpath.split(".")[0]}")

        xml.link(:rel => 'alternate', :type => 'text/html', :href => [request.base_url, config.base_path, html_path].join.gsub(%r{//}, '/'))
        xml.link(:rel => 'self', :type => 'application/atom+xml', :href => request.url)
        xml.title title

        xml.updated(entries.map(&:updated_at).max)

        entries.each do |entry|
          xml.entry do
            xml.id "tag:#{request.host},2005:Entry/#{entry.id}"

            xml.published entry.published_at.xmlschema
            xml.updated entry.updated_at.xmlschema

            xml.title entry.title

            href = [request.base_url, config.base_path, entry_path(entry)].join.gsub(%r{//}, '/')
            xml.link(rel: 'alternate', type: 'text/html', href: href)
            xml.content(entry.short_rendered { '... <a href="'+href+'">Continue Reading</a>' }, type: 'html')
          end
        end
      end
    end

    get '/feed' do
      entries = Entry.published.page(params[:page])

      content_type 'application/atom+xml'
      generate_atom_feed(entries)
    end

    get '/feed/category/:name' do
      category = Category.find_by(name: params[:name]) || halt(404)
      entries = category.entries.published.page(params[:page])

      content_type 'application/atom+xml'
      generate_atom_feed(entries, title: "#{config.title} (Category: #{category.name})", html_path: "/category/#{category.name}")
    end

  end
end
