require File.expand_path('../spec_helper.rb', __FILE__)
require File.expand_path('../../web.rb', __FILE__)

RSpec.describe Sinatra::Application do
  it 'should greet' do
    get '/'

    expect(last_response).to be_ok
    expect(last_response.body).to eq('I\'m Healthy')
  end
end

