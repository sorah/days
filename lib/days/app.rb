require 'sinatra'
require 'sprockets'
require 'rack/csrf'
require_relative 'config'
require_relative 'models'

module Days
  class App < Sinatra::Base
    set(:sprockets, Sprockets::Environment.new.tap { |env|
      env.append_path "#{self.root}/app/javascripts"
      env.append_path "#{self.root}/app/stylesheets"
      env.append_path "#{self.root}/app/images"
    })

    set(:rack, Rack::Builder.app {
      app = ::Days::App
      map '/' do
        use Rack::Csrf if app.environment != :test
        run app
      end

      map '/assets' do
        run app.sprockets
      end
    })

    set(:config, nil)
    set :method_override, true

    configure :production, :development do
      enable :sessions
    end

    configure :test do
      set :raise_errors, true
      set :dump_errors, false
      set :show_exceptions, false
    end

    helpers do
      def logged_in?
        !!session[:user_id]
      end

      def current_user
        @current_user ||= session[:user_id] ? User.where(session[:user_id]).first : nil
      end
    end

    set :admin_only do |_|
      condition do
        unless logged_in?
          # TODO: return-path param
          redirect '/admin/login'
        end
      end
    end

    set :setup_only do |_|
      condition do
        if User.first
          halt 403
        end
      end
    end

    class << self
      alias environment_orig= environment=
      def environment=(x)
        self.environment_orig = x
        Config.namespace x.to_s
        x
      end

      alias config_orig= config=
      def config=(x)
        self.config_orig = x
        self.set :session_secret, config['session_secret'] || 'jjiw-jewn-n2i9-nc1e_binding.pry-is-good'
        self.set(:sprockets, Sprockets::Environment.new.tap { |env|
          env.append_path "#{config.root}/javascripts"
          env.append_path "#{config.root}/stylesheets"
          env.append_path "#{config.root}/images"
          env.append_path "#{self.root}/app/javascripts"
          env.append_path "#{self.root}/app/stylesheets"
          env.append_path "#{self.root}/app/images"
        })
        x
      end
    end
  end
end

Dir["#{File.dirname(__FILE__)}/app/**/*.rb"].each do |f|
  require f
end

