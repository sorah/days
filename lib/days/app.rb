require 'sinatra'
require 'sprockets'
require 'rack/csrf'
require_relative 'config'
require_relative 'models'
require 'haml'
require 'sass'

module Days
  class App < Sinatra::Base
    set :root, File.expand_path(File.join(__FILE__, '..', '..', '..', 'app'))

    set(:sprockets, Sprockets::Environment.new.tap { |env|
      env.append_path "#{self.root}/javascripts"
      env.append_path "#{self.root}/stylesheets"
      env.append_path "#{self.root}/images"
    })


    def self.rack
      Rack::Builder.app {
        app = ::Days::App
        use ActiveRecord::ConnectionAdapters::ConnectionManagement

        map '/' do
          if app.environment != 'test'
            use Rack::Session::Cookie
            use Rack::Csrf
          end
          if app.environment == 'development'
            app.dump_errors = true
            app.show_exceptions = true
            app.reload_templates = true
          end
          run app
        end

        map '/assets' do
          run app.sprockets
        end
      }
    end

    set(:config, nil)
    set :method_override, true

    set :haml, :escape_html => true

    helpers do
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

    alias find_template_orig find_template
    def find_template(views, name, engine, &block)
      app_views = File.expand_path(settings.config['views'] || ::File.join(settings.config.root, "views"))
      find_template_orig app_views, name, engine, &block
      find_template_orig views, name, engine, &block
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
          env.append_path "#{self.root}/javascripts"
          env.append_path "#{self.root}/stylesheets"
          env.append_path "#{self.root}/images"
        })
        config.establish_db_connection()
        x
      end
    end
  end
end

Dir["#{File.dirname(__FILE__)}/app/**/*.rb"].each do |f|
  require f
end

