require 'sinatra'
require 'sprockets'
require_relative 'config'

module Days
  class App < Sinatra::Base
    set(:sprockets, Sprockets::Environment.new.tap { |env|
      # env.append_path "#{root}/javascripts"
      # env.append_path "#{root}/stylesheets"
    })

    set(:rack, Rack::Builder.app {
      app = ::Days::App
      map '/' do
        run app
      end

      map '/assets' do
        run app.sprockets
      end
    })

    set(:config, nil)

    class << self
      alias environment_orig= environment=
      def environment=(x)
        environment_orig = x
        Config.namespace x.to_s
        x
      end
    end
  end
end
