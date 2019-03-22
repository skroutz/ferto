require "webmock/rspec"
require "factory_bot"
require "faker"

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "ferto"

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  config.before(:suite) do
    FactoryBot.find_definitions
  end
end
