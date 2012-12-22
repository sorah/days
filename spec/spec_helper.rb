require 'days'
require 'days/migrator'
require 'rack/test'
require 'active_record'
require 'active_record/fixtures'
require 'active_support/test_case'
require 'pry'

Days::App.set :environment, :test

module AppSpecHelper
  include Rack::Test::Methods

  def app
    ::Days::App.rack
  end

  def self.included(k)
    k.module_eval do
      before(:all) do
        Days::App.config = RSpec.configuration.days_config
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

module FixturesAdapter
  extend ActiveSupport::Concern
  include SetupAndTeardown
  include ActiveRecord::TestFixtures

  included do
    self.fixture_path = "#{File.dirname(__FILE__)}/fixtures"
    self.use_transactional_fixtures = false
    self.use_instantiated_fixtures  = true
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
    Days::Migrator.start(config.days_config, verbose: true)
    ActiveRecord::Base.configurations = {'test' => Hash[config.days_config.database]}
  end

  config.include AppSpecHelper, type: :controller
  config.include FixturesAdapter

  config.tty = true
end
