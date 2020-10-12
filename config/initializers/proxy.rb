Rails.application.config.middleware.use Proxy, ENV.fetch("GOVUK_UPSTREAM_URI")
