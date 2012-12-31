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
          @entries = entry
          haml :entries
        when Entry
          haml :entry, locals: {entry: entry}
        end
      else
        ''
      end
    end

    get '/' do
      @entries = Entry.published.page(params[:page] || 1)
      haml :entries
    end

    get '/:year/:month' do
      base = Time.local(params[:year].to_i, params[:month].to_i, 1, 0, 0, 0)
      range = (base.beginning_of_month .. base.end_of_month)
      @entries = Entry.where(published_at: range).published
      haml :entries
    end

    get '/feed' do
      content_type 'application/atom+xml'
      entries = Entry.published.last(50)

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

            xml.content(entry.rendered, type: 'html')
          end
        end
      end
    end
  end
end
