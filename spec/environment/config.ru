require 'bundler'
require 'days'
Bundler.require(:default, Days::App.environment)

Days::App.set :config, Days::Config.new("#{File.dirname(__FILE__)}/config.yml")
run Days::App.rack
