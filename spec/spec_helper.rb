ENV["RACK_ENV"] ||= 'test'
require 'active_record'
require 'database_rewinder'
require 'days'
require 'days/models'
require 'days/migrator'
require 'rack/test'

require 'pry'

Days::App.set :environment, :test
Days::App.set :raise_errors, true

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

      before(:example) do |example|
        @renders = []
        unless example.metadata[:render]
          allow_any_instance_of(Days::App).to receive(:render) do |instance, *args, &block|
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

  config.mock_with :rspec do |mocks|
    # In RSpec 3, `any_instance` implementation blocks will be yielded the receiving
    # instance as the first block argument to allow the implementation block to use
    # the state of the receiver.
    # In RSpec 2.99, to maintain compatibility with RSpec 3 you need to either set
    # this config option to `false` OR set this to `true` and update your
    # `any_instance` implementation blocks to account for the first block argument
    # being the receiving instance.
    mocks.yield_receiver_to_any_instance_implementation_blocks = true
  end
end

require_relative "./shared/admin"
