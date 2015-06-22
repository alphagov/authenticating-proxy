require 'rack/proxy'

class Proxy < Rack::Proxy
  attr_accessor :upstream_url

  def initialize(app, upstream_url)
    @app = app
    super(backend: upstream_url, streaming: false)
  end

  def call(env)
    path = env['PATH_INFO']

    if proxy?(path)
      authenticate!(env)
      debug_logging(env, "Proxing request: #{path}")
      super
    else
      debug_logging(env, "Request not being proxied: #{path}")
      @app.call(env)
    end
  end

  def proxy?(path)
    !healthcheck_path?(path) && !gds_sso_path?(path)
  end

  def rewrite_env(env)
    add_authenticated_user_header(env)
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

private

  def authenticate!(env)
    if env['warden']
      user = env['warden'].authenticate!
      debug_logging(env, "authenticated as #{user.email}")
    end
  end

  def add_authenticated_user_header(env)
    if env['warden']
      env['HTTP_X_GOVUK_AUTHENTICATED_USER'] = env['warden'].user.id.to_s
    end
  end

  def healthcheck_path?(path)
    path == '/healthcheck'
  end

  def gds_sso_path?(path)
    path.starts_with?("/auth/")
  end

  def debug_logging(env, message)
    env['action_dispatch.logger'] and env['action_dispatch.logger'].debug message
  end
end
