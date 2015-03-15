require 'rack/csrf'

module Days
  module Helpers
    def config
      Days::App.config
    end

    def logged_in?
      !!session[:user_id]
    end

    def current_user
      @current_user ||= session[:user_id] ? User.where(id: session[:user_id]).first : nil
    end

    def csrf_token
      Rack::Csrf.csrf_token(env)
    end

    def csrf_tag
      Rack::Csrf.csrf_tag(env)
    end

    def entry_path(entry, allow_draft=false)
      return nil unless allow_draft || entry.published?

      published_at = entry.published_at
      hash = {
        year: published_at.year.to_s.rjust(2, '0'),
        month: published_at.month.to_s.rjust(2, '0'),
        day: published_at.day.to_s.rjust(2, '0'),
        hour: published_at.hour.to_s.rjust(2, '0'),
        minute: published_at.min.to_s.rjust(2, '0'),
        second: published_at.sec.to_s.rjust(2, '0'),
        slug: entry.slug, id: entry.id
      }
      config.permalink.gsub(/{(\w+?)}/) { hash[$1.to_sym] }
    end

    def lookup_entry(path)
      regexp = Regexp.compile(Regexp.escape(config.permalink).gsub(/\\{(\w+?)\\}/) { "(?<#{$1}>.+?)" } + "$")
      m = regexp.match(path)
      return nil unless m

      match = m.names.inject({}) do |hash, k|
        hash[k.to_sym] = m[k]
        hash
      end


      if match[:id] || match[:slug]
        if match[:id]
          query = Entry.where(id: match[:id])
        else
          query = Entry.where(slug: match[:slug])
        end

        entry = query.first
        return nil unless entry
        published_at = entry.published_at
        return nil unless published_at

        return nil if match[:slug]   && match[:slug]        != entry.slug
        return nil if match[:id]     && match[:id].to_i     != entry.id
        return nil if match[:year]   && match[:year].to_i   != published_at.localtime.year
        return nil if match[:month]  && match[:month].to_i  != published_at.localtime.month
        return nil if match[:day]    && match[:day].to_i    != published_at.localtime.day
        return nil if match[:hour]   && match[:hour].to_i   != published_at.localtime.hour
        return nil if match[:minute] && match[:minute].to_i != published_at.localtime.min
        return nil if match[:second] && match[:second].to_i != published_at.localtime.sec

        return entry
      else
        match_time = {}.tap do |h|
          [:year, :month, :day, :hour, :minute, :second].each do |k|
            h[k] = match[k] && match[k].to_i
          end
        end
        range_begin = Time.local(
          match_time[:year], match_time[:month] || 1, match_time[:day] || 1,
          match_time[:hour] || 0, match_time[:minute] || 0, match_time[:second] || 0
        )
        range_end = Time.local(
          match_time[:year], match_time[:month] || 12, match_time[:day] || 31,
          match_time[:hour] || 23, match_time[:minute] || 59, match_time[:second] || 59
        )

        query = Entry.where(published_at: (range_begin .. range_end))

        if query.count.zero?
          return nil
        elsif query.count == 1
          return query.first
        else
          return query
        end
      end
    end
  end
end
