ENV["RAILS_ENV"] ||= "test"
ENV["GOVUK_UPSTREAM_URI"] = "http://upstream-host.com"
# ENV["GOVUK_WEBSITE_ROOT"] = "http://www.test.gov.uk"
# ENV["GOVUK_APP_DOMAIN"] = "test.gov.uk"
ENV["GOVUK_APP_DOMAIN_EXTERNAL"] = "https://govuk-content-store-examples.herokuapp.com/"

require "simplecov"
SimpleCov.start "rails"

require File.expand_path("../config/environment", __dir__)
require "gds_api/test_helpers/content_store"
require "rspec/rails"
require "webmock/rspec"

GovukTest.configure
# WebMock.disable_net_connect!(
#   allow_localhost: true,
# )

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    #     be_bigger_than(2).and_smaller_than(4).description
    #     # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #     # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.include GdsApi::TestHelpers::ContentStore

  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

  config.disable_monkey_patching!
  config.default_formatter = "doc" if config.files_to_run.one?
  config.infer_spec_type_from_file_location!
  config.order = :random
  Kernel.srand config.seed
end
