require 'thor'
require 'fileutils'
require_relative 'config'
require_relative 'app'
require_relative 'migrator'

module Days
  class Command < Thor
    SKELETON_PATH = File.expand_path(File.join(__FILE__, '..', '..', '..', 'skeleton', 'days'))
    desc "init [DIR]", "Initialize days.gem world in the directory (default = ./)"
    def init(dir = ".")
      puts "Initializing new Days environment on #{File.expand_path dir}"
      FileUtils.cp_r Dir["#{SKELETON_PATH}/*"], "#{dir}/"
    end

    desc "server", "Starts the server"
    method_option :config, :type => :string, :aliases => "-c"
    method_option :port, :type => :numeric, :aliases => "-p", :default => 3162
    method_option :bind, :type => :string, :aliases => "-b", :default => nil
    method_option :environment, :type => :string, :aliases => "-e", :default => "development"
    method_option :pid, :type => :string, :aliases => "-c"
    def server
      set_env
      App.config = config
      rack_options = {
        app: App.rack,
        Port: options[:port],
        Host: options[:bind],
        daemonize: options[:daemonize],
        environment: options[:environment],
        server: options[:server],
      }
      rack_options.merge!(pid: File.expand_path(options[:pid])) if options[:pid]
      Rack::Server.start(rack_options)
    end

    desc "precompile", "Precompile the assets for production"
    method_option :config, :type => :string, :aliases => "-c"
    def precompile
    end

    desc "migrate [ENV]", "Run database migration for environment (default = development)"
    method_option :config, :type => :string, :aliases => "-c"
    method_option :version, :type => :numeric, :aliases => "-v", :default => nil
    method_option :scope, :type => :string, :aliases => "-s"
    method_option :verbose, :type => :boolean, :aliases => "-V", :default => true
    def migrate(env = "development")
      set_env env
      Days::Migrator.start(config, options)
    end

    private

    def set_env(env = nil)
      App.environment = env || options[:environment] || ENV["RACK_ENV"] || :development
    end

    def config
      @_days_config ||= Config.new(options[:config] || "./config.yml")
    end
  end
end
