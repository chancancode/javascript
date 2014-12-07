require "bundler/setup"
require "minitest/autorun"
require "minitest/pride"
require "active_support"
require "active_support/testing/declarative"
require "active_support/testing/setup_and_teardown"
require "active_support/testing/isolation"

I18n.enforce_available_locales = true

class TestCase < Minitest::Test
  extend ActiveSupport::Testing::Declarative
  include ActiveSupport::Testing::SetupAndTeardown
  include ActiveSupport::Testing::Isolation
end
