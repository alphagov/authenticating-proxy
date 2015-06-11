require 'rack/proxy'

class Proxy < Rack::Proxy
  attr_accessor :upstream_url

  def initialize(app, upstream_url)
    @app = app
    @upstream_url = URI.parse(upstream_url)
  end

  def call(env)
    (proxy?(env) && super) || @app.call(env)
  end

  def proxy?(env)
    env['PATH_INFO'] != '/healthcheck'
  end

  def rewrite_env(env)
    env['rack.url_scheme'] = upstream_url.scheme
    env["HTTP_HOST"] = upstream_url.host
    env['SERVER_PORT'] = upstream_url.port
    # rack-proxy doesn't cope well with gzipped/deflated content
    env.delete('HTTP_ACCEPT_ENCODING')
    # Here's where we will set the X-GOVUK-AUTHENTICATED-USER header
    env
  end

   def rewrite_response(response)
    status, headers, body = response

    [
      status,
      # We aren't returning a chunked response so remove that from the headers.
      # Also, status doesn't belong in the headers in a rack response triplet.
      headers.reject { |key, _| %w(status transfer-encoding).include?(key) },
      body
    ]
  end
end
