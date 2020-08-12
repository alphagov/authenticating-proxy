require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module AuthenticatingProxy
  class Application < Rails::Application
    config.load_defaults 6.0

    # Enable per-form CSRF tokens. Previous versions had false.
    config.action_controller.per_form_csrf_tokens = false

    # Enable origin-checking CSRF mitigation. Previous versions had false.
    config.action_controller.forgery_protection_origin_check = false

    # Make Ruby 2.4 preserve the timezone of the receiver when calling `to_time`.
    # Previous versions had false.
    ActiveSupport.to_time_preserves_timezone = false

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.jwt_auth_secret = ENV['JWT_AUTH_SECRET']
  end
end
