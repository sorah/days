ENV["RACK_ENV"] ||= 'test'
require 'days'
require 'days/models'
require 'days/migrator'
require 'rack/test'
require 'active_record'
require 'database_rewinder'
require 'pry'

Days::App.set :environment, :test

module AppSpecHelper
  include Rack::Test::Methods

  def app
    ::Days::App.rack
  end

  def response
    last_response
  end

  def env
    @env ||= {'rack.session' => session}
  end

  def session
    @session ||= {}
  end

  def last_render
    @renders.last
  end

  def render
    subject; @renders.last
  end

  def login(user)
    session.merge!(user_id: user.id)
    env
  end

  def self.included(k)
    k.module_eval do
      before(:all) do
        Days::App.config = RSpec.configuration.days_config
        ActiveRecord::Base.logger = nil
      end

      before(:each) do
        @renders = []
        unless self.example.metadata[:render]
          Days::App.any_instance.stub(:render) do |*args, &block|
            @renders << {engine: args[0], data: args[1], options: args[2] || {}, locals: args[3] || {}, ivars: args[4] || {}}
            ""
          end
          Days::App.class_eval do
            alias render_orig render
            def render(*args)
              render_orig *args, Hash[self.instance_variables.map{ |k| [k, instance_variable_get(k)] }]
            end
            private :render, :render_orig
          end
        end
      end
    end
  end
end

module SetupAndTeardown
  extend ActiveSupport::Concern
  module ClassMethods
    def setup(*methods)
      methods.each do |m|
        prepend_before do
          send m
        end
      end
    end

    def teardown(*methods)
      methods.each do |m|
        after do
          send m
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  # config.order = 'random'

  env = File.join(File.dirname(__FILE__), 'environment')
  config.add_setting :days_env, default: env
  config.add_setting :days_config, default: Days::Config.new(File.join(env, 'config.yml'))

  config.before(:suite) do
    Days::App.environment = ENV["RACK_ENV"] || :test
    config.days_config.establish_db_connection()
    ActiveRecord::Base.configurations = {'test' => Hash[config.days_config.database]}

    Days::Migrator.start(config.days_config, verbose: true)
    ActiveRecord::Base.logger = nil

    DatabaseRewinder.clean_all
  end

  config.after(:each) do
    DatabaseRewinder.clean
  end

  config.include AppSpecHelper, type: :controller

  config.tty = true
end

require_relative "./shared/admin"
