require 'rubygems'

gem "mocha", ">= 0.9.8"

require "mdt_reader"
require "mocha"
require "spec"

Spec::Runner.configure do |config|
  config.mock_with :mocha
end