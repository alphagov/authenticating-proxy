require "proxy"

if ENV["CI"].present?
  ENV["GOVUK_UPSTREAM_URI"] ||= "http://upstream-host.com"
end

Rails.application.config.middleware.use Proxy, ENV.fetch("GOVUK_UPSTREAM_URI")
