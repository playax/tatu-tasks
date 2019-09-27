require 'rspec'
require 'rack/test'

require 'dotenv/load'

ENV['RACK_ENV'] = 'test'

module RSpecMixin
  include Rack::Test::Methods

  def app
    described_class
  end
end

RSpec.configure do |config|
  config.include RSpecMixin
end
