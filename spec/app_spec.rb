require 'spec_helper'

describe Days::App do
  include Rack::Test::Methods
  let(:app) do
    described_class.rack
  end

  before(:all) do
    described_class.config = Days::Config.new(File.join(File.dirname(__FILE__), 'environment'))
  end
end
