require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

$: << File.expand_path("../../lib", File.dirname(__FILE__))

require_relative '../../lib/service_broker_api'
require_relative '../../lib/mysql_broker/mysql_broker'
require 'rack/test'
require 'cucumber/rspec/doubles'

module AppHelper
  def app
	MysqlBroker
  end
end

World(Rack::Test::Methods, AppHelper)
